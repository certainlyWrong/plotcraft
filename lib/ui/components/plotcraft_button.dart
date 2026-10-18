import 'package:flutter/material.dart';

enum PlotcraftButtonVariant { primary, secondary, text }

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
    final labelStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
      fontWeight: FontWeight.w600,
    );
    final child = icon == null
        ? Text(label, style: labelStyle)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 9),
              Text(label, style: labelStyle),
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
    };
  }
}
