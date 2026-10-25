import 'package:flutter/material.dart';

import 'plotcraft_chip.dart';

class PlotcraftChoiceOption<T> {
  const PlotcraftChoiceOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// One choice among a few, spelled out in words: a row of tinted tags of which
/// the chosen one is deeper and underlined in ink. It stands where a segmented
/// button would, and wraps instead of overflowing in a narrow panel.
class PlotcraftChoice<T> extends StatelessWidget {
  const PlotcraftChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<PlotcraftChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final option in options)
        PlotcraftChip(
          label: option.label,
          icon: option.icon,
          selected: option.value == selected,
          onTap: () => onChanged(option.value),
        ),
    ],
  );
}
