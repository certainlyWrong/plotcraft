import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_context_menu.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_splitter.dart';
import '../../../../core/ui/plotcraft_tab_bar.dart';
import '../../../projects/domain/story_project.dart';
import '../../domain/workspace_tab.dart';
import '../../stores/workspace_controller.dart';
import '../elements/element_list.dart';
import '../manuscript/chapter_list.dart';
import '../widgets/workspace_inspector.dart';
import '../workspace_actions.dart';
import 'activity_bar.dart';
import 'side_panel.dart';
import 'workspace_tab_content.dart';

enum _TabMenu { close, closeOthers }

/// Desktop layout of an open project: activity bar, side panel, tabbed editor
/// area and inspector, with draggable dividers between them.
class WorkspaceShell extends StatelessWidget {
  const WorkspaceShell({
    super.key,
    required this.project,
    required this.controller,
    required this.actions,
    required this.onBack,
  });

  final StoryProject project;
  final WorkspaceController controller;
  final WorkspaceActions actions;
  final VoidCallback onBack;

  /// The store holds the latest project (for example after editing it).
  StoryProject get _project => controller.store.project ?? project;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (context) {
      final store = controller.store;
      final activeTab = controller.activeTab;
      if (controller.editorFullscreen &&
          activeTab != null &&
          activeTab.isManuscript) {
        return Scaffold(
          body: SafeArea(
            child: WorkspaceTabContent(
              key: ValueKey(activeTab.id),
              tab: activeTab,
              project: _project,
              controller: controller,
              actions: actions,
            ),
          ),
        );
      }
      final panel = controller.sidePanel;
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              ActivityBar(
                selected: controller.activeSection,
                onSelect: controller.selectSection,
                onBack: onBack,
              ),
              if (panel != null) ...[
                SizedBox(
                  width: controller.sidePanelWidth,
                  child: _sidePanel(context, panel),
                ),
                PlotcraftSplitter(
                  onDrag: controller.resizeSidePanel,
                  onDragEnd: controller.persistPanelSizes,
                ),
              ],
              Expanded(
                child: store.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.loadFailed
                    ? _loadError()
                    : _editorArea(context),
              ),
              if (controller.inspectorVisible) ...[
                PlotcraftSplitter(
                  onDrag: controller.resizeInspector,
                  onDragEnd: controller.persistPanelSizes,
                ),
                SizedBox(
                  width: controller.inspectorWidth,
                  child: WorkspaceInspector(
                    project: _project,
                    section: activeTab?.section ?? WorkspaceSection.overview,
                    wordCount: store.wordCount,
                    imageCount: store.galleryImages.length,
                    onEditProject: () =>
                        controller.openTab(WorkspaceTab.settings),
                    onClose: controller.toggleInspector,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _sidePanel(BuildContext context, WorkspaceSection panel) {
    final store = controller.store;
    final activeTab = controller.activeTab;
    return switch (panel) {
      WorkspaceSection.elements => SidePanel(
        title: 'elements.title'.tr(),
        actions: [
          PlotcraftIconButton(
            icon: Feather.plus,
            tooltip: 'elements.new'.tr(),
            onPressed: () => actions.newElement(context),
          ),
        ],
        child: ElementList(
          elements: store.elements.toList(),
          types: store.elementTypes,
          activeElementId: activeTab?.kind == WorkspaceTabKind.element
              ? activeTab?.refId
              : null,
          onOpen: (element) => actions.openElement(element.id),
          onAction: (element, _) => actions.removeElement(context, element),
        ),
      ),
      _ => SidePanel(
        title: 'workspace.manuscript'.tr(),
        actions: [
          if (store.book.chaptersEnabled)
            PlotcraftIconButton(
              icon: Feather.plus,
              tooltip: 'book.add_chapter'.tr(),
              onPressed: store.isBookUpdating
                  ? null
                  : () => actions.addChapter(context),
            ),
        ],
        child: ChapterList(
          book: store.book,
          activeChapterId: activeTab?.kind == WorkspaceTabKind.chapter
              ? activeTab?.refId
              : null,
          singleActive: activeTab?.kind == WorkspaceTabKind.manuscript,
          busy: store.isBookUpdating,
          onOpen: controller.openManuscript,
          onOpenSingle: () => controller.openManuscript(null),
          onAction: (chapter, action) =>
              actions.chapterAction(context, chapter, action),
          onToggleChapters: () => actions.toggleChapters(context),
        ),
      ),
    };
  }

  Widget _editorArea(BuildContext context) {
    final tabs = controller.tabs.toList();
    final activeIndex = tabs.indexWhere(
      (tab) => tab.id == controller.activeTabId,
    );
    return Column(
      children: [
        PlotcraftTabBar(
          tabs: [for (final tab in tabs) _tabData(tab)],
          activeId: controller.activeTabId,
          onSelect: controller.activate,
          onClose: (id) => actions.closeTab(context, id),
          onTabMenu: (id, position) => _openTabMenu(context, id, position),
          trailing: PlotcraftIconButton(
            icon: Feather.sidebar,
            tooltip:
                (controller.inspectorVisible
                        ? 'workspace.close_inspector'
                        : 'workspace.open_inspector')
                    .tr(),
            onPressed: controller.toggleInspector,
          ),
        ),
        Expanded(
          child: tabs.isEmpty
              ? _emptyState(context)
              : IndexedStack(
                  index: activeIndex < 0 ? 0 : activeIndex,
                  children: [
                    for (final tab in tabs)
                      WorkspaceTabContent(
                        key: ValueKey(tab.id),
                        tab: tab,
                        project: _project,
                        controller: controller,
                        actions: actions,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  PlotcraftTabData _tabData(WorkspaceTab tab) {
    final store = controller.store;
    final (title, icon) = switch (tab.kind) {
      WorkspaceTabKind.overview => ('workspace.overview'.tr(), Feather.grid),
      WorkspaceTabKind.settings => (
        'workspace.edit_project'.tr(),
        Feather.settings,
      ),
      WorkspaceTabKind.gallery => ('workspace.gallery'.tr(), Feather.image),
      WorkspaceTabKind.manuscript => (
        'workspace.manuscript'.tr(),
        Feather.file_text,
      ),
      WorkspaceTabKind.chapter => (
        store.book.chapters
                .where((chapter) => chapter.id == tab.refId)
                .firstOrNull
                ?.title ??
            'workspace.manuscript'.tr(),
        Feather.file_text,
      ),
      WorkspaceTabKind.element => (
        store.elements
                .where((element) => element.id == tab.refId)
                .firstOrNull
                ?.title ??
            'elements.new'.tr(),
        Feather.user,
      ),
    };
    return PlotcraftTabData(
      id: tab.id,
      title: title,
      icon: icon,
      dirty: controller.isDirty(tab.id),
    );
  }

  Future<void> _openTabMenu(
    BuildContext context,
    String id,
    Offset position,
  ) async {
    final choice = await showPlotcraftContextMenu<_TabMenu>(context, position, [
      PopupMenuItem(
        value: _TabMenu.close,
        child: Text('workspace.close_tab'.tr()),
      ),
      PopupMenuItem(
        value: _TabMenu.closeOthers,
        child: Text('workspace.close_others'.tr()),
      ),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case _TabMenu.close:
        await actions.closeTab(context, id);
      case _TabMenu.closeOthers:
        await actions.closeOtherTabs(context, id);
      case null:
        break;
    }
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Feather.book_open, size: 34, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'workspace.overview_intro'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          PlotcraftButton(
            label: 'workspace.overview'.tr(),
            variant: PlotcraftButtonVariant.secondary,
            onPressed: () => controller.openTab(WorkspaceTab.overview),
          ),
        ],
      ),
    );
  }

  Widget _loadError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('workspace.load_error'.tr()),
        const SizedBox(height: 12),
        PlotcraftButton(
          onPressed: controller.load,
          label: 'workspace.retry'.tr(),
          variant: PlotcraftButtonVariant.secondary,
        ),
      ],
    ),
  );
}
