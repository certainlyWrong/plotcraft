import 'package:flutter/material.dart';

/// Shared display for project keywords, using the typography selected in the
/// interface preferences.
class ProjectTags extends StatelessWidget {
  const ProjectTags({super.key, required this.tags, this.dense = false});

  final List<String> tags;

  /// Smaller chips for side panels.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags
          .map(
            (tag) => Chip(
              label: Text(tag),
              visualDensity: dense ? VisualDensity.compact : null,
              labelStyle: dense ? Theme.of(context).textTheme.bodySmall : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }
}
