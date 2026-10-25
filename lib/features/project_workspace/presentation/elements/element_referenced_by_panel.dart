import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_reference.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

import '../../../../core/icons/icon_data.dart';
import '../element_colors.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

/// The elements whose details point to this one: the events that happened in
/// a place, the objects a character owns... Read-only; each opens its element.
class ElementReferencedByPanel extends StatelessWidget {
  const ElementReferencedByPanel({
    super.key,
    required this.references,
    required this.elements,
    required this.types,
    required this.onOpenElement,
  });

  final List<FieldReference> references;
  final List<NarrativeElement> elements;
  final List<ElementType> types;
  final ValueChanged<String> onOpenElement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.referenced_by'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: PlotcraftFonts.serif,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        for (final reference in references)
          Builder(
            builder: (context) {
              final source = elements
                  .where((e) => e.id == reference.sourceId)
                  .firstOrNull;
              if (source == null) return const SizedBox.shrink();
              final type = ElementTypeCatalog.resolve(source.typeId, types);
              final field = reference.field;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenElement(source.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Icon(
                        (source.icon ?? type?.icon ?? IconRef.fallback).data,
                        size: 16,
                        color:
                            source.color ?? type?.color ?? context.tokens.ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          source.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        field.labelKey != null
                            ? field.labelKey!.tr()
                            : field.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
