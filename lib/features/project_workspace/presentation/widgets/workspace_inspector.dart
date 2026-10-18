import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../projects/domain/story_project.dart';
import '../../domain/workspace_tab.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import 'project_cover_art.dart';
import 'project_tags.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

class WorkspaceInspector extends StatelessWidget {
  const WorkspaceInspector({
    super.key,
    required this.project,
    required this.section,
    required this.wordCount,
    required this.imageCount,
    required this.onEditProject,
    required this.onClose,
  });

  final StoryProject project;
  final WorkspaceSection section;
  final int wordCount;
  final int imageCount;
  final VoidCallback onEditProject;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'workspace.inspector'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PlotcraftIconButton(
                    icon: Feather.x,
                    tooltip: 'workspace.close_inspector'.tr(),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SizedBox(height: 146, child: ProjectCoverArt(project: project)),
                const SizedBox(height: 16),
                Text(
                  project.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (project.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _sectionLabel(context, 'workspace.project_details'.tr()),
                const SizedBox(height: 11),
                _detail(context, 'workspace.author'.tr(), project.author),
                _detail(context, 'workspace.genre'.tr(), project.genre),
                _detail(
                  context,
                  'workspace.format'.tr(),
                  project.primaryFormat == 'book'
                      ? 'workspace.book'.tr()
                      : project.primaryFormat,
                ),
                if (project.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ProjectTags(tags: project.tags),
                ],
                const SizedBox(height: 18),
                _sectionLabel(context, 'workspace.dates'.tr()),
                const SizedBox(height: 7),
                _detail(
                  context,
                  'workspace.created'.tr(),
                  _date(context, project.createdAt),
                ),
                _detail(
                  context,
                  'workspace.updated'.tr(),
                  _date(context, project.updatedAt),
                ),
                const SizedBox(height: 14),
                _sectionLabel(context, 'workspace.folder'.tr()),
                const SizedBox(height: 6),
                SelectableText(
                  project.directoryPath ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _sectionLabel(context, 'workspace.current_section'.tr()),
                const SizedBox(height: 8),
                _sectionSummary(context),
                const SizedBox(height: 20),
                PlotcraftButton(
                  onPressed: onEditProject,
                  icon: Feather.edit_2,
                  label: 'workspace.edit_project'.tr(),
                  variant: PlotcraftButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionSummary(BuildContext context) {
    final (icon, label, value) = switch (section) {
      WorkspaceSection.overview => (
        Feather.grid,
        'workspace.overview'.tr(),
        'workspace.inspector_overview'.tr(),
      ),
      WorkspaceSection.manuscript => (
        Feather.file_text,
        'workspace.manuscript'.tr(),
        'workspace.word_count'.tr(namedArgs: {'count': '$wordCount'}),
      ),
      WorkspaceSection.elements => (
        Feather.users,
        'elements.title'.tr(),
        'elements.inspector_summary'.tr(),
      ),
      WorkspaceSection.gallery => (
        Feather.image,
        'workspace.gallery'.tr(),
        'workspace.image_count'.tr(namedArgs: {'count': '$imageCount'}),
      ),
    };
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(PlotcraftRadii.control),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: .8,
      fontWeight: FontWeight.w700,
    ),
  );

  String _date(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return Localizations.localeOf(context).languageCode == 'pt'
        ? '$day/$month/${local.year}'
        : '$month/$day/${local.year}';
  }

  Widget _detail(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
