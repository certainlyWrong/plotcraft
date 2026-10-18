import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'spell_check_backend.dart';
import 'text_overlays.dart';

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
class QuillSpellChecker extends ChangeNotifier implements TextOverlaySource {
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

  @override
  List<TextOverlay> overlays(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return [
      for (final item in _misspellings)
        TextOverlay(
          item.start,
          item.end,
          TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: color,
          ),
        ),
    ];
  }

  /// Quill's `textSpanBuilder` when this is the only decoration.
  InlineSpan spanBuilder(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) => layeredSpan(context, node, nodeOffset, text, style, recognizer, [this]);

  /// Quill's `contextMenuBuilder`: the usual menu, with the suggestions for
  /// the misspelled word under the cursor first.
  Widget buildContextMenu(
    BuildContext context,
    QuillRawEditorState state, {
    List<ContextMenuButtonItem> extraItems = const [],
  }) => _SpellContextMenu(checker: this, editor: state, extraItems: extraItems);

  /// The misspelled word at the cursor or selection, with its text.
  ({Misspelling range, String word})? targetAt(TextSelection selection) {
    if (!selection.isValid) return null;
    final text = _controller?.document.toPlainText() ?? '';
    for (final offset in {selection.start, selection.baseOffset}) {
      final range = misspellingAt(offset);
      if (range != null && range.end <= text.length) {
        return (range: range, word: text.substring(range.start, range.end));
      }
    }
    return null;
  }

  /// Where [word] is now, looking first at [near]: the underlines may have
  /// moved or been refreshed since the menu opened. Null when it is gone.
  Misspelling? locate(String word, int near) {
    final text = _controller?.document.toPlainText();
    if (text == null || word.isEmpty) return null;
    final here = misspellingAt(near);
    if (here != null &&
        here.end <= text.length &&
        text.substring(here.start, here.end) == word) {
      return here;
    }
    Misspelling? best;
    var from = 0;
    while (true) {
      final index = text.indexOf(word, from);
      if (index < 0) break;
      from = index + 1;
      final end = index + word.length;
      final before = index == 0 ? '' : text[index - 1];
      final after = end >= text.length ? '' : text[end];
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(before) ||
          RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(after)) {
        continue;
      }
      if (best == null || (index - near).abs() < (best.start - near).abs()) {
        best = Misspelling(index, end);
      }
    }
    return best;
  }

  /// Replaces [word] (found again near [near]) with [replacement]. False
  /// when the word is no longer in the text.
  bool applySuggestion(String word, int near, String replacement) {
    final target = locate(word, near);
    if (target == null) {
      debugPrint('Spell check: "$word" is no longer in the text');
      return false;
    }
    replaceMisspelling(target, replacement);
    return true;
  }

  /// Label of the "add to dictionary" item; the interface sets a translation.
  String learnLabel = 'Add to dictionary';

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

/// The spelling part of the editor's context menu. It reads the word and asks
/// for suggestions once, when the menu opens, so rebuilding the menu does not
/// restart the request or lose the target.
class _SpellContextMenu extends StatefulWidget {
  const _SpellContextMenu({
    required this.checker,
    required this.editor,
    required this.extraItems,
  });

  final QuillSpellChecker checker;
  final QuillRawEditorState editor;
  final List<ContextMenuButtonItem> extraItems;

  @override
  State<_SpellContextMenu> createState() => _SpellContextMenuState();
}

class _SpellContextMenuState extends State<_SpellContextMenu> {
  ({Misspelling range, String word})? _target;
  Future<List<String>> _suggestions = Future.value(const []);

  @override
  void initState() {
    super.initState();
    final checker = widget.checker;
    _target = checker.targetAt(widget.editor.textEditingValue.selection);
    final target = _target;
    if (target != null) {
      _suggestions = checker.backend
          .suggest(target.word, checker.locale)
          .catchError((_) => const <String>[]);
    }
  }

  /// Closes the menu, runs [action] and gives the editor its focus back.
  void _run(void Function() action) {
    widget.editor.hideToolbar();
    action();
    widget.editor.requestKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    return FutureBuilder<List<String>>(
      future: _suggestions,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const <String>[];
        final items = <ContextMenuButtonItem>[
          if (target != null)
            for (final suggestion in suggestions.take(5))
              ContextMenuButtonItem(
                label: suggestion,
                onPressed: () => _run(
                  () => widget.checker.applySuggestion(
                    target.word,
                    target.range.start,
                    suggestion,
                  ),
                ),
              ),
          if (target != null)
            ContextMenuButtonItem(
              label: widget.checker.learnLabel,
              onPressed: () =>
                  _run(() => unawaited(widget.checker.learn(target.word))),
            ),
          ...widget.extraItems,
          ...widget.editor.contextMenuButtonItems,
        ];
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: items,
          anchors: widget.editor.contextMenuAnchors,
        );
      },
    );
  }
}
