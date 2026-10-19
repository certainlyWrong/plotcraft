// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WorkspaceController on _WorkspaceController, Store {
  Computed<WorkspaceTab?>? _$activeTabComputed;

  @override
  WorkspaceTab? get activeTab =>
      (_$activeTabComputed ??= Computed<WorkspaceTab?>(
        () => super.activeTab,
        name: '_WorkspaceController.activeTab',
      )).value;
  Computed<WorkspaceSection>? _$activeSectionComputed;

  @override
  WorkspaceSection get activeSection =>
      (_$activeSectionComputed ??= Computed<WorkspaceSection>(
        () => super.activeSection,
        name: '_WorkspaceController.activeSection',
      )).value;

  late final _$tabsAtom = Atom(
    name: '_WorkspaceController.tabs',
    context: context,
  );

  @override
  ObservableList<WorkspaceTab> get tabs {
    _$tabsAtom.reportRead();
    return super.tabs;
  }

  @override
  set tabs(ObservableList<WorkspaceTab> value) {
    _$tabsAtom.reportWrite(value, super.tabs, () {
      super.tabs = value;
    });
  }

  late final _$activeTabIdAtom = Atom(
    name: '_WorkspaceController.activeTabId',
    context: context,
  );

  @override
  String? get activeTabId {
    _$activeTabIdAtom.reportRead();
    return super.activeTabId;
  }

  @override
  set activeTabId(String? value) {
    _$activeTabIdAtom.reportWrite(value, super.activeTabId, () {
      super.activeTabId = value;
    });
  }

  late final _$sidePanelAtom = Atom(
    name: '_WorkspaceController.sidePanel',
    context: context,
  );

  @override
  WorkspaceSection? get sidePanel {
    _$sidePanelAtom.reportRead();
    return super.sidePanel;
  }

  @override
  set sidePanel(WorkspaceSection? value) {
    _$sidePanelAtom.reportWrite(value, super.sidePanel, () {
      super.sidePanel = value;
    });
  }

  late final _$inspectorVisibleAtom = Atom(
    name: '_WorkspaceController.inspectorVisible',
    context: context,
  );

  @override
  bool get inspectorVisible {
    _$inspectorVisibleAtom.reportRead();
    return super.inspectorVisible;
  }

  @override
  set inspectorVisible(bool value) {
    _$inspectorVisibleAtom.reportWrite(value, super.inspectorVisible, () {
      super.inspectorVisible = value;
    });
  }

  late final _$sidePanelWidthAtom = Atom(
    name: '_WorkspaceController.sidePanelWidth',
    context: context,
  );

  @override
  double get sidePanelWidth {
    _$sidePanelWidthAtom.reportRead();
    return super.sidePanelWidth;
  }

  @override
  set sidePanelWidth(double value) {
    _$sidePanelWidthAtom.reportWrite(value, super.sidePanelWidth, () {
      super.sidePanelWidth = value;
    });
  }

  late final _$inspectorWidthAtom = Atom(
    name: '_WorkspaceController.inspectorWidth',
    context: context,
  );

  @override
  double get inspectorWidth {
    _$inspectorWidthAtom.reportRead();
    return super.inspectorWidth;
  }

  @override
  set inspectorWidth(double value) {
    _$inspectorWidthAtom.reportWrite(value, super.inspectorWidth, () {
      super.inspectorWidth = value;
    });
  }

  late final _$editorFullscreenAtom = Atom(
    name: '_WorkspaceController.editorFullscreen',
    context: context,
  );

  @override
  bool get editorFullscreen {
    _$editorFullscreenAtom.reportRead();
    return super.editorFullscreen;
  }

  @override
  set editorFullscreen(bool value) {
    _$editorFullscreenAtom.reportWrite(value, super.editorFullscreen, () {
      super.editorFullscreen = value;
    });
  }

  late final _$loadFailedAtom = Atom(
    name: '_WorkspaceController.loadFailed',
    context: context,
  );

  @override
  bool get loadFailed {
    _$loadFailedAtom.reportRead();
    return super.loadFailed;
  }

  @override
  set loadFailed(bool value) {
    _$loadFailedAtom.reportWrite(value, super.loadFailed, () {
      super.loadFailed = value;
    });
  }

  late final _$revealRequestsAtom = Atom(
    name: '_WorkspaceController.revealRequests',
    context: context,
  );

  @override
  ObservableMap<String, TextRange> get revealRequests {
    _$revealRequestsAtom.reportRead();
    return super.revealRequests;
  }

  @override
  set revealRequests(ObservableMap<String, TextRange> value) {
    _$revealRequestsAtom.reportWrite(value, super.revealRequests, () {
      super.revealRequests = value;
    });
  }

  late final _$readingRequestsAtom = Atom(
    name: '_WorkspaceController.readingRequests',
    context: context,
  );

  @override
  ObservableMap<String, String> get readingRequests {
    _$readingRequestsAtom.reportRead();
    return super.readingRequests;
  }

  @override
  set readingRequests(ObservableMap<String, String> value) {
    _$readingRequestsAtom.reportWrite(value, super.readingRequests, () {
      super.readingRequests = value;
    });
  }

  late final _$dirtyTabsAtom = Atom(
    name: '_WorkspaceController.dirtyTabs',
    context: context,
  );

  @override
  ObservableSet<String> get dirtyTabs {
    _$dirtyTabsAtom.reportRead();
    return super.dirtyTabs;
  }

  @override
  set dirtyTabs(ObservableSet<String> value) {
    _$dirtyTabsAtom.reportWrite(value, super.dirtyTabs, () {
      super.dirtyTabs = value;
    });
  }

  late final _$externalConflictsAtom = Atom(
    name: '_WorkspaceController.externalConflicts',
    context: context,
  );

  @override
  ObservableSet<String> get externalConflicts {
    _$externalConflictsAtom.reportRead();
    return super.externalConflicts;
  }

  @override
  set externalConflicts(ObservableSet<String> value) {
    _$externalConflictsAtom.reportWrite(value, super.externalConflicts, () {
      super.externalConflicts = value;
    });
  }

  late final _$externalVersionsAtom = Atom(
    name: '_WorkspaceController.externalVersions',
    context: context,
  );

  @override
  ObservableMap<String, int> get externalVersions {
    _$externalVersionsAtom.reportRead();
    return super.externalVersions;
  }

  @override
  set externalVersions(ObservableMap<String, int> value) {
    _$externalVersionsAtom.reportWrite(value, super.externalVersions, () {
      super.externalVersions = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    '_WorkspaceController.load',
    context: context,
  );

  @override
  Future<void> load({String? firstChapterTitle}) {
    return _$loadAsyncAction.run(
      () => super.load(firstChapterTitle: firstChapterTitle),
    );
  }

  late final _$reloadFromDiskAsyncAction = AsyncAction(
    '_WorkspaceController.reloadFromDisk',
    context: context,
  );

  @override
  Future<bool> reloadFromDisk() {
    return _$reloadFromDiskAsyncAction.run(() => super.reloadFromDisk());
  }

  late final _$resolveExternalConflictAsyncAction = AsyncAction(
    '_WorkspaceController.resolveExternalConflict',
    context: context,
  );

  @override
  Future<void> resolveExternalConflict(String tabId, {required bool keepMine}) {
    return _$resolveExternalConflictAsyncAction.run(
      () => super.resolveExternalConflict(tabId, keepMine: keepMine),
    );
  }

  late final _$_WorkspaceControllerActionController = ActionController(
    name: '_WorkspaceController',
    context: context,
  );

  @override
  void openTab(WorkspaceTab tab) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.openTab',
    );
    try {
      return super.openTab(tab);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void activate(String tabId) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.activate',
    );
    try {
      return super.activate(tabId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void moveTab(int from, int to) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.moveTab',
    );
    try {
      return super.moveTab(from, to);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  String newElementDraft([String? typeId]) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.newElementDraft',
    );
    try {
      return super.newElementDraft(typeId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void promoteDraft(String draftTabId, String elementId) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.promoteDraft',
    );
    try {
      return super.promoteDraft(draftTabId, elementId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void closeTabNow(String tabId) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.closeTabNow',
    );
    try {
      return super.closeTabNow(tabId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDirty(String tabId, bool dirty) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.setDirty',
    );
    try {
      return super.setDirty(tabId, dirty);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectSection(WorkspaceSection section) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.selectSection',
    );
    try {
      return super.selectSection(section);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleInspector() {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.toggleInspector',
    );
    try {
      return super.toggleInspector();
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resizeSidePanel(double delta) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.resizeSidePanel',
    );
    try {
      return super.resizeSidePanel(delta);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resizeInspector(double delta) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.resizeInspector',
    );
    try {
      return super.resizeInspector(delta);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void openManuscript(String? chapterId, {TextRange? reveal}) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.openManuscript',
    );
    try {
      return super.openManuscript(chapterId, reveal: reveal);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearReveal(String tabId) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.clearReveal',
    );
    try {
      return super.clearReveal(tabId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void openReading([String? chapterId]) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.openReading',
    );
    try {
      return super.openReading(chapterId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearReadingRequest() {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.clearReadingRequest',
    );
    try {
      return super.clearReadingRequest();
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void onBufferChanged(String? chapterId) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.onBufferChanged',
    );
    try {
      return super.onBufferChanged(chapterId);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void syncWithBook() {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.syncWithBook',
    );
    try {
      return super.syncWithBook();
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetBuffers() {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.resetBuffers',
    );
    try {
      return super.resetBuffers();
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleFullscreen(bool value) {
    final _$actionInfo = _$_WorkspaceControllerActionController.startAction(
      name: '_WorkspaceController.toggleFullscreen',
    );
    try {
      return super.toggleFullscreen(value);
    } finally {
      _$_WorkspaceControllerActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
tabs: ${tabs},
activeTabId: ${activeTabId},
sidePanel: ${sidePanel},
inspectorVisible: ${inspectorVisible},
sidePanelWidth: ${sidePanelWidth},
inspectorWidth: ${inspectorWidth},
editorFullscreen: ${editorFullscreen},
loadFailed: ${loadFailed},
revealRequests: ${revealRequests},
readingRequests: ${readingRequests},
dirtyTabs: ${dirtyTabs},
externalConflicts: ${externalConflicts},
externalVersions: ${externalVersions},
activeTab: ${activeTab},
activeSection: ${activeSection}
    ''';
  }
}
