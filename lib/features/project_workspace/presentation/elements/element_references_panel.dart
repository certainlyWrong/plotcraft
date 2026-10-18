import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../domain/book_content.dart';

/// Lists the manuscript documents that link to an element.
class ElementReferencesPanel extends StatelessWidget {
  const ElementReferencesPanel({
    super.key,
    required this.elementId,
    required this.book,
    required this.onOpen,
  });

  final String elementId;
  final BookContent book;

  /// Receives the chapter ID, or null for the single manuscript.
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    final references = book.referencesTo(
      elementId,
      'workspace.manuscript'.tr(),
    );
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.references'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (references.isEmpty) Text('elements.no_references'.tr()),
        for (final reference in references)
          ListTile(
            leading: const Icon(Feather.file_text, size: 17),
            title: Text(reference.title),
            onTap: () => onOpen(reference.chapterId),
          ),
      ],
    );
  }
}
