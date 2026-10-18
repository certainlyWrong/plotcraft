/// Areas of the workspace reachable from the activity bar.
enum WorkspaceSection { overview, manuscript, elements, gallery }

enum WorkspaceTabKind {
  overview,
  settings,
  gallery,
  manuscript,
  chapter,
  element,
}

/// A document open in the editor area. [refId] is the chapter or element ID;
/// element IDs starting with [draftPrefix] are elements not saved yet.
class WorkspaceTab {
  const WorkspaceTab(this.kind, [this.refId]);

  static const overview = WorkspaceTab(WorkspaceTabKind.overview);
  static const settings = WorkspaceTab(WorkspaceTabKind.settings);
  static const gallery = WorkspaceTab(WorkspaceTabKind.gallery);
  static const singleManuscript = WorkspaceTab(WorkspaceTabKind.manuscript);
  static const draftPrefix = 'new-';

  factory WorkspaceTab.chapter(String id) =>
      WorkspaceTab(WorkspaceTabKind.chapter, id);
  factory WorkspaceTab.element(String id) =>
      WorkspaceTab(WorkspaceTabKind.element, id);

  final WorkspaceTabKind kind;
  final String? refId;

  String get id => refId == null ? kind.name : '${kind.name}:$refId';

  bool get isDraftElement =>
      kind == WorkspaceTabKind.element &&
      (refId?.startsWith(draftPrefix) ?? false);

  /// Chapter ID of a manuscript document: null for the single manuscript.
  bool get isManuscript =>
      kind == WorkspaceTabKind.manuscript || kind == WorkspaceTabKind.chapter;

  WorkspaceSection get section => switch (kind) {
    WorkspaceTabKind.overview ||
    WorkspaceTabKind.settings => WorkspaceSection.overview,
    WorkspaceTabKind.gallery => WorkspaceSection.gallery,
    WorkspaceTabKind.manuscript ||
    WorkspaceTabKind.chapter => WorkspaceSection.manuscript,
    WorkspaceTabKind.element => WorkspaceSection.elements,
  };

  @override
  bool operator ==(Object other) => other is WorkspaceTab && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
