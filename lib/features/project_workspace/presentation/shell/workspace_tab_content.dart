import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/plotcraft_dialog.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../domain/workspace_tab.dart';
import '../../stores/workspace_controller.dart';
import '../elements/element_editor.dart';
import '../manuscript/book_editor.dart';
import '../widgets/gallery_page.dart';
import '../widgets/project_metadata_editor.dart';
import '../widgets/project_overview.dart';
import '../workspace_actions.dart';

/// Builds the editor-area widget for one open tab.
class WorkspaceTabContent extends StatelessWidget {
  const WorkspaceTabContent({
    super.key,
    required this.tab,
    required this.project,
    required this.controller,
    required this.actions,
  });

  final WorkspaceTab tab;
  final StoryProject project;
  final WorkspaceController controller;
  final WorkspaceActions actions;

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    switch (tab.kind) {
      case WorkspaceTabKind.overview:
        return ProjectOverview(
          project: project,
          manuscript: store.manuscript,
          images: store.galleryImages.toList(),
          wordCount: store.wordCount,
          elementCount: store.elements.length,
          chapterCount: store.book.chapters.length,
          isImporting: store.isImporting,
          onOpenManuscript: () => controller.openManuscript(
            store.book.chaptersEnabled ? store.book.chapters.first.id : null,
          ),
          onOpenGallery: () => controller.openTab(WorkspaceTab.gallery),
          onImportImages: () => actions.importImages(context),
        );
      case WorkspaceTabKind.settings:
        return _DiscardGuard(
          controller: controller,
          tabId: tab.id,
          child: ProjectMetadataEditor(
            project: project,
            saving: store.isUpdating,
            onSave: (input, removeCover) =>
                actions.saveMetadata(context, input, removeCover),
            onCancel: () => actions.closeTab(context, tab.id),
            onChanged: () => controller.setDirty(tab.id, true),
          ),
        );
      case WorkspaceTabKind.gallery:
        final images = store.galleryImages.toList();
        return GalleryPage(
          images: images,
          importing: store.isImporting,
          removingImage: store.isRemovingImage,
          onImport: () => actions.importImages(context),
          onRefresh: controller.load,
          onSelect: (index) => actions.showImageViewer(context, images, index),
          onRemove: (path) => actions.removeGalleryImage(context, path),
        );
      case WorkspaceTabKind.manuscript:
      case WorkspaceTabKind.chapter:
        final chapterId = tab.refId;
        final buffer = controller.bufferFor(chapterId);
        return BookEditor(
          key: ObjectKey(buffer),
          controller: buffer.controller,
          dirty: controller.isDirty(tab.id),
          saving: store.isSaving,
          fullscreen: controller.editorFullscreen,
          elements: store.elements.toList(),
          types: store.elementTypes,
          galleryItems: store.galleryItems.toList(),
          chapterOrder: [for (final chapter in store.book.chapters) chapter.id],
          chapterId: chapterId,
          attachmentPath: store.attachmentPath,
          reveal: controller.revealRequests[tab.id],
          onRevealed: () => controller.clearReveal(tab.id),
          fonts: controller.fonts.catalog,
          onManageFonts: () => actions.manageFonts(context),
          onIgnoreTerm: (element, term) =>
              actions.ignoreMentionTerm(context, element, term),
          onSave: () => actions.saveManuscript(context, chapterId),
          onToggleFullscreen: () => actions.toggleFullscreen(context),
          onOpenElement: actions.openElement,
        );
      case WorkspaceTabKind.element:
        return ElementEditor(
          key: ValueKey(tab.id),
          tab: tab,
          store: store,
          controller: controller,
          book: store.book,
          onRemove: (element) => actions.removeElement(context, element),
          onOpenReference: (chapterId, range) =>
              actions.openReference(chapterId, range),
          onOpenElement: actions.openElement,
        );
    }
  }
}

/// Asks for confirmation before a tab with unsaved form changes is closed.
class _DiscardGuard extends StatefulWidget {
  const _DiscardGuard({
    required this.controller,
    required this.tabId,
    required this.child,
  });

  final WorkspaceController controller;
  final String tabId;
  final Widget child;

  @override
  State<_DiscardGuard> createState() => _DiscardGuardState();
}

class _DiscardGuardState extends State<_DiscardGuard> {
  @override
  void initState() {
    super.initState();
    widget.controller.setGuard(widget.tabId, () async {
      if (!widget.controller.isDirty(widget.tabId)) return true;
      final discard = await showConfirmDialog(
        context,
        title: 'workspace.discard_title'.tr(),
        message: 'workspace.discard_message'.tr(),
        confirmLabel: 'workspace.discard'.tr(),
        destructive: true,
      );
      if (discard) widget.controller.setDirty(widget.tabId, false);
      return discard;
    });
  }

  @override
  void dispose() {
    widget.controller.setGuard(widget.tabId, null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
