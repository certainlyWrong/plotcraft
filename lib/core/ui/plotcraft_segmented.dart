import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

class PlotcraftSegment<T> {
  const PlotcraftSegment({
    required this.value,
    required this.icon,
    required this.tooltip,
  });

  final T value;
  final IconData icon;
  final String tooltip;
}

/// Single-choice icon switcher (for example write / split / preview). The
/// choice is marked by a patch of pigment that slides to it, with a line of ink
/// beneath, instead of a filled and outlined segment.
class PlotcraftSegmented<T> extends StatelessWidget {
  const PlotcraftSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  static const _cell = Size(34, 30);

  final List<PlotcraftSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final index = segments.indexWhere((s) => s.value == selected);
    return SizedBox(
      width: _cell.width * segments.length,
      height: _cell.height,
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedPositioned(
              duration: PlotcraftMotion.medium,
              curve: PlotcraftMotion.curve,
              left: _cell.width * index,
              top: 0,
              width: _cell.width,
              height: _cell.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.pigment.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(PlotcraftRadii.control),
                  border: Border(
                    bottom: BorderSide(color: tokens.ink, width: 1.6),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                _Cell(
                  size: _cell,
                  segment: segment,
                  selected: segment.value == selected,
                  idle: scheme.onSurfaceVariant,
                  ink: tokens.ink,
                  onTap: () => onChanged(segment.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell<T> extends StatefulWidget {
  const _Cell({
    required this.size,
    required this.segment,
    required this.selected,
    required this.idle,
    required this.ink,
    required this.onTap,
  });

  final Size size;
  final PlotcraftSegment<T> segment;
  final bool selected;
  final Color idle;
  final Color ink;
  final VoidCallback onTap;

  @override
  State<_Cell<T>> createState() => _CellState<T>();
}

class _CellState<T> extends State<_Cell<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: Tooltip(
      message: widget.segment.tooltip,
      child: Semantics(
        container: true,
        button: true,
        selected: widget.selected,
        label: widget.segment.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox.fromSize(
            size: widget.size,
            child: Center(
              child: Icon(
                widget.segment.icon,
                size: 16,
                color: widget.selected || _hovered ? widget.ink : widget.idle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
