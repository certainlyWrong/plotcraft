import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../domain/book_content.dart';
import '../../domain/markdown_extensions.dart';
import '../../domain/narrative_element.dart';
import '../../../../core/platform/native_spell_check_service.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_popup_menu.dart';
import '../../../../core/ui/plotcraft_segmented.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

enum _EditorView { write, split, preview }

class BookEditor extends StatefulWidget {
  const BookEditor({
    super.key,
    required this.book,
    required this.projectFolder,
    required this.chapterId,
    required this.controller,
    required this.elements,
    required this.dirty,
    required this.saving,
    required this.busy,
    required this.fullscreen,
    required this.onChanged,
    required this.onSave,
    required this.onToggleFullscreen,
    required this.onToggleChapters,
    required this.onSelectChapter,
    required this.onAddChapter,
    required this.onRenameChapter,
    required this.onMoveChapter,
    required this.onRemoveChapter,
    required this.onOpenElement,
  });

  final BookContent book;
  final String projectFolder;
  final String? chapterId;
  final TextEditingController controller;
  final List<NarrativeElement> elements;
  final bool dirty;
  final bool saving;
  final bool busy;
  final bool fullscreen;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onToggleChapters;
  final ValueChanged<String> onSelectChapter;
  final VoidCallback onAddChapter;
  final void Function(BookChapter) onRenameChapter;
  final void Function(BookChapter, int) onMoveChapter;
  final void Function(BookChapter) onRemoveChapter;
  final ValueChanged<String> onOpenElement;

  @override
  State<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<BookEditor> {
  final _focusNode = FocusNode();
  final _undo = UndoHistoryController();
  final _find = TextEditingController();
  final _replace = TextEditingController();
  _EditorView _view = _EditorView.write;
  bool _showFind = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _undo.dispose();
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  void _insert(String before, [String after = '']) {
    final value = widget.controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final selected = selection.textInside(value.text);
    final replacement = '$before$selected$after';
    final text =
        selection.textBefore(value.text) +
        replacement +
        selection.textAfter(value.text);
    final start = selection.start + before.length;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + selected.length,
      ),
    );
    widget.onChanged();
    _focusNode.requestFocus();
  }

  void _replaceSelection(String replacement) {
    final value = widget.controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    widget.controller.value = TextEditingValue(
      text:
          selection.textBefore(value.text) +
          replacement +
          selection.textAfter(value.text),
      selection: TextSelection.collapsed(
        offset: selection.start + replacement.length,
      ),
    );
    widget.onChanged();
    _focusNode.requestFocus();
  }

  void _prefixLine(String prefix) {
    final value = widget.controller.value;
    final start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final lineStart = value.text.lastIndexOf('\n', start - 1) + 1;
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
    widget.onChanged();
    _focusNode.requestFocus();
  }

  void _insertElement(NarrativeElement element) {
    final selection = widget.controller.selection;
    final selected = selection.isValid
        ? selection.textInside(widget.controller.text).trim()
        : '';
    _replaceSelection(
      NarrativeLinkExtension.marker(
        element,
        label: selected.isEmpty ? null : selected,
      ),
    );
  }

  void _findNext() {
    final query = _find.text;
    if (query.isEmpty) return;
    final source = widget.controller.text.toLowerCase();
    final needle = query.toLowerCase();
    final from = widget.controller.selection.isValid
        ? widget.controller.selection.end
        : 0;
    var index = source.indexOf(needle, from);
    if (index < 0) index = source.indexOf(needle);
    if (index < 0) return;
    widget.controller.selection = TextSelection(
      baseOffset: index,
      extentOffset: index + query.length,
    );
    _focusNode.requestFocus();
  }

  void _replaceCurrent() {
    final selection = widget.controller.selection;
    if (selection.isValid &&
        selection.textInside(widget.controller.text).toLowerCase() ==
            _find.text.toLowerCase() &&
        _find.text.isNotEmpty) {
      _replaceSelection(_replace.text);
    }
    _findNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pipeline = PlotcraftMarkdownPipeline([
      NarrativeLinkExtension(widget.elements),
    ]);
    return Container(
      color: scheme.surfaceContainerLowest,
      child: Column(
        children: [
          _toolbar(context),
          if (_showFind) _findBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, _) {
                final showChapters =
                    widget.book.chaptersEnabled && !widget.fullscreen;
                return Row(
                  children: [
                    if (showChapters) _chapterRail(context),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, area) {
                          final editor = _sourceEditor(context);
                          final preview = _preview(context, pipeline);
                          return switch (_view) {
                            _EditorView.write => editor,
                            _EditorView.preview => preview,
                            _EditorView.split =>
                              area.maxWidth >= 900
                                  ? Row(
                                      children: [
                                        Expanded(child: editor),
                                        VerticalDivider(
                                          width: 1,
                                          color: scheme.outlineVariant,
                                        ),
                                        Expanded(child: preview),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Expanded(child: editor),
                                        Divider(
                                          height: 1,
                                          color: scheme.outlineVariant,
                                        ),
                                        Expanded(child: preview),
                                      ],
                                    ),
                          };
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _statusBar(context),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.book.chaptersEnabled
        ? widget.book.chapters
              .where((item) => item.id == widget.chapterId)
              .firstOrNull
              ?.title
        : null;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: 58,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 15),
              Text(
                active ?? 'workspace.manuscript'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              if (widget.book.chaptersEnabled)
                PlotcraftPopupMenuButton<String>(
                  tooltip: 'book.chapters'.tr(),
                  icon: const Icon(Feather.file_text, size: 18),
                  onSelected: (id) => widget.onSelectChapter(id),
                  itemBuilder: (_) => widget.book.chapters
                      .map(
                        (chapter) => PopupMenuItem(
                          value: chapter.id,
                          child: Text(chapter.title),
                        ),
                      )
                      .toList(),
                ),
              if (widget.book.chaptersEnabled)
                _tool(
                  Feather.plus,
                  'book.add_chapter'.tr(),
                  widget.busy ? null : widget.onAddChapter,
                ),
              ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: _undo,
                builder: (_, value, _) => Row(
                  children: [
                    _tool(
                      Feather.corner_up_left,
                      'book.undo'.tr(),
                      value.canUndo ? _undo.undo : null,
                    ),
                    _tool(
                      Feather.corner_up_right,
                      'book.redo'.tr(),
                      value.canRedo ? _undo.redo : null,
                    ),
                  ],
                ),
              ),
              _tool(Feather.bold, 'book.bold'.tr(), () => _insert('**', '**')),
              _tool(
                Feather.italic,
                'book.italic'.tr(),
                () => _insert('*', '*'),
              ),
              _tool(
                Feather.type,
                'book.heading'.tr(),
                () => _prefixLine('## '),
              ),
              _tool(Feather.list, 'book.list'.tr(), () => _prefixLine('- ')),
              _tool(
                Feather.check_square,
                'book.task'.tr(),
                () => _prefixLine('- [ ] '),
              ),
              _tool(
                Feather.message_square,
                'book.quote'.tr(),
                () => _prefixLine('> '),
              ),
              _tool(Feather.code, 'book.code'.tr(), () => _insert('`', '`')),
              _tool(
                Feather.link,
                'book.link'.tr(),
                () => _insert('[', '](https://)'),
              ),
              if (widget.elements.isNotEmpty)
                PlotcraftPopupMenuButton<NarrativeElement>(
                  tooltip: 'book.insert_element'.tr(),
                  icon: const Icon(Feather.at_sign, size: 18),
                  onSelected: _insertElement,
                  itemBuilder: (_) => widget.elements
                      .map(
                        (element) => PopupMenuItem(
                          value: element,
                          child: Text(element.title),
                        ),
                      )
                      .toList(),
                ),
              _tool(
                Feather.search,
                'book.find'.tr(),
                () => setState(() => _showFind = !_showFind),
              ),
              const SizedBox(width: 8),
              PlotcraftSegmented<_EditorView>(
                segments: [
                  PlotcraftSegment(
                    value: _EditorView.write,
                    icon: Feather.edit_3,
                    tooltip: 'book.write'.tr(),
                  ),
                  PlotcraftSegment(
                    value: _EditorView.split,
                    icon: Feather.layout,
                    tooltip: 'book.split'.tr(),
                  ),
                  PlotcraftSegment(
                    value: _EditorView.preview,
                    icon: Feather.eye,
                    tooltip: 'book.preview'.tr(),
                  ),
                ],
                selected: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
              const SizedBox(width: 8),
              _tool(
                Feather.book_open,
                'book.toggle_chapters'.tr(),
                widget.busy ? null : widget.onToggleChapters,
              ),
              _tool(
                widget.fullscreen ? Feather.minimize_2 : Feather.maximize_2,
                widget.fullscreen
                    ? 'book.exit_fullscreen'.tr()
                    : 'book.fullscreen'.tr(),
                widget.onToggleFullscreen,
              ),
              _tool(
                Feather.save,
                'workspace.save'.tr(),
                widget.dirty && !widget.saving ? widget.onSave : null,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback? onPressed) =>
      PlotcraftIconButton(icon: icon, tooltip: tooltip, onPressed: onPressed);

  Widget _findBar(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        _tool(Feather.arrow_down, 'book.find_next'.tr(), _findNext),
        _tool(Feather.repeat, 'book.replace_current'.tr(), _replaceCurrent),
      ],
    ),
  );

  Widget _chapterRail(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 225,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'book.chapters'.tr(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _tool(
                  Feather.plus,
                  'book.add_chapter'.tr(),
                  widget.busy ? null : widget.onAddChapter,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.book.chapters.length,
              itemBuilder: (context, index) {
                final chapter = widget.book.chapters[index];
                final selected = chapter.id == widget.chapterId;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(PlotcraftRadii.control),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            chapter.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => widget.onSelectChapter(chapter.id),
                        ),
                      ),
                      PlotcraftPopupMenuButton<String>(
                        tooltip: 'book.chapter_actions'.tr(),
                        onSelected: (action) {
                          switch (action) {
                            case 'rename':
                              widget.onRenameChapter(chapter);
                            case 'up':
                              widget.onMoveChapter(chapter, -1);
                            case 'down':
                              widget.onMoveChapter(chapter, 1);
                            case 'remove':
                              widget.onRemoveChapter(chapter);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('book.rename'.tr()),
                          ),
                          if (index > 0)
                            PopupMenuItem(
                              value: 'up',
                              child: Text('book.move_up'.tr()),
                            ),
                          if (index < widget.book.chapters.length - 1)
                            PopupMenuItem(
                              value: 'down',
                              child: Text('book.move_down'.tr()),
                            ),
                          if (widget.book.chapters.length > 1)
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('book.remove_chapter'.tr()),
                            ),
                        ],
                        icon: const Icon(Feather.more_vertical, size: 17),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceEditor(BuildContext context) {
    final theme = Theme.of(context);
    final spellConfig = Platform.isMacOS
        ? const SpellCheckConfiguration(
            spellCheckService: NativeSpellCheckService(),
          )
        : Platform.isAndroid || Platform.isIOS
        ? const SpellCheckConfiguration()
        : const SpellCheckConfiguration.disabled();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.fullscreen ? 54 : 28,
        vertical: 26,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
              _insert('**', '**'),
          const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
              _insert('**', '**'),
          const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
              _insert('*', '*'),
          const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
              _insert('*', '*'),
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
              widget.onSave,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              widget.onSave,
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              setState(() => _showFind = true),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              setState(() => _showFind = true),
        },
        child: TextField(
          key: ValueKey(widget.chapterId ?? 'single'),
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

  Widget _preview(BuildContext context, PlotcraftMarkdownPipeline pipeline) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: MarkdownBody(
            data: pipeline.preparePreview(widget.controller.text),
            selectable: true,
            imageDirectory: widget.projectFolder.isEmpty
                ? null
                : Uri.directory(widget.projectFolder).toString(),
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              a: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
              p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              code: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Menlo',
                fontFamilyFallback: const ['Consolas', 'monospace'],
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
              codeblockDecoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              blockquoteDecoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              ),
            ),
            onTapLink: (_, href, _) {
              if (href?.startsWith('plotcraft://element/') ?? false) {
                widget.onOpenElement(
                  href!.substring('plotcraft://element/'.length),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _statusBar(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.controller.text.trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            'workspace.word_count'.tr(namedArgs: {'count': '$count'}),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            widget.saving
                ? 'workspace.saving'.tr()
                : widget.dirty
                ? 'workspace.unsaved'.tr()
                : 'book.saved'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
