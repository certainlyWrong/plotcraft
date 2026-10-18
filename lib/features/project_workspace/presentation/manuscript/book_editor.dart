import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/platform/native_spell_check_service.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_splitter.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/markdown_edit_controller.dart';
import '../../domain/narrative_element.dart';
import 'editor_toolbar.dart';
import 'markdown_preview.dart';

import 'package:icons_flutter/icons_flutter.dart';

/// One open manuscript document: toolbar, find bar, source, preview and status.
class BookEditor extends StatefulWidget {
  const BookEditor({
    super.key,
    required this.projectFolder,
    required this.controller,
    required this.elements,
    required this.dirty,
    required this.saving,
    required this.fullscreen,
    required this.onChanged,
    required this.onSave,
    required this.onToggleFullscreen,
    required this.onOpenElement,
  });

  final String projectFolder;
  final TextEditingController controller;
  final List<NarrativeElement> elements;
  final bool dirty;
  final bool saving;
  final bool fullscreen;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<String> onOpenElement;

  @override
  State<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<BookEditor> {
  final _focusNode = FocusNode();
  final _undo = UndoHistoryController();
  final _find = TextEditingController();
  final _replace = TextEditingController();
  EditorView _view = EditorView.write;
  bool _showFind = false;
  double _splitRatio = .5;

  MarkdownEditController get _edit => MarkdownEditController(widget.controller);

  @override
  void dispose() {
    _focusNode.dispose();
    _undo.dispose();
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  /// Runs a text edit and reports it like a keystroke would.
  void _apply(VoidCallback edit) {
    edit();
    widget.onChanged();
    _focusNode.requestFocus();
  }

  void _findNext() {
    if (_edit.findNext(_find.text)) _focusNode.requestFocus();
  }

  void _replaceCurrent() {
    if (_edit.replaceCurrent(_find.text, _replace.text)) widget.onChanged();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerLowest,
      child: Column(
        children: [
          EditorToolbar(
            undo: _undo,
            elements: widget.elements,
            view: _view,
            fullscreen: widget.fullscreen,
            canSave: widget.dirty && !widget.saving,
            onWrap: (before, [after = '']) =>
                _apply(() => _edit.wrapSelection(before, after)),
            onPrefix: (prefix) => _apply(() => _edit.prefixLine(prefix)),
            onInsertElement: (element) =>
                _apply(() => _edit.insertElement(element)),
            onFind: () => setState(() => _showFind = !_showFind),
            onViewChanged: (view) => setState(() => _view = view),
            onToggleFullscreen: widget.onToggleFullscreen,
            onSave: widget.onSave,
          ),
          if (_showFind) _findBar(context),
          Expanded(child: _content(context)),
          _statusBar(context),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final preview = ListenableBuilder(
      listenable: widget.controller,
      builder: (_, _) => MarkdownPreview(
        source: widget.controller.text,
        elements: widget.elements,
        projectFolder: widget.projectFolder,
        onOpenElement: widget.onOpenElement,
      ),
    );
    return switch (_view) {
      EditorView.write => _sourceEditor(context),
      EditorView.preview => preview,
      EditorView.split => LayoutBuilder(
        builder: (context, area) {
          final editorWidth = (area.maxWidth * _splitRatio).clamp(
            240.0,
            area.maxWidth - 240,
          );
          return Row(
            children: [
              SizedBox(width: editorWidth, child: _sourceEditor(context)),
              PlotcraftSplitter(
                onDrag: (delta) => setState(
                  () => _splitRatio = ((editorWidth + delta) / area.maxWidth)
                      .clamp(.2, .8),
                ),
              ),
              Expanded(child: preview),
            ],
          );
        },
      ),
    };
  }

  Widget _findBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Row(
      children: [
        Expanded(
          child: PlotcraftTextField(
            controller: _find,
            compact: true,
            hint: 'book.find'.tr(),
            onSubmitted: (_) => _findNext(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PlotcraftTextField(
            controller: _replace,
            compact: true,
            hint: 'book.replace'.tr(),
            onSubmitted: (_) => _replaceCurrent(),
          ),
        ),
        PlotcraftIconButton(
          icon: Feather.arrow_down,
          tooltip: 'book.find_next'.tr(),
          onPressed: _findNext,
        ),
        PlotcraftIconButton(
          icon: Feather.repeat,
          tooltip: 'book.replace_current'.tr(),
          onPressed: _replaceCurrent,
        ),
      ],
    ),
  );

  Widget _sourceEditor(BuildContext context) {
    final theme = Theme.of(context);
    final spellConfig = Platform.isMacOS
        ? const SpellCheckConfiguration(
            spellCheckService: NativeSpellCheckService(),
          )
        : Platform.isAndroid || Platform.isIOS
        ? const SpellCheckConfiguration()
        : const SpellCheckConfiguration.disabled();
    CallbackShortcuts shortcuts(Widget child) => CallbackShortcuts(
      bindings: {
        for (final meta in const [true, false]) ...{
          SingleActivator(
            LogicalKeyboardKey.keyB,
            meta: meta,
            control: !meta,
          ): () =>
              _apply(() => _edit.wrapSelection('**', '**')),
          SingleActivator(
            LogicalKeyboardKey.keyI,
            meta: meta,
            control: !meta,
          ): () =>
              _apply(() => _edit.wrapSelection('*', '*')),
          SingleActivator(LogicalKeyboardKey.keyS, meta: meta, control: !meta):
              widget.onSave,
          SingleActivator(
            LogicalKeyboardKey.keyF,
            meta: meta,
            control: !meta,
          ): () =>
              setState(() => _showFind = true),
        },
      },
      child: child,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.fullscreen ? 54 : 24,
        vertical: 20,
      ),
      child: shortcuts(
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          undoController: _undo,
          spellCheckConfiguration: spellConfig,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          onChanged: (_) => widget.onChanged(),
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
          decoration: InputDecoration(
            hintText: 'workspace.manuscript_placeholder'.tr(),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
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
              final text = widget.controller.text.trim();
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
