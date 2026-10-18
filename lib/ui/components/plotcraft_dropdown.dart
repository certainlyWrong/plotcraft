import 'package:flutter/material.dart';

class PlotcraftDropdown<T> extends StatelessWidget {
  const PlotcraftDropdown({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: initialValue,
    items: items,
    onChanged: onChanged,
    isExpanded: true,
    borderRadius: BorderRadius.circular(11),
    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
    menuMaxHeight: 360,
  );
}
