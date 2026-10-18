import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';

class ProjectSidebar extends StatelessWidget {
  const ProjectSidebar({
    super.key,
    required this.compact,
    required this.onPreferences,
    required this.onProjects,
    required this.onNewProject,
    required this.projectsSelected,
    required this.createSelected,
    required this.preferencesSelected,
  });

  final bool compact;
  final VoidCallback onPreferences;
  final VoidCallback onProjects;
  final VoidCallback onNewProject;
  final bool projectsSelected;
  final bool createSelected;
  final bool preferencesSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: compact ? 72 : 236,
      padding: EdgeInsets.fromLTRB(compact ? 8 : 14, 28, compact ? 8 : 14, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Center(child: _BrandMark(color: theme.colorScheme.primary))
          else
            Row(
              children: [
                _BrandMark(color: theme.colorScheme.primary),
                const SizedBox(width: 11),
                Text(
                  'plotcraft',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
              ],
            ),
          SizedBox(height: compact ? 28 : 34),
          _NavigationItem(
            icon: Feather.grid,
            label: 'home.projects'.tr(),
            selected: projectsSelected,
            onTap: onProjects,
            compact: compact,
          ),
          const SizedBox(height: 4),
          _NavigationItem(
            icon: Feather.plus,
            label: 'home.new_project'.tr(),
            selected: createSelected,
            onTap: onNewProject,
            compact: compact,
          ),
          const Spacer(),
          Divider(color: theme.colorScheme.outlineVariant),
          _NavigationItem(
            icon: Feather.sliders,
            label: 'preferences.title'.tr(),
            selected: preferencesSelected,
            onTap: onPreferences,
            compact: compact,
          ),
          const SizedBox(height: 6),
          if (!compact)
            Text(
              'PLOTCRAFT  ·  0.1',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: .45),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 35,
    height: 35,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(PlotcraftRadii.control),
    ),
    child: Icon(
      Feather.book_open,
      color: Theme.of(context).colorScheme.onPrimary,
      size: 19,
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconWidget = SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          icon,
          size: 19,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return Tooltip(
      message: compact ? label : '',
      child: SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(PlotcraftRadii.control),
            ),
            child: compact
                ? Center(child: iconWidget)
                : Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
