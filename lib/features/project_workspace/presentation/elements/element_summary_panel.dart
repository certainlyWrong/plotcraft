import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/icons/icon_ref.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/project_image.dart';
import '../../domain/element_type.dart';
import '../../domain/narrative_element.dart';
import '../../../../core/ui/count_label.dart';
import '../widgets/project_tags.dart';
import 'element_type_label.dart';

/// Side summary of the element being edited: cover, type, tags, dates and how
/// many times it appears in the text. It follows the form as it is edited.
class ElementSummaryPanel extends StatelessWidget {
  const ElementSummaryPanel({
    super.key,
    required this.title,
    required this.type,
    required this.icon,
    required this.color,
    required this.coverPath,
    required this.tags,
    required this.aliasCount,
    required this.saved,
    required this.occurrenceCount,
    required this.linkedCount,
    required this.onEditAppearance,
    this.compact = false,
  });

  final String title;
  final ElementType? type;
  final IconRef icon;
  final Color color;
  final String? coverPath;
  final List<String> tags;
  final int aliasCount;

  /// The saved element, for its dates; null for a new one.
  final NarrativeElement? saved;
  final int occurrenceCount;
  final int linkedCount;
  final VoidCallback onEditAppearance;

  /// Cover beside the details, for pages too narrow for a side column.
  final bool compact;

  String _date(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return Localizations.localeOf(context).languageCode == 'pt'
        ? '$day/$month/${local.year}'
        : '$month/$day/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    final cover = coverPath != null
        ? ProjectImage(coverPath!, cacheWidth: 700)
        : ColoredBox(
            color: color.withValues(alpha: .14),
            child: Icon(icon.data, size: 56, color: color),
          );
    final details = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tooltip(
                message: 'elements.appearance'.tr(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEditAppearance,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon.data, size: 20, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? '—' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      type?.label ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            ProjectTags(tags: tags, dense: true),
          ],
          const SizedBox(height: 14),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 6),
          if (aliasCount > 0) row('elements.aliases'.tr(), '$aliasCount'),
          row(
            'elements.references'.tr(),
            saved == null
                ? '—'
                : countLabel('elements.occurrence_count', occurrenceCount),
          ),
          if (saved != null && occurrenceCount > 0)
            row('elements.linked_label'.tr(), '$linkedCount/$occurrenceCount'),
          if (saved != null) ...[
            row('workspace.created'.tr(), _date(context, saved!.createdAt)),
            row('workspace.updated'.tr(), _date(context, saved!.updatedAt)),
          ],
        ],
      ),
    );
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: compact
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 200, child: cover),
                  Expanded(child: details),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 16 / 10, child: cover),
                details,
              ],
            ),
    );
  }
}
