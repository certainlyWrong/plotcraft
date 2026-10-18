import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../projects/domain/story_project.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

// The workspace keeps a compact navigation rail as its window narrows. Labels
// remain available as tooltips so the project still feels like a desktop tool.
enum WorkspaceSection { overview, manuscript, elements, gallery }

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    super.key,
    required this.project,
    required this.compact,
    required this.selected,
    required this.onSelect,
    required this.onBack,
  });

  final StoryProject project;
  final bool compact;
  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: compact ? 72 : 236,
      padding: EdgeInsets.fromLTRB(compact ? 8 : 14, 18, compact ? 8 : 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: compact
                ? Center(child: _BrandMark(color: scheme.primary))
                : Row(
                    children: [
                      _BrandMark(color: scheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Plotcraft',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          if (!compact) ...[
            Text(
              'workspace.project'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(PlotcraftRadii.control),
              ),
              child: Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
          _item(
            context,
            WorkspaceSection.overview,
            Feather.grid,
            'workspace.overview'.tr(),
          ),
          const SizedBox(height: 4),
          _item(
            context,
            WorkspaceSection.manuscript,
            Feather.file_text,
            'workspace.manuscript'.tr(),
          ),
          const SizedBox(height: 4),
          _item(
            context,
            WorkspaceSection.elements,
            Feather.users,
            'elements.title'.tr(),
          ),
          const SizedBox(height: 4),
          _item(
            context,
            WorkspaceSection.gallery,
            Feather.image,
            'workspace.gallery'.tr(),
          ),
          const Spacer(),
          Divider(color: scheme.outlineVariant),
          _backItem(context),
        ],
      ),
    );
  }

  Widget _backItem(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: compact ? 'workspace.back_to_library'.tr() : '',
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Icon(
                Feather.arrow_left,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              if (!compact) ...[
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'workspace.back_to_library'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (compact) const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    WorkspaceSection section,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = section == selected;
    return Tooltip(
      message: compact ? label : '',
      child: InkWell(
        onTap: () => onSelect(section),
        borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 11),
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              if (!compact) ...[
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: active
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(PlotcraftRadii.control),
    ),
    alignment: Alignment.center,
    child: Icon(
      Feather.book_open,
      color: Theme.of(context).colorScheme.onPrimary,
      size: 18,
    ),
  );
}
