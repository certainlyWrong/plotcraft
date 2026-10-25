import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

/// An icon that is a place to go: it lights up in ink under the pointer, and
/// while it is the current place a soft patch of pigment lies beneath it.
class PlotcraftNavIcon extends StatefulWidget {
  const PlotcraftNavIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.size = 40,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool selected;
  final double size;

  @override
  State<PlotcraftNavIcon> createState() => _PlotcraftNavIconState();
}

class _PlotcraftNavIconState extends State<PlotcraftNavIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = widget.onTap != null;
    final lit = widget.selected || (_hovered && enabled);
    final color = !enabled
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .38)
        : lit
        ? tokens.ink
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Semantics(
          container: true,
          excludeSemantics: true,
          button: true,
          enabled: enabled,
          selected: widget.selected,
          label: widget.tooltip,
          onTap: widget.onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: PlotcraftMotion.medium,
              curve: PlotcraftMotion.curve,
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.pigment.withValues(
                  alpha: widget.selected ? .28 : 0,
                ),
                // A resting patch is a leaf; a hovered one rounds out.
                borderRadius: BorderRadius.circular(
                  widget.selected ? widget.size / 2 : widget.size / 4,
                ),
              ),
              child: Icon(widget.icon, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
