import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_chip.dart';

/// Shared display for project keywords: small tinted tags in the typography
/// selected in the interface preferences.
class ProjectTags extends StatelessWidget {
  const ProjectTags({super.key, required this.tags, this.dense = false});

  final List<String> tags;

  /// Smaller chips for side panels.
  final bool dense;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: dense ? 6 : 8,
    runSpacing: dense ? 6 : 8,
    children: [for (final tag in tags) PlotcraftChip(label: tag)],
  );
}
