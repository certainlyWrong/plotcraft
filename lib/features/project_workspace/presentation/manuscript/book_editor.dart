import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/count_label.dart';

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/fonts/editor_font_catalog.dart';
import '../../../../core/spellcheck/quill_spell_checker.dart';
import '../../../../core/spellcheck/spell_check_backend.dart';
import '../../../../core/spellcheck/text_overlays.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../domain/active_phase.dart';
import '../../domain/element_image.dart';
import '../../domain/element_type.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/gallery_item.dart';
import '../../domain/narrative_element.dart';
import '../../domain/rich/mention_edit.dart';
import '../../domain/rich/quill_find_replace.dart';
import '../../domain/rich/rich_document.dart';
import '../elements/gallery_picker_dialog.dart';
import 'element_mention_picker.dart';
import 'auto_mention_tracker.dart';
import 'embeds.dart';
import 'editor_fonts.dart';
import 'find_bar.dart';
import 'rich_toolbar.dart';
import 'element_hover_card.dart';
import 'mention_hover_controller.dart';

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
    this.elements = const [],
    this.types = const [],
    this.galleryItems = const [],
    this.chapterOrder = const [],
    this.chapterId,
    this.attachmentPath,
    this.fonts = const EditorFontCatalog(bundled: bundledEditorFontFamilies),
    this.onManageFonts,
    this.onIgnoreTerm,
    this.reveal,
    this.onRevealed,
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

  /// Elements that can be linked from the text, and their types.
  final List<NarrativeElement> elements;
  final List<ElementType> types;

  /// Gallery images that can be shown in the text.
  final List<GalleryItem> galleryItems;

  /// Chapter IDs in reading order and the one being edited, to find the phase
  /// of an element in force here (shown when hovering a mention).
  final List<String> chapterOrder;
  final String? chapterId;

  /// File of an image attached to an element, from its project-relative path.
  final String? Function(String file)? attachmentPath;

  /// Fonts the editor can offer and draw, and the way to manage the project's.
  final EditorFontCatalog fonts;
  final VoidCallback? onManageFonts;

  /// Asked to stop detecting [term] as a mention of [element].
  final void Function(NarrativeElement element, String term)? onIgnoreTerm;

  /// A stretch of text to select and bring into view when shown.
  final TextRange? reveal;
  final VoidCallback? onRevealed;

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
  late final AutoMentionTracker _auto;
  bool _showFind = false;
  bool _spellStarted = false;
  late final MentionHoverController _hover;
  StreamSubscription<DocChange>? _changes;

  QuillFindReplace get _search => QuillFindReplace(widget.controller);

  @override
  void initState() {
    super.initState();
    _spell = QuillSpellChecker(
      backend: widget.backend,
      locale: const Locale('en'),
    );
    _auto = AutoMentionTracker(elements: widget.elements);
    _hover = MentionHoverController(
      context: () => context,
      cardFor: _hoverCard,
    );
    _scroll.addListener(_hover.hide);
    _auto.onHoverEnter = (hit, position) {
      _hover.enter(hit.elementId, position, auto: true);
    };
    _auto.onHoverExit = _hover.leave;
    _scheduleReveal();
    _changes = widget.controller.document.changes.listen(_onDocumentChange);
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
      _auto.attach(widget.controller);
    } else {
      _spell.schedule();
    }
  }

  @override
  void didUpdateWidget(covariant BookEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elements != widget.elements) _auto.elements = widget.elements;
    if (widget.reveal != null && widget.reveal != oldWidget.reveal) {
      _scheduleReveal();
    }
    if (oldWidget.controller != widget.controller) {
      _spell.attach(widget.controller);
      _auto.attach(widget.controller);
      unawaited(_changes?.cancel());
      _changes = widget.controller.document.changes.listen(_onDocumentChange);
    }
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _hover.dispose();
    _spell.dispose();
    _auto.dispose();
    _focus.dispose();
    _scroll.dispose();
    _find.dispose();
    _replace.dispose();
    super.dispose();
  }

  /// The usual menu with spelling suggestions and, over a name that could be
  /// a mention, the choice to link it or to stop detecting it.
  Widget _contextMenu(BuildContext context, QuillRawEditorState state) {
    final selection = state.textEditingValue.selection;
    final hit = selection.isValid ? _auto.hitAt(selection.baseOffset) : null;
    final element = hit == null
        ? null
        : widget.elements.where((e) => e.id == hit.elementId).firstOrNull;
    final linkItems = <ContextMenuButtonItem>[
      if (hit != null && element != null) ...[
        ContextMenuButtonItem(
          label: 'editor.link_to'.tr(namedArgs: {'name': element.title}),
          onPressed: () {
            state.hideToolbar();
            widget.controller.formatText(
              hit.start,
              hit.length,
              MentionEdit.attribute(element),
            );
          },
        ),
        if (widget.onIgnoreTerm != null)
          ContextMenuButtonItem(
            label: 'editor.ignore_term'.tr(namedArgs: {'term': hit.term}),
            onPressed: () {
              state.hideToolbar();
              widget.onIgnoreTerm!(element, hit.term);
            },
          ),
      ],
    ];
    return _spell.buildContextMenu(context, state, extraItems: linkItems);
  }

  /// Selects the requested stretch once the editor is laid out. Quill scrolls
  /// to the selection when the editor has focus.
  void _scheduleReveal() {
    if (widget.reveal == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final range = widget.reveal;
      if (!mounted || range == null) return;
      final length = widget.controller.document.length - 1;
      final start = range.start.clamp(0, length);
      final end = range.end.clamp(start, length);
      widget.controller.updateSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        ChangeSource.local,
      );
      _focus.requestFocus();
      widget.onRevealed?.call();
    });
  }

  /// Typing `@` at the start of a word opens the element picker.
  void _onDocumentChange(DocChange change) {
    _hover.hide();
    if (change.source != ChangeSource.local) return;
    final ops = change.change.toList();
    var index = 0;
    Object? inserted;
    if (ops.length == 1 && ops.first.isInsert) {
      inserted = ops.first.data;
    } else if (ops.length == 2 && ops.first.isRetain && ops.last.isInsert) {
      index = ops.first.length ?? 0;
      inserted = ops.last.data;
    }
    if (inserted != '@') return;
    final text = widget.controller.document.toPlainText();
    final before = index == 0 || index > text.length ? '\n' : text[index - 1];
    // "name@site" is an address, not a mention.
    if (!RegExp(r'[\s(\[{"“]').hasMatch(before)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_mentionAt(index));
    });
  }

  Future<NarrativeElement?> _pickElement() => showElementMentionPicker(
    context,
    elements: widget.elements,
    types: widget.types,
  );

  /// Replaces the `@` typed at [index] with the chosen element.
  Future<void> _mentionAt(int index) async {
    if (widget.elements.isEmpty) return;
    final element = await _pickElement();
    if (element == null || !mounted) {
      _focus.requestFocus();
      return;
    }
    final text = widget.controller.document.toPlainText();
    if (index < text.length && text[index] == '@') {
      MentionEdit.insert(widget.controller, index, 1, element);
    }
    _focus.requestFocus();
  }

  /// Toolbar button: link the selected text, or insert the element's name.
  Future<void> _linkElement() async {
    final element = await _pickElement();
    if (element == null || !mounted) return;
    final controller = widget.controller;
    if (!MentionEdit.linkSelection(controller, element)) {
      final at = controller.selection.isValid ? controller.selection.start : 0;
      MentionEdit.insert(controller, at, 0, element);
    }
    _focus.requestFocus();
  }

  Future<void> _insertImage() async {
    final ids = await showGalleryPicker(
      context,
      items: widget.galleryItems,
      selected: const [],
    );
    if (ids == null || !mounted) return;
    for (final id in ids) {
      MentionEdit.insertGalleryImage(widget.controller, id);
    }
    _focus.requestFocus();
  }

  /// The card for the element a mention points to, or null if it is gone.
  Widget? _hoverCard(String id, {required bool auto}) {
    final element = widget.elements.where((e) => e.id == id).firstOrNull;
    if (element == null) return null;
    ElementImage? cover = element.images.firstOrNull;
    String? coverPath;
    if (cover != null) {
      coverPath = cover.isGallery
          ? _galleryPath(cover.value)
          : widget.attachmentPath?.call(cover.value);
    }
    return ElementHoverCard(
      element: element,
      type: ElementTypeCatalog.resolve(element.typeId, widget.types),
      coverPath: coverPath,
      phase: activePhaseAt(element, widget.chapterOrder, widget.chapterId),
      auto: auto,
    );
  }

  /// Makes every piece of a mention's text report the pointer entering and
  /// leaving, so its card can be shown.
  InlineSpan _withHover(InlineSpan span, String id) {
    if (span is! TextSpan) return span;
    return TextSpan(
      text: span.text,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: (event) => _hover.enter(id, event.position),
      onExit: (_) => _hover.leave(),
      children: [
        for (final child in span.children ?? const <InlineSpan>[])
          _withHover(child, id),
      ],
    );
  }

  String? _galleryPath(String id) {
    final item = widget.galleryItems.where((item) => item.id == id).firstOrNull;
    return item != null && item.exists ? item.path : null;
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
              fonts: widget.fonts.menuItems,
              extraActions: [
                if (widget.onManageFonts != null)
                  PlotcraftIconButton(
                    icon: Feather.type,
                    tooltip: 'editor.fonts'.tr(),
                    onPressed: widget.onManageFonts,
                  ),
                PlotcraftIconButton(
                  icon: Feather.at_sign,
                  tooltip: 'editor.insert_mention'.tr(),
                  onPressed: _linkElement,
                ),
                PlotcraftIconButton(
                  icon: Feather.image,
                  tooltip: 'editor.insert_image'.tr(),
                  onPressed: _insertImage,
                ),
                PlotcraftIconButton(
                  icon: Feather.minus,
                  tooltip: 'editor.insert_divider'.tr(),
                  onPressed: () {
                    MentionEdit.insertDivider(widget.controller);
                    _focus.requestFocus();
                  },
                ),
              ],
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
            _missingFontsBanner(context),
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
      listenable: Listenable.merge([_spell, _auto]),
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
          embedBuilders: [
            GalleryImageEmbedBuilder(pathOf: _galleryPath),
            const DividerEmbedBuilder(),
            const ExternalImageEmbedBuilder(),
          ],
          textSpanBuilder: (context, node, offset, text, style, recognizer) {
            final span = layeredSpan(
              context,
              node,
              offset,
              text,
              style,
              recognizer,
              [_auto, _spell],
            );
            final mention = node is Leaf
                ? node.style.attributes[RichDocument.mentionKey]?.value
                : null;
            if (mention is Map && mention['id'] is String) {
              return _withHover(span, mention['id'] as String);
            }
            return span;
          },
          contextMenuBuilder: _contextMenu,
          customStyleBuilder: (attribute) {
            if (attribute.key == Attribute.font.key) {
              // Project fonts are registered under project-specific names.
              return TextStyle(
                fontFamily: widget.fonts.resolve('${attribute.value}'),
              );
            }
            if (attribute.key == RichDocument.mentionKey) {
              return TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                backgroundColor: scheme.primary.withValues(alpha: .08),
              );
            }
            return const TextStyle();
          },
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

  /// Fonts used by the text that this computer cannot draw.
  List<String> _missingFonts() {
    final used = <String>{};
    for (final op in widget.controller.document.toDelta().toList()) {
      final font = op.attributes?[Attribute.font.key];
      if (font is String) used.add(font);
    }
    return widget.fonts.missing(used);
  }

  Widget _missingFontsBanner(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final missing = _missingFonts();
      if (missing.isEmpty) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      return Container(
        color: scheme.tertiaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Icon(
              Feather.alert_triangle,
              size: 16,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'editor.missing_fonts'.tr(
                  namedArgs: {'fonts': missing.join(', ')},
                ),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: scheme.onTertiaryContainer),
              ),
            ),
            if (widget.onManageFonts != null)
              TextButton(
                onPressed: widget.onManageFonts,
                child: Text('editor.missing_fonts_action'.tr()),
              ),
          ],
        ),
      );
    },
  );

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
                countLabel('workspace.word_count', count),
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
