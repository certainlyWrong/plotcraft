import 'package:flutter/material.dart';

class PlotcraftSegment<T> {
  const PlotcraftSegment({
    required this.value,
    required this.icon,
    required this.tooltip,
  });

  final T value;
  final IconData icon;
  final String tooltip;
}

/// Single-choice icon switcher (for example write / split / preview).
class PlotcraftSegmented<T> extends StatelessWidget {
  const PlotcraftSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<PlotcraftSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final segment in segments)
        ButtonSegment(
          value: segment.value,
          icon: Icon(segment.icon, size: 16),
          tooltip: segment.tooltip,
        ),
    ],
    selected: {selected},
    onSelectionChanged: (values) => onChanged(values.first),
  );
}
