import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/spellcheck/quill_spell_checker.dart';
import '../../../../core/spellcheck/spell_check_backend.dart';
import '../../domain/rich/quill_find_replace.dart';
import '../../domain/rich/rich_document.dart';
import 'find_bar.dart';
import 'rich_toolbar.dart';

/// One open manuscript document: toolbar, find bar, rich text and status bar.
class BookEditor extends StatefulWidget {
  const BookEditor({
    super.key,
    required this.controller,
    required this.dirty,
    required this.saving,
    required this.fullscreen,
    required this.onSave,
    required this.onToggleFullscreen,
    required this.onOpenElement,
    this.backend = const MethodChannelSpellCheckBackend(),
  });

  final QuillController controller;
  final bool dirty;
  final bool saving;
  final bool fullscreen;
  final VoidCallback onSave;
  final VoidCallback onToggleFullscreen;

  /// Opens the element whose mention was Cmd/Ctrl-clicked.
  final ValueChanged<String> onOpenElement;

  /// The system spell checker (a fake in tests).
  final SpellCheckBackend backend;

  @override
  State<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<BookEditor> {
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _find = TextEditingController();
  final _replace = TextEditingController();
  late final QuillSpellChecker _spell;
  bool _showFind = false;
  bool _spellStarted = false;

  QuillFindReplace get _search => QuillFindReplace(widget.controller);

  @override
  void initState() {
    super.initState();
    _spell = QuillSpellChecker(
      backend: widget.backend,
      locale: const Locale('en'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spell
      ..locale = Localizations.localeOf(context)
      ..learnLabel = 'editor.add_to_dictionary'.tr();
    if (!_spellStarted) {
      _spellStarted = true;
      _spell.attach(widget.controller);
    } else {
      _spell.schedule();
    }
  }

  @override
  void didUpdateWidget(covariant BookEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _spell.attach(widget.controller);
    }
  }

  @override
  void dispose() {
    _spell.dispose();
    _focus.dispose();
    _scroll.dispose();
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  void _openFind() {
    setState(() => _showFind = true);
  }

  void _closeFind() {
    setState(() => _showFind = false);
    _focus.requestFocus();
  }

  void _findNext() {
    if (_search.findNext(_find.text)) _focus.requestFocus();
  }

  void _replaceCurrent() {
    _search.replaceCurrent(_find.text, _replace.text);
    setState(() {});
  }

  void _replaceAll() {
    if (_find.text.isEmpty) return;
    _search.replaceAll(_find.text, _replace.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {
        for (final meta in const [true, false]) ...{
          SingleActivator(LogicalKeyboardKey.keyS, meta: meta, control: !meta):
              widget.onSave,
          SingleActivator(LogicalKeyboardKey.keyF, meta: meta, control: !meta):
              _openFind,
        },
      },
      child: Container(
        color: scheme.surfaceContainerLowest,
        child: Column(
          children: [
            RichToolbar(
              controller: widget.controller,
              fullscreen: widget.fullscreen,
              canSave: widget.dirty && !widget.saving,
              findOpen: _showFind,
              onFind: _showFind ? _closeFind : _openFind,
              onToggleFullscreen: widget.onToggleFullscreen,
              onSave: widget.onSave,
            ),
            if (_showFind)
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) => FindBar(
                  find: _find,
                  replace: _replace,
                  matchCount: _search.matches(_find.text).length,
                  onQueryChanged: (_) => setState(() {}),
                  onFindNext: _findNext,
                  onReplace: _replaceCurrent,
                  onReplaceAll: _replaceAll,
                  onClose: _closeFind,
                ),
              ),
            Expanded(child: _editor(context)),
            _statusBar(context),
          ],
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.bodyLarge!.copyWith(height: 1.7);
    return ListenableBuilder(
      listenable: _spell,
      builder: (context, _) => QuillEditor(
        controller: widget.controller,
        focusNode: _focus,
        scrollController: _scroll,
        config: QuillEditorConfig(
          placeholder: 'editor.placeholder'.tr(),
          padding: EdgeInsets.symmetric(
            horizontal: widget.fullscreen ? 54 : 28,
            vertical: 24,
          ),
          maxContentWidth: 820,
          textSpanBuilder: _spell.spanBuilder,
          contextMenuBuilder: _spell.buildContextMenu,
          customStyleBuilder: (attribute) =>
              attribute.key == RichDocument.mentionKey
              ? TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  backgroundColor: scheme.primary.withValues(alpha: .08),
                )
              : const TextStyle(),
          customRecognizerBuilder: (attribute, leaf) {
            if (attribute.key != RichDocument.mentionKey) return null;
            final value = attribute.value;
            if (value is! Map || value['id'] is! String) return null;
            final id = value['id'] as String;
            // Like links in an editor, a mention opens only with Cmd/Ctrl held,
            // so a plain click still places the cursor.
            return TapGestureRecognizer()
              ..onTap = () {
                final keyboard = HardwareKeyboard.instance;
                if (keyboard.isMetaPressed || keyboard.isControlPressed) {
                  widget.onOpenElement(id);
                }
              };
          },
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              base,
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 10),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBar(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (_, _) {
              final text = RichDocument.plainText(
                widget.controller.document.toDelta(),
                embed: '',
              ).trim();
              final count = text.isEmpty
                  ? 0
                  : text.split(RegExp(r'\s+')).length;
              return Text(
                'workspace.word_count'.tr(namedArgs: {'count': '$count'}),
                style: style,
              );
            },
          ),
          const Spacer(),
          Text(
            widget.saving
                ? 'workspace.saving'.tr()
                : widget.dirty
                ? 'workspace.unsaved'.tr()
                : 'book.saved'.tr(),
            style: style,
          ),
        ],
      ),
    );
  }
}
