import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../domain/workspace_tab.dart';
import 'workspace_icons.dart';

/// Narrow icon rail with the workspace sections and the way back to the
/// library. Names appear as tooltips.
class ActivityBar extends StatelessWidget {
  const ActivityBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    this.sections = WorkspaceSection.values,
  });

  static const width = 48.0;

  static const _labels = {
    WorkspaceSection.overview: 'workspace.overview',
    WorkspaceSection.manuscript: 'workspace.manuscript',
    WorkspaceSection.elements: 'elements.title',
    WorkspaceSection.graph: 'workspace.graph',
    WorkspaceSection.timeline: 'workspace.timeline',
    WorkspaceSection.gallery: 'workspace.gallery',
  };

  final WorkspaceSection selected;
  final ValueChanged<WorkspaceSection> onSelect;
  final VoidCallback onBack;

  /// Sections the project's format offers, in order.
  final List<WorkspaceSection> sections;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _BrandMark(color: scheme.primary),
          const SizedBox(height: 12),
          for (final section in sections)
            _item(
              context,
              section,
              WorkspaceIcons.of(section),
              _labels[section]!,
            ),
          const Spacer(),
          Tooltip(
            message: 'workspace.back_to_library'.tr(),
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Feather.arrow_left,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    WorkspaceSection section,
    IconData icon,
    String labelKey,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final active = section == selected;
    return Tooltip(
      message: labelKey.tr(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        ),
        child: IconButton(
          onPressed: () => onSelect(section),
          icon: Icon(
            icon,
            size: 18,
            color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
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
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(PlotcraftRadii.control),
    ),
    alignment: Alignment.center,
    child: Icon(
      Feather.book_open,
      color: Theme.of(context).colorScheme.onPrimary,
      size: 16,
    ),
  );
}
