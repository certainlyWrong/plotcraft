import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';
import 'gris/pigment_drop.dart';

enum PlotcraftButtonVariant { primary, secondary, text, destructive }

/// Shared button facade. Dimensions, colors, focus and shape are supplied by
/// the active app theme so every feature uses the same desktop interaction.
/// The primary button blooms a drop of pigment under the pointer.
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    // The accent is the ink of the current stage, so a button turns red in the
    // manuscript and green among the elements, as the website's does.
    final ink = context.tokens.ink;
    final onInk = ink.computeLuminance() > .38
        ? const Color(0xFF17201D)
        : Colors.white;
    return switch (variant) {
      // The drop of pigment only blooms for a button that can be pressed.
      PlotcraftButtonVariant.primary => PigmentDrop(
        active: onPressed == null ? false : null,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: onInk,
          ),
          child: child,
        ),
      ),
      PlotcraftButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(ink)),
        child: child,
      ),
      PlotcraftButtonVariant.text => TextButton(
        onPressed: onPressed,
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(ink)),
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
