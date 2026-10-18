import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

/// Where an element appears in the book. Choosing an occurrence opens that
/// chapter with the text selected.
class ElementReferencesPanel extends StatelessWidget {
  const ElementReferencesPanel({
    super.key,
    required this.occurrences,
    required this.onOpen,
  });

  final List<MentionOccurrence> occurrences;
  final ValueChanged<MentionOccurrence> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final linked = occurrences.where((o) => o.linked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.references'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (occurrences.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'elements.occurrences_summary'.tr(
                namedArgs: {
                  'count': '${occurrences.length}',
                  'linked': '$linked',
                },
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (occurrences.isEmpty) Text('elements.no_references'.tr()),
        for (final occurrence in occurrences)
          ListTile(
            dense: true,
            leading: Icon(
              occurrence.linked ? Feather.link : Feather.file_text,
              size: 16,
              color: occurrence.linked ? scheme.primary : null,
            ),
            title: Text(
              occurrence.snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(occurrence.chapterTitle),
            onTap: () => onOpen(occurrence),
          ),
      ],
    );
  }
}
