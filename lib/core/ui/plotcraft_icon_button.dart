import 'package:flutter/material.dart';

/// Compact icon action with a mandatory tooltip, sized for desktop toolbars.
class PlotcraftIconButton extends StatelessWidget {
  const PlotcraftIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 18,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: size),
  );
}
