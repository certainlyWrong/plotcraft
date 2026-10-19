import 'package:flutter/widgets.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../domain/workspace_tab.dart';

/// Icons of the workspace sections, shared by the activity bar and the tabs.
abstract final class WorkspaceIcons {
  static const overview = MaterialCommunityIcons.compass;
  static const manuscript = MaterialCommunityIcons.fountain_pen_tip;
  static const elements = MaterialCommunityIcons.account_group;
  static const gallery = MaterialCommunityIcons.image_filter_hdr;
  static const graph = MaterialCommunityIcons.google_circles_extended;
  static const timeline = MaterialCommunityIcons.chart_timeline;

  static IconData of(WorkspaceSection section) => switch (section) {
    WorkspaceSection.overview => overview,
    WorkspaceSection.manuscript => manuscript,
    WorkspaceSection.elements => elements,
    WorkspaceSection.gallery => gallery,
    WorkspaceSection.graph => graph,
    WorkspaceSection.timeline => timeline,
  };
}
