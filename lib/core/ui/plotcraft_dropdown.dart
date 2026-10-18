import 'package:flutter/material.dart';

import '../theme/plotcraft_tokens.dart';

class PlotcraftDropdown<T> extends StatelessWidget {
  const PlotcraftDropdown({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.label,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  /// Same height as a compact [PlotcraftTextField]; otherwise the height of a
  /// regular one, so a dropdown next to a field lines up with it.
  final bool compact;
  final String? label;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: initialValue,
    items: items,
    onChanged: onChanged,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      isDense: compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 8 : 10,
      ),
    ),
    borderRadius: BorderRadius.circular(PlotcraftRadii.control),
    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
    menuMaxHeight: 360,
  );
}
