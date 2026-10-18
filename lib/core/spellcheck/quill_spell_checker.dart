import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'spell_check_backend.dart';

/// Spell checking for a [QuillController].
///
/// Quill draws its own text and does not use Flutter's `SpellCheckService`, so
/// this class finds the errors itself and tells Quill how to paint them:
///
/// * the text is checked after the person pauses typing ([debounce]);
/// * ranges are kept per document offset and moved along with every edit, so
///   an underline stays under its word until the next check replaces it;
/// * [spanBuilder] splits Quill's text spans at the ranges and underlines them
///   with a wavy line. Nothing is written to the document, so the underline
///   does not appear in the saved Delta or in the undo history.
class QuillSpellChecker extends ChangeNotifier {
  QuillSpellChecker({
    required this.backend,
    required this.locale,
    this.debounce = const Duration(milliseconds: 350),
  });

  final SpellCheckBackend backend;
  final Duration debounce;
  Locale locale;

  QuillController? _controller;
  StreamSubscription<DocChange>? _changes;
  Timer? _timer;
  int _generation = 0;
  List<Misspelling> _misspellings = const [];
  bool _enabled = true;
  bool _disposed = false;

  List<Misspelling> get misspellings => _misspellings;

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (value) {
      schedule();
    } else {
      _timer?.cancel();
      _generation++;
      _setMisspellings(const []);
    }
  }

  /// Starts watching [controller]; any previous controller is released.
  void attach(QuillController controller) {
    detach();
    _controller = controller;
    _changes = controller.document.changes.listen(_onChange);
    schedule();
  }

  void detach() {
    _changes?.cancel();
    _changes = null;
    _timer?.cancel();
    _controller = null;
  }

  void _onChange(DocChange change) {
    if (_misspellings.isNotEmpty) {
      // Keep existing underlines on their words while the person types.
      final moved = <Misspelling>[];
      for (final item in _misspellings) {
        final start = change.change.transformPosition(item.start);
        final end = change.change.transformPosition(item.end);
        if (end > start) moved.add(Misspelling(start, end));
      }
      _setMisspellings(moved);
    }
    schedule();
  }

  /// Checks the document after [debounce], dropping any earlier request.
  void schedule() {
    _timer?.cancel();
    if (!_enabled || _controller == null) return;
    _timer = Timer(debounce, checkNow);
  }

  Future<void> checkNow() async {
    final controller = _controller;
    if (!_enabled || controller == null || _disposed) return;
    final request = ++_generation;
    final text = controller.document.toPlainText();
    try {
      final found = await backend.check(text, locale);
      // A newer edit or check makes this answer stale.
      if (request != _generation || _disposed) return;
      _setMisspellings(found);
    } catch (_) {
      // A broken checker must never get in the way of writing.
    }
  }

  void _setMisspellings(List<Misspelling> value) {
    if (_listEquals(_misspellings, value)) return;
    _misspellings = value;
    if (!_disposed) notifyListeners();
  }

  bool _listEquals(List<Misspelling> a, List<Misspelling> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// The misspelling covering document [offset], if any.
  Misspelling? misspellingAt(int offset) {
    for (final item in _misspellings) {
      if (offset >= item.start && offset <= item.end) return item;
    }
    return null;
  }

  /// Quill's `textSpanBuilder`: underlines the misspelled parts of [text].
  InlineSpan spanBuilder(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final from = node.documentOffset + nodeOffset;
    final to = from + text.length;
    final mouseCursor = recognizer != null ? SystemMouseCursors.click : null;
    if (_misspellings.isEmpty || text.isEmpty) {
      return TextSpan(
        text: text,
        style: style,
        recognizer: recognizer,
        mouseCursor: mouseCursor,
      );
    }
    final underline = (style ?? const TextStyle()).merge(
      TextStyle(
        decoration: TextDecoration.combine([
          if (style?.decoration != null) style!.decoration!,
          TextDecoration.underline,
        ]),
        decorationStyle: TextDecorationStyle.wavy,
        decorationColor: Theme.of(context).colorScheme.error,
      ),
    );
    final children = <TextSpan>[];
    var cursor = from;
    for (final item in _misspellings) {
      if (item.end <= from) continue;
      if (item.start >= to) break;
      final start = item.start < from ? from : item.start;
      final end = item.end > to ? to : item.end;
      if (start > cursor) {
        children.add(
          TextSpan(
            text: text.substring(cursor - from, start - from),
            style: style,
            recognizer: recognizer,
            mouseCursor: mouseCursor,
          ),
        );
      }
      children.add(
        TextSpan(
          text: text.substring(start - from, end - from),
          style: underline,
          recognizer: recognizer,
          mouseCursor: mouseCursor,
        ),
      );
      cursor = end;
    }
    if (cursor < to) {
      children.add(
        TextSpan(
          text: text.substring(cursor - from),
          style: style,
          recognizer: recognizer,
          mouseCursor: mouseCursor,
        ),
      );
    }
    return TextSpan(children: children, style: style);
  }

  /// Quill's `contextMenuBuilder`: the usual menu, with the suggestions for
  /// the misspelled word under the cursor first.
  Widget buildContextMenu(BuildContext context, QuillRawEditorState state) {
    final selection = state.textEditingValue.selection;
    final target = selection.isValid
        ? misspellingAt(selection.baseOffset)
        : null;
    final text = _controller?.document.toPlainText() ?? '';
    final word = target == null || target.end > text.length
        ? null
        : text.substring(target.start, target.end);
    return FutureBuilder<List<String>>(
      future: word == null
          ? Future.value(const [])
          : backend.suggest(word, locale),
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const <String>[];
        final items = <ContextMenuButtonItem>[
          if (target != null)
            for (final suggestion in suggestions.take(5))
              ContextMenuButtonItem(
                label: suggestion,
                onPressed: () {
                  state.hideToolbar();
                  replaceMisspelling(target, suggestion);
                },
              ),
          if (target != null && word != null)
            ContextMenuButtonItem(
              label: _learnLabel,
              onPressed: () {
                state.hideToolbar();
                unawaited(learn(word));
              },
            ),
          ...state.contextMenuButtonItems,
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: items,
          anchors: state.contextMenuAnchors,
        );
      },
    );
  }

  /// Label of the "add to dictionary" item; the interface sets a translation.
  String _learnLabel = 'Add to dictionary';

  set learnLabel(String value) => _learnLabel = value;

  /// Replaces the misspelled word with [replacement] as one undoable edit.
  void replaceMisspelling(Misspelling target, String replacement) {
    final controller = _controller;
    if (controller == null) return;
    controller.replaceText(
      target.start,
      target.length,
      replacement,
      TextSelection.collapsed(offset: target.start + replacement.length),
    );
  }

  /// Teaches the system dictionary [word] and re-checks the text.
  Future<void> learn(String word) async {
    await backend.learn(word);
    await checkNow();
  }

  @override
  void dispose() {
    _disposed = true;
    detach();
    super.dispose();
  }
}
