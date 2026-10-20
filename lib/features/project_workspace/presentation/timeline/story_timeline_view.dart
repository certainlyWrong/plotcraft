import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

import '../../domain/story_chronology.dart';
import '../../domain/story_matrix.dart';
import '../shell/workspace_icons.dart';
import 'chapter_matrix_view.dart';
import 'world_timeline_view.dart';

enum TimelineMode { chapters, world }

/// The story over time, in two ways: by the order of the chapters (who
/// appears where) and by the story's own chronology (what happens when).
/// Both can be zoomed (buttons, Cmd/Ctrl + wheel, Cmd/Ctrl +/-) and shown
/// full screen; zoom and mode are saved between sessions.
class StoryTimelineView extends StatefulWidget {
  const StoryTimelineView({
    super.key,
    required this.elements,
    required this.chapters,
    required this.types,
    required this.presence,
    required this.hasChapters,
    required this.onOpenElement,
    required this.onOpenChapter,
    required this.onPlace,
    this.initialState,
    this.onStateChanged,
    this.fullscreen = false,
    this.onToggleFullscreen,
  });

  final List<NarrativeElement> elements;
  final List<BookChapter> chapters;
  final List<ElementType> types;
  final List<ChapterPresence> presence;

  /// False for formats without a manuscript: only the chronology applies.
  final bool hasChapters;
  final ValueChanged<String> onOpenElement;
  final ValueChanged<String> onOpenChapter;

  /// Gives the element a new position on the chronology.
  final void Function(String elementId, double position) onPlace;

  /// What the view looked like last time (mode, zoom, scale).
  final Map<String, Object?>? initialState;
  final ValueChanged<Map<String, Object?>>? onStateChanged;
  final bool fullscreen;
  final VoidCallback? onToggleFullscreen;

  @override
  State<StoryTimelineView> createState() => _StoryTimelineViewState();
}

class _StoryTimelineViewState extends State<StoryTimelineView> {
  static const matrixZoomRange = (0.6, 2.0);
  static const worldZoomRange = (0.5, 8.0);

  TimelineMode _mode = TimelineMode.chapters;
  double _matrixZoom = 1;
  double _worldZoom = 1;
  bool _proportional = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    final state = widget.initialState;
    if (state != null) {
      _mode = TimelineMode.values.firstWhere(
        (m) => m.name == state['mode'],
        orElse: () => TimelineMode.chapters,
      );
      _matrixZoom = _number(state['matrixZoom'], 1, matrixZoomRange);
      _worldZoom = _number(state['worldZoom'], 1, worldZoomRange);
      _proportional = state['proportional'] == true;
    }
  }

  static double _number(Object? value, double fallback, (double, double) r) =>
      value is num && value.isFinite
      ? value.toDouble().clamp(r.$1, r.$2)
      : fallback;

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) _saveNow();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    if (widget.onStateChanged == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  void _saveNow() => widget.onStateChanged?.call({
    'mode': _mode.name,
    'matrixZoom': _matrixZoom,
    'worldZoom': _worldZoom,
    'proportional': _proportional,
  });

  TimelineMode get _activeMode =>
      widget.hasChapters ? _mode : TimelineMode.world;

  /// Multiplies the zoom of the view being shown.
  void _zoomBy(double factor) {
    setState(() {
      if (_activeMode == TimelineMode.chapters) {
        _matrixZoom = (_matrixZoom * factor).clamp(
          matrixZoomRange.$1,
          matrixZoomRange.$2,
        );
      } else {
        _worldZoom = (_worldZoom * factor).clamp(
          worldZoomRange.$1,
          worldZoomRange.$2,
        );
      }
    });
    _scheduleSave();
  }

  void _resetZoom() {
    setState(() {
      if (_activeMode == TimelineMode.chapters) {
        _matrixZoom = 1;
      } else {
        _worldZoom = 1;
      }
    });
    _scheduleSave();
  }

  double get _zoom =>
      _activeMode == TimelineMode.chapters ? _matrixZoom : _worldZoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mode = _activeMode;
    final matrix = StoryMatrix.build(
      elements: widget.elements,
      chapters: widget.chapters,
      presence: widget.presence,
    );
    final chronology = StoryChronology.build(widget.elements);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (widget.fullscreen) widget.onToggleFullscreen?.call();
        },
        for (final meta in const [true, false]) ...{
          SingleActivator(
            LogicalKeyboardKey.equal,
            meta: meta,
            control: !meta,
          ): () =>
              _zoomBy(1.25),
          SingleActivator(
            LogicalKeyboardKey.minus,
            meta: meta,
            control: !meta,
          ): () =>
              _zoomBy(0.8),
          SingleActivator(
            LogicalKeyboardKey.digit0,
            meta: meta,
            control: !meta,
          ): _resetZoom,
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    WorkspaceIcons.timeline,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  // Not flexible: the controls take all the remaining width and
                  // sit against the right edge (two flexible children would
                  // split the free space and leave a gap).
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      'workspace.timeline'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (widget.hasChapters)
                          SegmentedButton<TimelineMode>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: [
                              ButtonSegment(
                                value: TimelineMode.chapters,
                                icon: const Icon(Feather.list, size: 15),
                                label: Text('workspace.timeline_chapters'.tr()),
                              ),
                              ButtonSegment(
                                value: TimelineMode.world,
                                icon: const Icon(Feather.clock, size: 15),
                                label: Text('workspace.timeline_world'.tr()),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (values) {
                              setState(() => _mode = values.first);
                              _scheduleSave();
                            },
                          ),
                        if (mode == TimelineMode.world) ...[
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text('workspace.timeline_order'.tr()),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('workspace.timeline_scale'.tr()),
                              ),
                            ],
                            selected: {_proportional},
                            onSelectionChanged: (values) {
                              setState(() => _proportional = values.first);
                              _scheduleSave();
                            },
                          ),
                        ],
                        _zoomControls(context),
                        if (widget.onToggleFullscreen != null)
                          Tooltip(
                            message: widget.fullscreen
                                ? 'book.exit_fullscreen'.tr()
                                : 'book.fullscreen'.tr(),
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onToggleFullscreen,
                              icon: Icon(
                                widget.fullscreen
                                    ? Feather.minimize_2
                                    : Feather.maximize_2,
                                size: 17,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: mode == TimelineMode.chapters
                  ? ChapterMatrixView(
                      matrix: matrix,
                      elements: widget.elements,
                      types: widget.types,
                      zoom: _matrixZoom,
                      onZoomBy: _zoomBy,
                      onOpenElement: widget.onOpenElement,
                      onOpenChapter: widget.onOpenChapter,
                    )
                  : WorldTimelineView(
                      chronology: chronology,
                      elements: widget.elements,
                      types: widget.types,
                      zoom: _worldZoom,
                      proportional: _proportional,
                      onZoomBy: _zoomBy,
                      onOpenElement: widget.onOpenElement,
                      onPlace: widget.onPlace,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomControls(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'workspace.zoom_out'.tr(),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _zoomBy(0.8),
            icon: const Icon(Feather.zoom_out, size: 17),
          ),
        ),
        Tooltip(
          message: 'workspace.zoom_reset'.tr(),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _resetZoom,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                '${(_zoom * 100).round()}%',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'workspace.zoom_in'.tr(),
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _zoomBy(1.25),
            icon: const Icon(Feather.zoom_in, size: 17),
          ),
        ),
      ],
    );
  }
}
