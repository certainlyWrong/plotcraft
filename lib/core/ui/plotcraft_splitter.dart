import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

/// Draggable divider between two panels. It only reports the drag; the parent
/// owns the panel size, clamps it and decides when to persist it.
class PlotcraftSplitter extends StatefulWidget {
  const PlotcraftSplitter({
    super.key,
    required this.onDrag,
    this.onDragEnd,
    this.axis = Axis.vertical,
  });

  /// Pixels moved along the axis since the last event (positive = right/down).
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragEnd;

  /// [Axis.vertical] draws a vertical line and resizes horizontally.
  final Axis axis;

  @override
  State<PlotcraftSplitter> createState() => _PlotcraftSplitterState();
}

class _PlotcraftSplitterState extends State<PlotcraftSplitter> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vertical = widget.axis == Axis.vertical;
    final line = ColoredBox(
      color: _active
          ? context.tokens.ink
          : scheme.outlineVariant.withValues(alpha: .5),
    );
    return MouseRegion(
      cursor: vertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: vertical
            ? (details) => widget.onDrag(details.delta.dx)
            : null,
        onHorizontalDragEnd: vertical ? (_) => widget.onDragEnd?.call() : null,
        onVerticalDragUpdate: vertical
            ? null
            : (details) => widget.onDrag(details.delta.dy),
        onVerticalDragEnd: vertical ? null : (_) => widget.onDragEnd?.call(),
        child: SizedBox(
          width: vertical ? 5 : null,
          height: vertical ? null : 5,
          child: Center(
            child: SizedBox(
              width: vertical ? (_active ? 2 : 1) : null,
              height: vertical ? null : (_active ? 2 : 1),
              child: line,
            ),
          ),
        ),
      ),
    );
  }
}
