import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../theme/plotcraft_tokens.dart';

/// A small tinted tag: a value, a filter, a choice. It is a soft patch of ink
/// rather than an outlined pill, and a selected one deepens its tint and gains
/// a line of ink beneath. Pass [onTap] to make it a choice, [onDeleted] for a
/// removable value.
class PlotcraftChip extends StatefulWidget {
  const PlotcraftChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.icon,
    this.iconColor,
    this.deleteTooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final IconData? icon;

  /// Colour of [icon]; defaults to the ink of the stage.
  final Color? iconColor;
  final String? deleteTooltip;

  @override
  State<PlotcraftChip> createState() => _PlotcraftChipState();
}

class _PlotcraftChipState extends State<PlotcraftChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = context.tokens.ink;
    final interactive = widget.onTap != null;
    final tint = widget.selected
        ? .22
        : (_hovered && interactive)
        ? .14
        : .08;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Semantics(
          container: true,
          button: interactive,
          selected: widget.selected,
          child: AnimatedContainer(
            duration: PlotcraftMotion.quick,
            curve: PlotcraftMotion.curve,
            padding: EdgeInsets.fromLTRB(
              10,
              4,
              widget.onDeleted == null ? 10 : 4,
              4,
            ),
            decoration: BoxDecoration(
              color: ink.withValues(alpha: tint),
              borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
              border: Border(
                bottom: BorderSide(
                  color: widget.selected ? ink : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: widget.iconColor ?? ink),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.onDeleted != null) ...[
                  const SizedBox(width: 2),
                  Tooltip(
                    message: widget.deleteTooltip ?? '',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDeleted,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Feather.x,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
