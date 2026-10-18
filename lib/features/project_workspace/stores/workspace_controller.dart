import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:mobx/mobx.dart';

import '../../../core/storage/local_storage.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../domain/workspace_tab.dart';
import 'editor_fonts_store.dart';
import 'project_workspace_store.dart';

part 'workspace_controller.g.dart';

/// One open manuscript document: its Quill controller and the Delta that was
/// last saved, so the buffer knows when it has unsaved changes.
class DocumentBuffer {
  DocumentBuffer(Delta saved, {required VoidCallback onChanged})
    : savedDelta = saved,
      controller = QuillController(
        document: Document.fromDelta(saved),
        selection: const TextSelection.collapsed(offset: 0),
      ) {
    _changes = controller.document.changes.listen((_) => onChanged());
  }

  final QuillController controller;
  Delta savedDelta;
  Timer? autosave;
  late final StreamSubscription<DocChange> _changes;

  Delta get currentDelta => controller.document.toDelta();

  bool get isModified => currentDelta != savedDelta;

  /// Brings in a change made outside the app: the text becomes [delta] as a
  /// remote change (no undo step) and counts as saved.
  void applyExternal(Delta delta) {
    savedDelta = delta;
    final diff = currentDelta.diff(delta);
    if (diff.isEmpty) return;
    final last = (delta.length - 1).clamp(0, delta.length);
    final selection = controller.selection;
    controller.compose(
      diff,
      TextSelection(
        baseOffset: selection.baseOffset.clamp(0, last),
        extentOffset: selection.extentOffset.clamp(0, last),
      ),
      ChangeSource.remote,
    );
  }

  void dispose() {
    autosave?.cancel();
    unawaited(_changes.cancel());
    controller.dispose();
  }
}

/// Size limits of the resizable panels.
abstract final class WorkspaceLayout {
  static const minSidePanelWidth = 180.0;
  static const maxSidePanelWidth = 420.0;
  static const minInspectorWidth = 240.0;
  static const maxInspectorWidth = 460.0;
}

class WorkspaceController = _WorkspaceController with _$WorkspaceController;

/// UI state of an open project: tabs, panels, manuscript buffers and autosave.
/// Dialogs stay in the presentation layer; this class only decides and stores.
abstract class _WorkspaceController with Store {
  _WorkspaceController(
    this.store,
    this._initialProject,
    this._storage,
    this.fonts,
  ) {
    sidePanelWidth = _storage?.loadDouble(_sidePanelKey) ?? 250;
    inspectorWidth = _storage?.loadDouble(_inspectorKey) ?? 300;
    inspectorVisible = (_storage?.loadDouble(_inspectorVisibleKey) ?? 1) > 0;
  }

  static const _sidePanelKey = 'workspace.side_panel_width';
  static const _inspectorKey = 'workspace.inspector_width';
  static const _inspectorVisibleKey = 'workspace.inspector_visible';
  static const _autosaveDelay = Duration(seconds: 2);

  final ProjectWorkspaceStore store;

  /// Fonts the editor can use in this project.
  final EditorFontsStore fonts;
  final StoryProject _initialProject;
  StoryProject get initialProject => _initialProject;
  final LocalStorage? _storage;
  final _buffers = <String, DocumentBuffer>{};
  final _guards = <String, Future<bool> Function()>{};
  var _draftCounter = 0;
  final _draftTypes = <String, String>{};

  @observable
  ObservableList<WorkspaceTab> tabs = ObservableList.of([
    WorkspaceTab.overview,
  ]);

  @observable
  String? activeTabId = WorkspaceTab.overview.id;

  /// Which list the side panel shows; null hides the panel.
  @observable
  WorkspaceSection? sidePanel;

  @observable
  bool inspectorVisible = true;

  @observable
  double sidePanelWidth = 250;

  @observable
  double inspectorWidth = 300;

  @observable
  bool editorFullscreen = false;

  @observable
  bool loadFailed = false;

  /// Text to select and show when a manuscript tab is next displayed (for
  /// example after choosing an occurrence of an element), by tab ID.
  @observable
  ObservableMap<String, TextRange> revealRequests =
      ObservableMap<String, TextRange>();

  @observable
  ObservableSet<String> dirtyTabs = ObservableSet<String>();

  /// Tabs (`chapter:<id>`, `element:<id>`) whose file changed outside the app
  /// while they had unsaved edits: the person decides which version stays.
  @observable
  ObservableSet<String> externalConflicts = ObservableSet<String>();

  /// Bumped when a tab's content was replaced by a newer version from disk,
  /// so its editor is rebuilt from the fresh data.
  @observable
  ObservableMap<String, int> externalVersions = ObservableMap<String, int>();

  @computed
  WorkspaceTab? get activeTab =>
      tabs.where((tab) => tab.id == activeTabId).firstOrNull;

  /// Section highlighted in the activity bar: the panel in view, else the tab.
  @computed
  WorkspaceSection get activeSection =>
      sidePanel ?? activeTab?.section ?? WorkspaceSection.overview;

  /// Loads the project's files into the store and refreshes open documents.
  @action
  Future<void> load({String? firstChapterTitle}) async {
    loadFailed = false;
    try {
      await store.load(
        store.project ?? _initialProject,
        firstChapterTitle: firstChapterTitle,
      );
      resetBuffers();
      await fonts.load(store.project ?? _initialProject);
    } catch (_) {
      loadFailed = true;
    }
  }

  bool isDirty(String tabId) => dirtyTabs.contains(tabId);

  // --- Tabs ---------------------------------------------------------------

  @action
  void openTab(WorkspaceTab tab) {
    if (!tabs.contains(tab)) tabs.add(tab);
    activeTabId = tab.id;
  }

  @action
  void activate(String tabId) {
    if (tabs.any((tab) => tab.id == tabId)) activeTabId = tabId;
  }

  /// Opens an unsaved element of [typeId] (character when omitted).
  @action
  String newElementDraft([String? typeId]) {
    final tab = WorkspaceTab.element(
      '${WorkspaceTab.draftPrefix}${++_draftCounter}',
    );
    if (typeId != null) _draftTypes[tab.id] = typeId;
    openTab(tab);
    return tab.id;
  }

  /// Type chosen when the draft [tabId] was created.
  String? draftTypeFor(String tabId) => _draftTypes[tabId];

  /// Replaces a draft element tab with the saved element's tab.
  @action
  void promoteDraft(String draftTabId, String elementId) {
    final index = tabs.indexWhere((tab) => tab.id == draftTabId);
    if (index < 0) return;
    final next = WorkspaceTab.element(elementId);
    final wasActive = activeTabId == draftTabId;
    final existing = tabs.indexWhere((tab) => tab == next);
    if (existing >= 0 && existing != index) {
      tabs.removeAt(index);
    } else {
      tabs[index] = next;
    }
    _guards.remove(draftTabId);
    _draftTypes.remove(draftTabId);
    dirtyTabs.remove(draftTabId);
    if (wasActive) activeTabId = next.id;
  }

  /// Removes the tab without asking; call [canClose] first when it may hold
  /// unsaved work.
  @action
  void closeTabNow(String tabId) {
    final index = tabs.indexWhere((tab) => tab.id == tabId);
    if (index < 0) return;
    final tab = tabs[index];
    tabs.removeAt(index);
    dirtyTabs.remove(tabId);
    _guards.remove(tabId);
    _draftTypes.remove(tabId);
    if (tab.isManuscript) _disposeBuffer(_bufferKey(tab));
    if (activeTabId == tabId) {
      activeTabId = tabs.isEmpty
          ? null
          : tabs[index.clamp(0, tabs.length - 1)].id;
    }
    if (tabs.every((item) => !item.isManuscript)) editorFullscreen = false;
  }

  /// Registers how a tab confirms that it can be closed (for example an
  /// element editor asking about unsaved changes).
  void setGuard(String tabId, Future<bool> Function()? guard) {
    if (guard == null) {
      _guards.remove(tabId);
    } else {
      _guards[tabId] = guard;
    }
  }

  @action
  void setDirty(String tabId, bool dirty) {
    if (dirty) {
      dirtyTabs.add(tabId);
    } else {
      dirtyTabs.remove(tabId);
    }
  }

  /// Saves manuscripts and asks guarded tabs; false means "stay".
  Future<bool> canClose(String tabId) async {
    final tab = tabs.where((item) => item.id == tabId).firstOrNull;
    if (tab == null) return true;
    if (tab.isManuscript && !await saveBuffer(_bufferKey(tab))) return false;
    final guard = _guards[tabId];
    return guard == null || await guard();
  }

  /// True when every open tab can be left (used before leaving the project).
  Future<bool> canCloseAll() async {
    for (final tab in [...tabs]) {
      if (!await canClose(tab.id)) {
        activate(tab.id);
        return false;
      }
    }
    return true;
  }

  // --- Panels -------------------------------------------------------------

  @action
  void selectSection(WorkspaceSection section) {
    switch (section) {
      case WorkspaceSection.overview:
        openTab(WorkspaceTab.overview);
        sidePanel = null;
      case WorkspaceSection.gallery:
        openTab(WorkspaceTab.gallery);
        sidePanel = null;
      case WorkspaceSection.manuscript:
      case WorkspaceSection.elements:
        sidePanel = sidePanel == section ? null : section;
    }
  }

  @action
  void toggleInspector() {
    inspectorVisible = !inspectorVisible;
    unawaited(
      _storage?.saveDouble(_inspectorVisibleKey, inspectorVisible ? 1 : 0),
    );
  }

  @action
  void resizeSidePanel(double delta) {
    sidePanelWidth = (sidePanelWidth + delta).clamp(
      WorkspaceLayout.minSidePanelWidth,
      WorkspaceLayout.maxSidePanelWidth,
    );
  }

  @action
  void resizeInspector(double delta) {
    // The inspector is on the right, so dragging left makes it wider.
    inspectorWidth = (inspectorWidth - delta).clamp(
      WorkspaceLayout.minInspectorWidth,
      WorkspaceLayout.maxInspectorWidth,
    );
  }

  void persistPanelSizes() {
    unawaited(_storage?.saveDouble(_sidePanelKey, sidePanelWidth));
    unawaited(_storage?.saveDouble(_inspectorKey, inspectorWidth));
  }

  // --- Manuscript ---------------------------------------------------------

  String _bufferKey(WorkspaceTab tab) => tab.refId ?? 'single';

  /// Tab that edits [chapterId]; the single manuscript when it is null.
  WorkspaceTab manuscriptTab(String? chapterId) => chapterId == null
      ? WorkspaceTab.singleManuscript
      : WorkspaceTab.chapter(chapterId);

  DocumentBuffer bufferFor(String? chapterId) => _buffers.putIfAbsent(
    chapterId ?? 'single',
    () => DocumentBuffer(
      store.book.deltaFor(chapterId),
      onChanged: () => onBufferChanged(chapterId),
    ),
  );

  @action
  void openManuscript(String? chapterId, {TextRange? reveal}) {
    bufferFor(chapterId);
    final tab = manuscriptTab(chapterId);
    if (reveal != null) revealRequests[tab.id] = reveal;
    openTab(tab);
  }

  @action
  void clearReveal(String tabId) => revealRequests.remove(tabId);

  @action
  void onBufferChanged(String? chapterId) {
    final buffer = bufferFor(chapterId);
    final tabId = manuscriptTab(chapterId).id;
    setDirty(tabId, buffer.isModified);
    buffer.autosave?.cancel();
    buffer.autosave = Timer(_autosaveDelay, () {
      if (isDirty(tabId) &&
          !store.isSaving &&
          !externalConflicts.contains(tabId)) {
        unawaited(saveBuffer(chapterId ?? 'single'));
      }
    });
  }

  /// Saves one document. Returns true when it ends up clean.
  Future<bool> saveBuffer(String key, {bool force = false}) async {
    final chapterId = key == 'single' ? null : key;
    final buffer = _buffers[key];
    final tabId = manuscriptTab(chapterId).id;
    if (buffer == null) return true;
    // Writing now would erase what changed outside the app.
    if (!force && externalConflicts.contains(tabId)) return false;
    // The Delta is the truth; the dirty flag is updated by a stream event that
    // can lag behind an edit made a moment ago.
    if (!buffer.isModified) {
      runInAction(() => setDirty(tabId, false));
      return true;
    }
    if (store.isSaving) return false;
    buffer.autosave?.cancel();
    final delta = buffer.currentDelta;
    await store.saveBookDocument(chapterId, delta);
    buffer.savedDelta = delta;
    final current = !buffer.isModified;
    runInAction(() => setDirty(tabId, !current));
    if (!current) onBufferChanged(chapterId);
    return current;
  }

  /// Saves every modified manuscript; false when one could not be saved.
  Future<bool> saveAllBuffers() async {
    for (final key in _buffers.keys.toList()) {
      if (!await saveBuffer(key)) return false;
    }
    return true;
  }

  // --- Changes made outside the app ---------------------------------------

  /// Reads the project folder again after an external change and brings the
  /// open documents up to date: untouched ones are replaced, ones with unsaved
  /// edits are flagged in [externalConflicts]. Returns false when the store
  /// was busy and the caller should try again shortly.
  @action
  Future<bool> reloadFromDisk() async {
    final before = {
      for (final element in store.elements)
        element.id: jsonEncode(element.toJson()),
    };
    if (!await store.refreshFromDisk()) return false;
    for (final entry in _buffers.entries.toList()) {
      final chapterId = entry.key == 'single' ? null : entry.key;
      if (chapterId != null &&
          !store.book.chapters.any((chapter) => chapter.id == chapterId)) {
        continue;
      }
      final buffer = entry.value;
      final disk = store.book.deltaFor(chapterId);
      final tabId = manuscriptTab(chapterId).id;
      if (disk == buffer.savedDelta) continue;
      if (disk == buffer.currentDelta || !buffer.isModified) {
        buffer.applyExternal(disk);
        setDirty(tabId, false);
        externalConflicts.remove(tabId);
      } else {
        externalConflicts.add(tabId);
      }
    }
    for (final tab in [...tabs]) {
      if (tab.kind != WorkspaceTabKind.element || tab.isDraftElement) continue;
      final id = tab.refId!;
      final now = store.elements
          .where((element) => element.id == id)
          .firstOrNull;
      final changed = now == null
          ? before.containsKey(id)
          : before[id] != jsonEncode(now.toJson());
      if (!changed) continue;
      if (isDirty(tab.id)) {
        externalConflicts.add(tab.id);
      } else if (now == null) {
        closeTabNow(tab.id);
      } else {
        externalVersions[tab.id] = (externalVersions[tab.id] ?? 0) + 1;
      }
    }
    syncWithBook();
    return true;
  }

  /// Settles a tab flagged by [reloadFromDisk]: take the version on disk, or
  /// keep the edits (which will overwrite the file on the next save).
  @action
  Future<void> resolveExternalConflict(
    String tabId, {
    required bool keepMine,
  }) async {
    externalConflicts.remove(tabId);
    final tab = tabs.where((item) => item.id == tabId).firstOrNull;
    if (tab == null) return;
    if (tab.isManuscript) {
      final chapterId = tab.refId;
      final buffer = _buffers[chapterId ?? 'single'];
      if (buffer == null) return;
      if (keepMine) {
        await saveBuffer(chapterId ?? 'single', force: true);
      } else {
        buffer.applyExternal(store.book.deltaFor(chapterId));
        setDirty(tabId, false);
      }
    } else if (!keepMine) {
      setDirty(tabId, false);
      externalVersions[tabId] = (externalVersions[tabId] ?? 0) + 1;
    }
  }

  /// Aligns open documents with the book after chapters or the mode changed.
  @action
  void syncWithBook() {
    final book = store.book;
    final valid = <String>{
      if (!book.chaptersEnabled) WorkspaceTab.singleManuscript.id,
      if (book.chaptersEnabled)
        for (final chapter in book.chapters)
          WorkspaceTab.chapter(chapter.id).id,
    };
    for (final tab in [...tabs]) {
      if (tab.isManuscript && !valid.contains(tab.id)) closeTabNow(tab.id);
    }
  }

  /// Re-reads buffers from the store after a full reload.
  @action
  void resetBuffers() {
    for (final key in _buffers.keys.toList()) {
      _disposeBuffer(key);
    }
    for (final tab in [...tabs]) {
      if (tab.isManuscript) {
        dirtyTabs.remove(tab.id);
        bufferFor(tab.refId);
      }
    }
    syncWithBook();
  }

  void _disposeBuffer(String key) {
    _buffers.remove(key)?.dispose();
  }

  @action
  void toggleFullscreen(bool value) => editorFullscreen = value;

  void dispose() {
    for (final buffer in _buffers.values) {
      buffer.dispose();
    }
    _buffers.clear();
  }
}
