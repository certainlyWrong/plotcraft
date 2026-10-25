import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/gris/brand_mark.dart';
import '../../../../core/ui/plotcraft_nav_icon.dart';
import '../../domain/workspace_tab.dart';
import 'workspace_icons.dart';

/// Narrow rail of icons with the workspace sections and the way back to the
/// library. It has no fill and no rule: the icons rest on the paper, and the
/// section you are in carries a patch of pigment. Names appear as tooltips.
class ActivityBar extends StatelessWidget {
  const ActivityBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    this.onExport,
    this.sections = WorkspaceSection.values,
  });

  static const width = 56.0;

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

  /// Exports the book; null hides the button (projects without manuscript).
  final VoidCallback? onExport;

  /// Sections the project's format offers, in order.
  final List<WorkspaceSection> sections;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      children: [
        const SizedBox(height: 16),
        const BrandMark(size: 30),
        const SizedBox(height: 22),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: PlotcraftNavIcon(
              icon: WorkspaceIcons.of(section),
              tooltip: _labels[section]!.tr(),
              selected: section == selected,
              onTap: () => onSelect(section),
            ),
          ),
        const Spacer(),
        if (onExport != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: PlotcraftNavIcon(
              icon: Feather.download,
              tooltip: 'export.menu'.tr(),
              onTap: onExport,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: PlotcraftNavIcon(
            icon: Feather.arrow_left,
            tooltip: 'workspace.back_to_library'.tr(),
            onTap: onBack,
          ),
        ),
        const SizedBox(height: 14),
      ],
    ),
  );
}
