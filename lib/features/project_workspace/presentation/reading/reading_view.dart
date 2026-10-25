import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/fonts/editor_font_catalog.dart';
import '../../../../core/ui/count_label.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';

import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/gallery_item.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';

import '../manuscript/editor_fonts.dart';
import '../manuscript/embeds.dart';
import '../manuscript/mention_card.dart';
import '../manuscript/mention_hover_controller.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/arch_bridge.dart';

/// Reading mode: the book shown one chapter at a time, as a reader would see
/// it. No toolbar, no cursor, no spell checking; names linked to elements show
/// their card on hover and open the element on click.
class ReadingView extends StatefulWidget {
  const ReadingView({
    super.key,
    required this.chapters,
    required this.deltaFor,
    required this.title,
    required this.fullscreen,
    required this.onToggleFullscreen,
    required this.onOpenElement,
    this.onEdit,
    this.elements = const [],
    this.types = const [],
    this.galleryItems = const [],
    this.attachmentPath,
    this.fonts = const EditorFontCatalog(bundled: bundledEditorFontFamilies),
    this.initialChapterId,
    this.jumpTo,
    this.onJumped,
    this.initialState,
    this.onStateChanged,
  });

  /// Chapters in reading order. Empty for a book written as a single text.
  final List<BookChapter> chapters;

  /// The current text of a chapter (null for the single text).
  final Delta Function(String? chapterId) deltaFor;

  /// Shown for a book without chapters.
  final String title;

  final bool fullscreen;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<String> onOpenElement;

  /// Opens the chapter being read in the editor.
  final ValueChanged<String?>? onEdit;

  final List<NarrativeElement> elements;
  final List<ElementType> types;
  final List<GalleryItem> galleryItems;
  final String? Function(String file)? attachmentPath;
  final EditorFontCatalog fonts;

  /// Chapter to start at when there is no saved position.
  final String? initialChapterId;

  /// A chapter to move to now (asked from outside, for example from the
  /// chapter list); [onJumped] is called once it is shown.
  final String? jumpTo;
  final VoidCallback? onJumped;

  /// Where the reader stopped and the text size, kept between sessions.
  final Map<String, Object?>? initialState;
  final ValueChanged<Map<String, Object?>>? onStateChanged;

  static const minTextSize = 14.0;
  static const maxTextSize = 30.0;
  static const defaultTextSize = 19.0;

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _textFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  final _textScroll = ScrollController();
  late final MentionHoverController _hover;
  QuillController? _quill;
  int _index = 0;
  double _textSize = ReadingView.defaultTextSize;
  double _progress = 0;
  Timer? _saveTimer;

  int get _count => widget.chapters.isEmpty ? 1 : widget.chapters.length;

  String? get _chapterId =>
      widget.chapters.isEmpty ? null : widget.chapters[_index].id;

  @override
  void initState() {
    super.initState();
    _hover = MentionHoverController(
      context: () => context,
      cardFor: (id, {required auto}) => mentionCard(
        id: id,
        auto: auto,
        elements: widget.elements,
        types: widget.types,
        galleryItems: widget.galleryItems,
        chapterOrder: [for (final chapter in widget.chapters) chapter.id],
        chapterId: _chapterId,
        attachmentPath: widget.attachmentPath,
      ),
    );
    _scroll.addListener(_onScroll);
    final saved = widget.initialState;
    final size = saved?['size'];
    if (size is num) {
      _textSize = size.toDouble().clamp(
        ReadingView.minTextSize,
        ReadingView.maxTextSize,
      );
    }
    _index =
        _indexOf(widget.jumpTo) ??
        _indexOf(saved?['chapter'] as String?) ??
        _indexOf(widget.initialChapterId) ??
        0;
    _load();
    if (widget.jumpTo != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onJumped?.call(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _indexOf(widget.jumpTo);
    if (widget.jumpTo != null && widget.jumpTo != oldWidget.jumpTo) {
      if (target != null) _go(target);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onJumped?.call(),
      );
    } else if (oldWidget.chapters != widget.chapters) {
      // Chapters were added, removed or reordered: keep the same chapter.
      final id = oldWidget.chapters.isEmpty
          ? null
          : oldWidget
                .chapters[_index.clamp(0, oldWidget.chapters.length - 1)]
                .id;
      _index = (_indexOf(id) ?? _index).clamp(0, _count - 1);
      _load();
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _hover.dispose();
    _quill?.dispose();
    _focus.dispose();
    _textFocus.dispose();
    _textScroll.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int? _indexOf(String? chapterId) {
    if (chapterId == null) return null;
    final index = widget.chapters.indexWhere((c) => c.id == chapterId);
    return index < 0 ? null : index;
  }

  /// Builds a read-only controller with the current text of the chapter.
  void _load() {
    final old = _quill;
    _quill = QuillController(
      document: Document.fromDelta(widget.deltaFor(_chapterId)),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    // The old controller may still be mounted for one more frame.
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    _progress = 0;
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _go(int index) {
    final target = index.clamp(0, _count - 1);
    if (target == _index && _quill != null) return;
    _hover.hide();
    setState(() {
      _index = target;
      _load();
    });
    _scheduleSave();
  }

  void _setTextSize(double value) {
    setState(() {
      _textSize = value.clamp(ReadingView.minTextSize, ReadingView.maxTextSize);
    });
    _scheduleSave();
  }

  void _onScroll() {
    _hover.hide();
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final next = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0);
    if ((next - _progress).abs() > .002) setState(() => _progress = next);
  }

  void _scheduleSave() {
    final onStateChanged = widget.onStateChanged;
    if (onStateChanged == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      onStateChanged({'chapter': _chapterId, 'size': _textSize});
    });
  }

  int _words(Delta delta) {
    final text = RichDocument.plainText(delta, embed: '').trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  String? _galleryPath(String id) {
    final item = widget.galleryItems.where((i) => i.id == id).firstOrNull;
    return item != null && item.exists ? item.path : null;
  }

  String get _chapterTitle =>
      widget.chapters.isEmpty ? widget.title : widget.chapters[_index].title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Overall progress: finished chapters plus the part of this one scrolled.
    final overall = (_index + _progress) / _count;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _go(_index - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _go(_index + 1),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (widget.fullscreen) widget.onToggleFullscreen();
        },
        for (final meta in const [true, false]) ...{
          SingleActivator(
            LogicalKeyboardKey.equal,
            meta: meta,
            control: !meta,
          ): () =>
              _setTextSize(_textSize + 1),
          SingleActivator(
            LogicalKeyboardKey.minus,
            meta: meta,
            control: !meta,
          ): () =>
              _setTextSize(_textSize - 1),
        },
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Container(
          color: scheme.surfaceContainerLowest.withValues(alpha: .84),
          child: Column(
            children: [
              _header(context),
              LinearProgressIndicator(
                value: overall,
                minHeight: 2,
                color: context.tokens.ink,
                backgroundColor: scheme.outlineVariant.withValues(alpha: .4),
              ),
              Expanded(child: _page(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Feather.book_open, size: 18, color: context.tokens.ink),
          const SizedBox(width: 10),
          Expanded(
            child: widget.chapters.length > 1
                ? _chapterMenu(context)
                : Text(
                    _chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          PlotcraftIconButton(
            icon: Feather.minus,
            tooltip: 'reading.smaller'.tr(),
            onPressed: _textSize > ReadingView.minTextSize
                ? () => _setTextSize(_textSize - 1)
                : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${_textSize.round()}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ),
          PlotcraftIconButton(
            icon: Feather.plus,
            tooltip: 'reading.larger'.tr(),
            onPressed: _textSize < ReadingView.maxTextSize
                ? () => _setTextSize(_textSize + 1)
                : null,
          ),
          if (widget.onEdit != null)
            PlotcraftIconButton(
              icon: Feather.edit_3,
              tooltip: 'reading.edit'.tr(),
              onPressed: () => widget.onEdit!(_chapterId),
            ),
          PlotcraftIconButton(
            icon: widget.fullscreen ? Feather.minimize_2 : Feather.maximize_2,
            tooltip: widget.fullscreen
                ? 'book.exit_fullscreen'.tr()
                : 'book.fullscreen'.tr(),
            onPressed: widget.onToggleFullscreen,
          ),
        ],
      ),
    );
  }

  Widget _chapterMenu(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<int>(
        tooltip: 'reading.chapters'.tr(),
        initialValue: _index,
        onSelected: _go,
        itemBuilder: (_) => [
          for (var i = 0; i < widget.chapters.length; i++)
            PopupMenuItem(value: i, child: Text(widget.chapters[i].title)),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _chapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: PlotcraftFonts.serif,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Feather.chevron_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quill = _quill!;
    final words = _words(quill.document.toDelta());
    final minutes = (words / 220).ceil();
    final body = theme.textTheme.bodyLarge!.copyWith(
      fontSize: _textSize,
      height: 1.75,
    );
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.symmetric(
          horizontal: widget.fullscreen ? 54 : 28,
          vertical: 36,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.chapters.isNotEmpty) ...[
                  Text(
                    'reading.chapter_of'.tr(
                      namedArgs: {'n': '${_index + 1}', 'total': '$_count'},
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  _chapterTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: PlotcraftFonts.serif,
                    fontSize: _textSize * 1.7,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${countLabel('workspace.word_count', words)} · '
                  '${'reading.minutes'.tr(namedArgs: {'count': '$minutes'})}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                _text(context, quill, body),
                const SizedBox(height: 48),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context, QuillController quill, TextStyle base) {
    return QuillEditor(
      key: ObjectKey(quill),
      controller: quill,
      focusNode: _textFocus,
      scrollController: _textScroll,
      config: QuillEditorConfig(
        scrollable: false,
        showCursor: false,
        padding: EdgeInsets.zero,
        embedBuilders: [
          GalleryImageEmbedBuilder(pathOf: _galleryPath),
          const DividerEmbedBuilder(),
          const ExternalImageEmbedBuilder(),
        ],
        textSpanBuilder: (context, node, offset, text, style, recognizer) {
          final span = TextSpan(
            text: text,
            style: style,
            recognizer: recognizer,
          );
          final mention = node is Leaf
              ? node.style.attributes[RichDocument.mentionKey]?.value
              : null;
          if (mention is Map && mention['id'] is String) {
            return withMentionHover(span, mention['id'] as String, _hover);
          }
          return span;
        },
        customStyleBuilder: (attribute) {
          if (attribute.key == Attribute.font.key) {
            return TextStyle(
              fontFamily: widget.fonts.resolve('${attribute.value}'),
            );
          }
          if (attribute.key == RichDocument.mentionKey) {
            return TextStyle(
              color: context.tokens.ink,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle();
        },
        customRecognizerBuilder: (attribute, leaf) {
          if (attribute.key != RichDocument.mentionKey) return null;
          final value = attribute.value;
          if (value is! Map || value['id'] is! String) return null;
          final id = value['id'] as String;
          return TapGestureRecognizer()..onTap = () => widget.onOpenElement(id);
        },
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            base,
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 14),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }

  /// End of the chapter: where the book goes next.
  Widget _footer(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = _index >= _count - 1;
    final hasChapters = widget.chapters.isNotEmpty;
    if (!hasChapters) {
      return Center(
        child: Icon(Feather.feather, size: 18, color: scheme.outline),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Where the chapter ends, a bridge of arches draws itself across.
        const ArchBridge(height: 56),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _NavButton(
                label: _index > 0 ? widget.chapters[_index - 1].title : null,
                caption: 'reading.previous'.tr(),
                icon: Feather.arrow_left,
                alignEnd: false,
                onPressed: _index > 0 ? () => _go(_index - 1) : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isLast
                  ? Center(
                      child: Text(
                        'reading.the_end'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: PlotcraftFonts.serif,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _NavButton(
                      label: widget.chapters[_index + 1].title,
                      caption: 'reading.next'.tr(),
                      icon: Feather.arrow_right,
                      alignEnd: true,
                      onPressed: () => _go(_index + 1),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.caption,
    required this.icon,
    required this.alignEnd,
    required this.onPressed,
  });

  final String? label;
  final String caption;
  final IconData icon;
  final bool alignEnd;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (label == null) return const SizedBox.shrink();
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!alignEnd) Icon(icon, size: 14),
              if (!alignEnd) const SizedBox(width: 6),
              Text(
                caption,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (alignEnd) const SizedBox(width: 6),
              if (alignEnd) Icon(icon, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: PlotcraftFonts.serif,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
