import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

/// A sheet of paper: the one container for grouped content. No shadow and no
/// hard outline — only a whisper of edge, and a faint tint of ink when it can
/// be pressed and the pointer is over it. Replaces `Card`.
class PlotcraftSurface extends StatefulWidget {
  const PlotcraftSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = PlotcraftRadii.surface,
    this.color,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Overrides the paper colour.
  final Color? color;

  /// Draws the edge in ink, for the current choice among several.
  final bool selected;

  @override
  State<PlotcraftSurface> createState() => _PlotcraftSurfaceState();
}

class _PlotcraftSurfaceState extends State<PlotcraftSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = context.tokens.ink;
    final interactive = widget.onTap != null;
    final radius = BorderRadius.circular(widget.radius);
    final paper = widget.color ?? scheme.surfaceContainer;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PlotcraftMotion.medium,
          curve: PlotcraftMotion.curve,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: _hovered && interactive
                ? Color.alphaBlend(ink.withValues(alpha: .06), paper)
                : paper,
            border: Border.all(
              color: widget.selected
                  ? ink
                  : scheme.outlineVariant.withValues(alpha: .7),
              width: widget.selected ? 1.4 : 1,
            ),
          ),
          // Content such as list tiles needs a Material beneath the painted
          // decoration to draw its own states on.
          child: Material(type: MaterialType.transparency, child: widget.child),
        ),
      ),
    );
  }
}

/// A sheet of paper whose content brings its own padding: the drop-in for the
/// plain `Card` that was used to group a block of content.
class PlotcraftCard extends StatelessWidget {
  const PlotcraftCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      PlotcraftSurface(padding: EdgeInsets.zero, child: child);
}
