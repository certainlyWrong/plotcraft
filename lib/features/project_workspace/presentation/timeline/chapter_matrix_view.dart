import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import '../../../../core/icons/icon_data.dart';
import '../../domain/story_matrix.dart';
import '../element_colors.dart';
import '../elements/element_type_label.dart';
import '../shell/workspace_icons.dart';

/// Chapters across, elements down. A dot is an element written in a chapter
/// (bigger when it appears more); a diamond is where one of its phases begins.
/// The element names and the chapter titles stay in view while scrolling.
class ChapterMatrixView extends StatefulWidget {
  const ChapterMatrixView({
    super.key,
    required this.matrix,
    required this.elements,
    required this.types,
    this.zoom = 1,
    this.onZoomBy,
    required this.onOpenElement,
    required this.onOpenChapter,
  });

  final StoryMatrix matrix;
  final List<NarrativeElement> elements;
  final List<ElementType> types;

  /// Scales the cells (1 = normal).
  final double zoom;

  /// Asked for when Cmd/Ctrl + wheel is used over the grid.
  final ValueChanged<double>? onZoomBy;
  final ValueChanged<String> onOpenElement;
  final ValueChanged<String> onOpenChapter;

  @override
  State<ChapterMatrixView> createState() => _ChapterMatrixViewState();
}

class _ChapterMatrixViewState extends State<ChapterMatrixView> {
  static const _labelWidth = 200.0;
  static const _baseCellWidth = 76.0;
  static const _baseCellHeight = 40.0;
  static const _headerHeight = 58.0;

  double get _cellWidth => _baseCellWidth * widget.zoom;
  double get _cellHeight => _baseCellHeight * widget.zoom;

  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  final _hiddenTypes = <String>{};
  String _query = '';

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  ElementType? _typeOf(String id) =>
      ElementTypeCatalog.resolve(id, widget.types);

  NarrativeElement? _elementOf(String id) =>
      widget.elements.where((e) => e.id == id).firstOrNull;

  /// Cmd/Ctrl + wheel over the grid zooms instead of scrolling.
  void _onSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || widget.onZoomBy == null) return;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      widget.onZoomBy!(
        math.exp(-(event as PointerScrollEvent).scrollDelta.dy / 400),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final matrix = widget.matrix;
    if (matrix.rows.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(WorkspaceIcons.timeline, size: 38, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                'workspace.timeline_chapters_empty'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final query = _query.toLowerCase();
    final rows = [
      for (final row in matrix.rows)
        if (!_hiddenTypes.contains(row.typeId) &&
            (query.isEmpty || row.title.toLowerCase().contains(query)))
          row,
    ];
    final typeIds = {for (final row in matrix.rows) row.typeId};
    final width = _labelWidth + matrix.chapters.length * _cellWidth;
    final height = _headerHeight + rows.length * _cellHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filters(context, typeIds),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _vertical,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: Listener(
                  onPointerSignal: _onSignal,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_horizontal, _vertical]),
                      builder: (context, _) {
                        final dx = _horizontal.hasClients
                            ? _horizontal.offset
                            : 0.0;
                        final dy = _vertical.hasClients
                            ? _vertical.offset
                            : 0.0;
                        return Stack(
                          children: [
                            // Cells.
                            for (var r = 0; r < rows.length; r++)
                              for (var c = 0; c < matrix.chapters.length; c++)
                                Positioned(
                                  left: _labelWidth + c * _cellWidth,
                                  top: _headerHeight + r * _cellHeight,
                                  width: _cellWidth,
                                  height: _cellHeight,
                                  child: _cell(context, rows[r], c),
                                ),
                            // Chapter titles, pinned to the top.
                            Positioned(
                              left: 0,
                              top: dy,
                              width: width,
                              height: _headerHeight,
                              child: _header(context, dx),
                            ),
                            // Element names, pinned to the left.
                            Positioned(
                              left: dx,
                              top: _headerHeight,
                              width: _labelWidth,
                              height: rows.length * _cellHeight,
                              child: _labels(context, rows),
                            ),
                            Positioned(
                              left: dx,
                              top: dy,
                              width: _labelWidth,
                              height: _headerHeight,
                              child: Container(
                                color: scheme.surface,
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                                child: Text(
                                  '${rows.length} ${'elements.title'.tr()}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context, Set<String> typeIds) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'workspace.timeline_search'.tr(),
                prefixIcon: const Icon(Feather.search, size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
              ),
            ),
          ),
          for (final id in typeIds)
            FilterChip(
              avatar: Icon(
                (_typeOf(id)?.icon ?? IconRef.fallback).data,
                size: 15,
                color: _hiddenTypes.contains(id)
                    ? scheme.outline
                    : (_typeOf(id)?.color ?? scheme.primary),
              ),
              label: Text(_typeOf(id)?.label ?? id),
              selected: !_hiddenTypes.contains(id),
              showCheckmark: false,
              onSelected: (value) => setState(() {
                if (value) {
                  _hiddenTypes.remove(id);
                } else {
                  _hiddenTypes.add(id);
                }
              }),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, double dx) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _labelWidth),
          for (var c = 0; c < widget.matrix.chapters.length; c++)
            SizedBox(
              width: _cellWidth,
              child: Tooltip(
                message: widget.matrix.chapters[c].title,
                child: InkWell(
                  onTap: () =>
                      widget.onOpenChapter(widget.matrix.chapters[c].id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.matrix.chapters[c].title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _labels(BuildContext context, List<MatrixRow> rows) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.surface,
      child: Column(
        children: [
          for (final row in rows)
            SizedBox(
              height: _cellHeight,
              child: InkWell(
                onTap: () => widget.onOpenElement(row.elementId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        (_elementOf(row.elementId)?.icon ??
                                _typeOf(row.typeId)?.icon ??
                                IconRef.fallback)
                            .data,
                        size: 15,
                        color: _colorOf(row, scheme),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorOf(MatrixRow row, ColorScheme scheme) =>
      _elementOf(row.elementId)?.color ??
      _typeOf(row.typeId)?.color ??
      scheme.primary;

  Widget _cell(BuildContext context, MatrixRow row, int chapterIndex) {
    final scheme = Theme.of(context).colorScheme;
    final cell = row.cells[chapterIndex];
    final chapter = widget.matrix.chapters[chapterIndex];
    final border = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
    );
    if (cell.isEmpty) return DecoratedBox(decoration: border);
    final color = _colorOf(row, scheme);
    final size = 8.0 + (cell.mentions.clamp(0, 8)) * 1.6;
    final lines = [
      '${row.title} · ${chapter.title}',
      if (cell.mentions > 0)
        'workspace.timeline_mentions'.tr(
          namedArgs: {'count': '${cell.mentions}'},
        ),
      for (final phase in cell.phases)
        '${'workspace.timeline_phase'.tr()}: $phase',
    ];
    return Tooltip(
      message: lines.join('\n'),
      child: InkWell(
        onTap: () => widget.onOpenChapter(chapter.id),
        child: DecoratedBox(
          decoration: border,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (cell.mentions > 0)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                if (cell.phases.isNotEmpty)
                  Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: size + 8,
                      height: size + 8,
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.onSurface, width: 1.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
