import 'package:flutter/material.dart';

/// Shared display for project keywords, using the typography selected in the
/// interface preferences.
class ProjectTags extends StatelessWidget {
  const ProjectTags({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags
          .map((tag) => Chip(label: Text(tag, style: labelStyle)))
          .toList(),
    );
  }
}
