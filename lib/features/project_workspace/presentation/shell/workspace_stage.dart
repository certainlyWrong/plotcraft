import '../../../../core/theme/plotcraft_tokens.dart';
import '../../domain/workspace_tab.dart';

/// Where in the journey a part of the workspace sits, so the colour of the whole
/// window follows what you are doing: the overview is still grey; writing is
/// red; the story's elements are green; the map and the timeline are blue; the
/// reader and the gallery are yellow, where the colour finally settles.
StageId stageForSection(WorkspaceSection section) => switch (section) {
  WorkspaceSection.overview => StageId.grey,
  WorkspaceSection.manuscript => StageId.red,
  WorkspaceSection.elements => StageId.green,
  WorkspaceSection.graph || WorkspaceSection.timeline => StageId.blue,
  WorkspaceSection.gallery => StageId.yellow,
};

/// The stage of a tab: its section's, except the reader, which is yellow even
/// though it belongs to the manuscript.
StageId stageForTab(WorkspaceTab tab) => tab.kind == WorkspaceTabKind.reading
    ? StageId.yellow
    : stageForSection(tab.section);
