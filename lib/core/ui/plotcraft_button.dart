import 'package:flutter/material.dart';

enum PlotcraftButtonVariant { primary, secondary, text, destructive }

/// Shared button facade. Dimensions, colors, focus and shape are supplied by
/// the active app theme so every feature uses the same desktop interaction.
class PlotcraftButton extends StatelessWidget {
  const PlotcraftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PlotcraftButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PlotcraftButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 9),
              Text(label),
            ],
          );
    return switch (variant) {
      PlotcraftButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      PlotcraftButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
      PlotcraftButtonVariant.text => TextButton(
        onPressed: onPressed,
        child: child,
      ),
      PlotcraftButtonVariant.destructive => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: child,
      ),
    };
  }
}
