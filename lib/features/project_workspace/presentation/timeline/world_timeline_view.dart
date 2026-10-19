import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import '../../../../core/icons/icon_data.dart';
import '../../domain/story_chronology.dart';
import '../element_colors.dart';
import '../elements/element_type_label.dart';
import '../shell/workspace_icons.dart';

/// The story's own chronology, earliest on the left, in two ways.
///
/// **Order**: a line of cards evenly spaced. Dragging a card to another spot
/// gives it a position between its new neighbours.
///
/// **Scale**: an axis where each event sits at its real position, with ticks
/// and rows that keep the cards from covering each other, so a long gap looks
/// long. Zoom spreads out a crowded stretch.
///
/// Cards without a position wait at the end (or below the axis) until placed.
class WorldTimelineView extends StatelessWidget {
  const WorldTimelineView({
    super.key,
    required this.chronology,
    required this.elements,
    required this.types,
    required this.onOpenElement,
    required this.onPlace,
    this.zoom = 1,
    this.proportional = false,
    this.onZoomBy,
  });

  static const cardWidth = 212.0;

  final StoryChronology chronology;
  final List<NarrativeElement> elements;
  final List<ElementType> types;
  final ValueChanged<String> onOpenElement;
  final void Function(String elementId, double position) onPlace;
  final double zoom;

  /// Scale mode instead of order mode.
  final bool proportional;

  /// Asked for when Cmd/Ctrl + wheel is used.
  final ValueChanged<double>? onZoomBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (chronology.entries.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(WorkspaceIcons.timeline, size: 38, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                'workspace.timeline_world_empty'.tr(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            (proportional
                    ? 'workspace.timeline_scale_hint'
                    : 'workspace.timeline_world_hint')
                .tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: proportional
              ? _ScaleTimeline(view: this)
              : _OrderTimeline(view: this),
        ),
      ],
    );
  }

  NarrativeElement? _elementOf(String id) =>
      elements.where((e) => e.id == id).firstOrNull;

  ElementType? _typeOf(String id) => ElementTypeCatalog.resolve(id, types);

  /// Cmd/Ctrl + wheel zooms, claiming the event so nothing scrolls.
  void _zoomWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || onZoomBy == null) return;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      onZoomBy!(math.exp(-(event as PointerScrollEvent).scrollDelta.dy / 400));
    });
  }
}

ScrollBehavior _draggable(BuildContext context) =>
    ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    );

// ---------------------------------------------------------------------------
// Order mode
// ---------------------------------------------------------------------------

class _OrderTimeline extends StatefulWidget {
  const _OrderTimeline({required this.view});

  final WorldTimelineView view;

  @override
  State<_OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<_OrderTimeline> {
  final _controller = ScrollController();

  WorldTimelineView get view => widget.view;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reorder(int from, int to) {
    final sequence = [...view.chronology.entries];
    final moved = sequence.removeAt(from);
    sequence.insert(to, moved);
    view.onPlace(
      moved.elementId,
      StoryChronology.positionAfterMove(sequence, to),
    );
  }

  /// The wheel scrolls sideways, since the line only extends that way.
  void _onWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isMetaPressed) return;
    if (!_controller.hasClients) return;
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    final position = _controller.position;
    _controller.jumpTo(
      (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = view.chronology.entries;
    final width = WorldTimelineView.cardWidth * view.zoom.clamp(0.5, 3.0);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Listener(
        onPointerSignal: (event) {
          view._zoomWheel(event);
          _onWheel(event);
        },
        child: ReorderableListView.builder(
          scrollController: _controller,
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          itemCount: entries.length,
          onReorderItem: _reorder,
          proxyDecorator: (child, index, animation) =>
              Material(type: MaterialType.transparency, child: child),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ReorderableDragStartListener(
              key: ValueKey(entry.elementId),
              index: index,
              child: SizedBox(
                width: width,
                child: _OrderCard(
                  entry: entry,
                  view: view,
                  first: index == 0,
                  last: index == entries.length - 1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.entry,
    required this.view,
    required this.first,
    required this.last,
  });

  final ChronologyEntry entry;
  final WorldTimelineView view;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final element = view._elementOf(entry.elementId);
    final type = view._typeOf(entry.typeId);
    final color = element?.color ?? type?.color ?? scheme.primary;
    final placed = entry.time.isPlaced;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 8),
          child: Text(
            entry.time.display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: placed ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (placed && entry.time.label.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              'workspace.timeline_position'.tr(
                namedArgs: {'value': _position(entry)},
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          const SizedBox(height: 14),
        // The line, with a dot where the card sits on it.
        SizedBox(
          height: 22,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: first ? 12 : 0,
                right: last ? 100 : 0,
                child: Container(
                  height: 2,
                  color: placed
                      ? scheme.outlineVariant
                      : scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                left: 6,
                child: _Dot(color: color, filled: placed),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _EntryBody(entry: entry, view: view),
        ),
      ],
    );
  }

  static String _position(ChronologyEntry entry) {
    final value = entry.time.position;
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(2);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: filled ? color : Theme.of(context).colorScheme.surface,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
  );
}

/// The card with the icon, name and type of an event; opens its element.
class _EntryBody extends StatelessWidget {
  const _EntryBody({required this.entry, required this.view, this.showTime});

  final ChronologyEntry entry;
  final WorldTimelineView view;

  /// Shows the time label inside the card (scale mode has no header).
  final bool? showTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final element = view._elementOf(entry.elementId);
    final type = view._typeOf(entry.typeId);
    final color = element?.color ?? type?.color ?? scheme.primary;
    final icon = (element?.icon ?? type?.icon ?? IconRef.fallback).data;
    final placed = entry.time.isPlaced;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: placed
              ? scheme.outlineVariant
              : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => view.onOpenElement(entry.elementId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTime ?? false) ...[
                Text(
                  entry.time.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                type?.label ?? entry.typeId,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (!placed) ...[
                const SizedBox(height: 8),
                Text(
                  'workspace.timeline_unplaced'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scale mode
// ---------------------------------------------------------------------------

/// Where each placed event goes on an axis, and in which row its card sits.
class ScaleLayout {
  const ScaleLayout({
    required this.xs,
    required this.lanes,
    required this.laneCount,
    required this.width,
    required this.pxPerUnit,
    required this.min,
    required this.max,
  });

  /// Left edge of each card (and its dot), by index into the placed entries.
  final List<double> xs;

  /// Row of each card.
  final List<int> lanes;
  final int laneCount;
  final double width;
  final double pxPerUnit;
  final double min;
  final double max;

  /// Positions the placed [positions] (ascending) over [viewWidth], then
  /// stacks cards that would overlap into rows.
  factory ScaleLayout.of(
    List<double> positions, {
    required double viewWidth,
    required double zoom,
    double cardWidth = 200,
    double padding = 40,
    double gap = 10,
  }) {
    final min = positions.first;
    final max = positions.last;
    final span = max - min;
    final fit = span > 0 ? (viewWidth - 2 * padding - cardWidth) / span : 0.0;
    final pxPerUnit = math.max(fit * zoom, 0.2);
    final xs = [for (final p in positions) padding + (p - min) * pxPerUnit];
    final laneRight = <double>[];
    final lanes = <int>[];
    for (final x in xs) {
      var lane = laneRight.indexWhere((right) => right + gap <= x);
      if (lane < 0) {
        laneRight.add(0);
        lane = laneRight.length - 1;
      }
      laneRight[lane] = x + cardWidth;
      lanes.add(lane);
    }
    return ScaleLayout(
      xs: xs,
      lanes: lanes,
      laneCount: laneRight.length,
      width: math.max(viewWidth, 2 * padding + span * pxPerUnit + cardWidth),
      pxPerUnit: pxPerUnit,
      min: min,
      max: max,
    );
  }

  /// A round step (1, 2, 5 × a power of ten) that puts ticks about
  /// [targetPx] apart.
  static double tickStep(double pxPerUnit, {double targetPx = 90}) {
    final raw = targetPx / pxPerUnit;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    final normal = raw / magnitude;
    final nice = normal <= 1
        ? 1
        : normal <= 2
        ? 2
        : normal <= 5
        ? 5
        : 10;
    return nice * magnitude.toDouble();
  }

  static String formatTick(double value, double step) {
    if (step >= 1) return value.round().toString();
    final decimals = math.max(0, -(math.log(step) / math.ln10).floor());
    return value.toStringAsFixed(decimals);
  }
}

class _ScaleTimeline extends StatelessWidget {
  const _ScaleTimeline({required this.view});

  final WorldTimelineView view;

  static const _cardWidth = 200.0;
  static const _cardHeight = 96.0;
  static const _laneGap = 14.0;
  static const _axisY = 44.0;
  static const _firstLaneTop = _axisY + 40;
  static const _padding = 40.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placed = [
      for (final e in view.chronology.entries)
        if (e.time.isPlaced) e,
    ];
    final unplaced = [
      for (final e in view.chronology.entries)
        if (!e.time.isPlaced) e,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = placed.isEmpty
            ? null
            : ScaleLayout.of(
                [for (final e in placed) e.time.position!],
                viewWidth: constraints.maxWidth,
                zoom: view.zoom,
                cardWidth: _cardWidth,
                padding: _padding,
              );
        final lanesBottom = layout == null
            ? 0.0
            : _firstLaneTop + layout.laneCount * (_cardHeight + _laneGap);
        final width = layout?.width ?? constraints.maxWidth;
        final unplacedTop = lanesBottom + (layout == null ? 8 : 12);
        final children = <Widget>[];
        if (layout != null) {
          // Axis and ticks.
          final step = ScaleLayout.tickStep(layout.pxPerUnit);
          children.add(
            Positioned(
              left: _padding - 20,
              top: _axisY,
              width: layout.width - 2 * (_padding - 20),
              height: 2,
              child: ColoredBox(color: scheme.outlineVariant),
            ),
          );
          var tick = (layout.min / step).ceil() * step;
          while (tick <= layout.max + step * 0.001) {
            final x = _padding + (tick - layout.min) * layout.pxPerUnit;
            children
              ..add(
                Positioned(
                  left: x - 0.5,
                  top: _axisY - 6,
                  width: 1,
                  height: 14,
                  child: ColoredBox(color: scheme.outline),
                ),
              )
              ..add(
                Positioned(
                  left: x - 40,
                  top: _axisY - 28,
                  width: 80,
                  child: Text(
                    ScaleLayout.formatTick(tick, step),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            tick += step;
          }
          // Drawn in layers so a long line to a card in a lower row goes
          // behind the cards it passes, never over them: first all the
          // lines, then all the cards, then the dots that mark where each
          // line starts and ends.
          Color colorOf(ChronologyEntry entry) =>
              view._elementOf(entry.elementId)?.color ??
              view._typeOf(entry.typeId)?.color ??
              scheme.primary;
          double topOf(int i) =>
              _firstLaneTop + layout.lanes[i] * (_cardHeight + _laneGap);
          for (var i = 0; i < placed.length; i++) {
            children.add(
              Positioned(
                left: layout.xs[i] - 1,
                top: _axisY,
                width: 2,
                height: topOf(i) - _axisY,
                child: ColoredBox(
                  color: colorOf(placed[i]).withValues(alpha: 0.55),
                ),
              ),
            );
          }
          for (var i = 0; i < placed.length; i++) {
            children.add(
              Positioned(
                left: layout.xs[i] - 6,
                top: topOf(i),
                width: _cardWidth,
                child: _EntryBody(entry: placed[i], view: view, showTime: true),
              ),
            );
          }
          for (var i = 0; i < placed.length; i++) {
            final color = colorOf(placed[i]);
            children
              ..add(
                Positioned(
                  left: layout.xs[i] - 6,
                  top: _axisY - 5,
                  child: _Dot(color: color, filled: true),
                ),
              )
              ..add(
                Positioned(
                  left: layout.xs[i] - 4,
                  top: topOf(i) - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
          }
        }
        if (unplaced.isNotEmpty) {
          children.add(
            Positioned(
              left: _padding - 6,
              top: unplacedTop,
              width: math.max(300, math.min(width - 2 * _padding, 900)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'workspace.timeline_unplaced_title'.tr(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'workspace.timeline_unplaced_hint'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in unplaced)
                        SizedBox(
                          width: _cardWidth,
                          child: _EntryBody(
                            entry: entry,
                            view: view,
                            showTime: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        final unplacedHeight = unplaced.isEmpty
            ? 0.0
            : 90.0 +
                  (unplaced.length / math.max(1, (width / 230).floor()))
                          .ceil() *
                      130;
        final height = unplacedTop + unplacedHeight + 40;
        return ScrollConfiguration(
          behavior: _draggable(context),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Listener(
                onPointerSignal: view._zoomWheel,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(clipBehavior: Clip.none, children: children),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
