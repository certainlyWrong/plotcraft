import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';

class PlotcraftPopupMenuButton<T> extends StatelessWidget {
  const PlotcraftPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.initialValue,
    this.tooltip,
    this.child,
    this.icon,
    this.iconColor,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T>? onSelected;
  final T? initialValue;
  final String? tooltip;
  final Widget? child;
  final Widget? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    itemBuilder: itemBuilder,
    onSelected: onSelected,
    initialValue: initialValue,
    tooltip: tooltip,
    icon: icon,
    iconColor: iconColor,
    clipBehavior: Clip.antiAlias,
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        ),
      ),
      overlayColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      ),
    ),
    child: child,
  );
}
