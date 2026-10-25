import 'package:flutter/material.dart';

import '../../../../core/theme/plotcraft_tokens.dart';

/// Row used by the side panel lists: icon, label, optional subtitle and a
/// trailing widget. The selected row lies on a patch of pigment; the one under
/// the pointer is only tinted.
class PanelListItem extends StatefulWidget {
  const PanelListItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Overrides the icon color (for example the color of an element type).
  final Color? iconColor;

  @override
  State<PanelListItem> createState() => _PanelListItemState();
}

class _PanelListItemState extends State<PanelListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final tint = widget.selected
        ? .2
        : _hovered
        ? .08
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Semantics(
            container: true,
            button: true,
            selected: widget.selected,
            child: AnimatedContainer(
              duration: PlotcraftMotion.quick,
              curve: PlotcraftMotion.curve,
              padding: const EdgeInsets.only(
                left: 10,
                top: 6,
                bottom: 6,
                right: 2,
              ),
              decoration: BoxDecoration(
                color: tokens.ink.withValues(alpha: tint),
                borderRadius: BorderRadius.circular(PlotcraftRadii.control),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 15,
                    color:
                        widget.iconColor ??
                        (widget.selected
                            ? tokens.ink
                            : scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?widget.trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
