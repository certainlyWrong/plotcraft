import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/project_image.dart';
import '../../domain/element_type.dart';
import '../../domain/narrative_element.dart';
import '../elements/element_type_label.dart';

/// Summary of an element shown while the pointer rests on a mention: its
/// cover, type, summary, first details and the phase in force in the chapter.
class ElementHoverCard extends StatelessWidget {
  const ElementHoverCard({
    super.key,
    required this.element,
    required this.type,
    required this.coverPath,
    required this.phase,
  });

  static const width = 320.0;

  final NarrativeElement element;
  final ElementType? type;

  /// File of the element's cover image, when it has one that exists.
  final String? coverPath;
  final NarrativePhase? phase;

  /// Up to three filled details: the phase's values win over the element's.
  List<(String, String)> _details() {
    final fields = type?.fields ?? const <ElementField>[];
    final result = <(String, String)>[];
    for (final field in fields) {
      final value = (phase?.fieldOverrides[field.id] ?? '').isNotEmpty
          ? phase!.fieldOverrides[field.id]!
          : element.fields[field.id] ?? '';
      if (value.trim().isEmpty) continue;
      result.add((field.displayLabel, value.trim()));
      if (result.length == 3) break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = element.color ?? type?.color ?? scheme.primary;
    final icon = (element.icon ?? type?.icon ?? IconRef.fallback).data;
    final details = _details();
    final summary = element.summary.trim();
    return Material(
      color: scheme.surfaceContainer,
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverPath != null)
              SizedBox(
                height: 130,
                width: double.infinity,
                child: ProjectImage(coverPath!, cacheWidth: 640),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          type?.label ?? element.typeId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    element.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final (label, value) in details)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$label: ',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(text: value),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                  if (phase != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(
                          PlotcraftRadii.control,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Feather.clock, size: 13, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phase!.description.trim().isEmpty
                                  ? phase!.title
                                  : '${phase!.title}: ${phase!.description.trim()}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'editor.hover_open_hint'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
