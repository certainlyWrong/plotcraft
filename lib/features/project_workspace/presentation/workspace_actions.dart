import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform/window_service.dart';
import '../../../core/theme/plotcraft_tokens.dart';
import '../../../core/ui/plotcraft_dialog.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../domain/book_content.dart';
import '../domain/narrative_element.dart';
import '../domain/workspace_tab.dart';
import '../stores/project_workspace_store.dart';
import '../stores/workspace_controller.dart';
import 'manuscript/chapter_dialogs.dart';
import '../domain/element_type.dart';
import 'elements/element_type_editor.dart';
import 'elements/element_type_picker.dart';
import 'manuscript/chapter_list.dart';
import 'manuscript/project_fonts_dialog.dart';
import 'shell/gallery_image_viewer_launcher.dart';

/// User-initiated workspace operations. Each one gathers what it needs from
/// the user (dialogs), asks the controller or store to act and reports
/// failures, so widgets stay free of that sequencing.
class WorkspaceActions {
  WorkspaceActions(this.controller);

  final WorkspaceController controller;

  ProjectWorkspaceStore get store => controller.store;

  void _snack(ScaffoldMessengerState messenger, String key) =>
      messenger.showSnackBar(SnackBar(content: Text(key.tr())));

  // --- Tabs ---------------------------------------------------------------

  Future<void> closeTab(BuildContext context, String tabId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await controller.canClose(tabId)) controller.closeTabNow(tabId);
    } catch (_) {
      _snack(messenger, 'workspace.save_error');
    }
  }

  Future<void> closeOtherTabs(BuildContext context, String keepId) async {
    for (final tab in [...controller.tabs]) {
      if (tab.id != keepId && context.mounted) await closeTab(context, tab.id);
    }
  }

  /// Leaves the project after every open document is saved or discarded.
  Future<bool> leave(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await controller.canCloseAll()) return false;
    } catch (_) {
      _snack(messenger, 'workspace.save_error');
      return false;
    }
    await exitFullscreen();
    return true;
  }

  // --- Manuscript ---------------------------------------------------------

  Future<void> saveManuscript(BuildContext context, String? chapterId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.saveBuffer(chapterId ?? 'single');
    } catch (_) {
      _snack(messenger, 'workspace.save_error');
    }
  }

  /// Saves pending text so a structural change starts from what is on disk.
  Future<bool> _settle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.isSaving || store.isBookUpdating) return false;
    try {
      return await controller.saveAllBuffers();
    } catch (_) {
      _snack(messenger, 'workspace.save_error');
      return false;
    }
  }

  Future<void> _bookOperation(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await operation();
      controller.syncWithBook();
    } catch (_) {
      _snack(messenger, 'book.operation_error');
    }
  }

  Future<void> toggleChapters(BuildContext context) async {
    if (!await _settle(context) || !context.mounted) return;
    final enabling = !store.book.chaptersEnabled;
    final confirmed = await showConfirmDialog(
      context,
      title: enabling ? 'book.enable_title'.tr() : 'book.disable_title'.tr(),
      message: enabling
          ? 'book.enable_message'.tr()
          : 'book.disable_message'.tr(),
      confirmLabel: 'book.convert'.tr(),
    );
    if (!confirmed || !context.mounted) return;
    await _bookOperation(context, () async {
      await store.setChapterMode(enabling);
      controller.openManuscript(enabling ? store.book.chapters.first.id : null);
    });
  }

  Future<void> addChapter(BuildContext context) async {
    if (!await _settle(context) || !context.mounted) return;
    final title = await promptChapterTitle(context);
    if (title == null || !context.mounted) return;
    await _bookOperation(context, () async {
      final id = await store.addChapter(title);
      if (id != null) controller.openManuscript(id);
    });
  }

  Future<void> chapterAction(
    BuildContext context,
    BookChapter chapter,
    ChapterAction action,
  ) async {
    switch (action) {
      case ChapterAction.rename:
        await _renameChapter(context, chapter);
      case ChapterAction.up:
        await _moveChapter(context, chapter, -1);
      case ChapterAction.down:
        await _moveChapter(context, chapter, 1);
      case ChapterAction.remove:
        await _removeChapter(context, chapter);
    }
  }

  Future<void> _renameChapter(BuildContext context, BookChapter chapter) async {
    if (!await _settle(context) || !context.mounted) return;
    final title = await promptChapterTitle(context, chapter.title);
    if (title == null || !context.mounted) return;
    await _bookOperation(
      context,
      () => store.updateChapters([
        for (final item in store.book.chapters)
          item.id == chapter.id ? BookChapter(id: item.id, title: title) : item,
      ]),
    );
  }

  Future<void> _moveChapter(
    BuildContext context,
    BookChapter chapter,
    int direction,
  ) async {
    if (!await _settle(context)) return;
    final chapters = [...store.book.chapters];
    final index = chapters.indexWhere((item) => item.id == chapter.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= chapters.length) return;
    chapters
      ..removeAt(index)
      ..insert(target, chapter);
    if (!context.mounted) return;
    await _bookOperation(context, () => store.updateChapters(chapters));
  }

  Future<void> _removeChapter(BuildContext context, BookChapter chapter) async {
    if (!await _settle(context) || !context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'book.remove_chapter'.tr(),
      message: 'book.remove_message'.tr(),
      confirmLabel: 'book.remove_chapter'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await _bookOperation(context, () async {
      await store.removeChapter(chapter.id);
      final open = controller.tabs.any((tab) => tab.isManuscript);
      if (!open) controller.openManuscript(store.book.chapters.first.id);
    });
  }

  // --- Elements -----------------------------------------------------------

  void openElement(String id) {
    exitFullscreen();
    controller.openTab(WorkspaceTab.element(id));
  }

  Future<void> removeElement(
    BuildContext context,
    NarrativeElement element,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'elements.remove_title'.tr(),
      message: 'elements.remove_message'.tr(),
      confirmLabel: 'elements.remove'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await store.removeElement(element.id);
      controller.closeTabNow(WorkspaceTab.element(element.id).id);
    } catch (_) {
      _snack(messenger, 'elements.remove_error');
    }
  }

  /// Asks which type of element to create and opens a new draft of it. The
  /// picker also leads to creating and editing custom types, then reopens.
  Future<void> newElement(BuildContext context) async {
    while (true) {
      if (!context.mounted) return;
      final choice = await showElementTypePicker(
        context,
        store.elementTypes,
        allowCreate: true,
      );
      if (choice == null || !context.mounted) return;
      if (choice == createElementTypeChoice) {
        final typeId = await _editElementType(context);
        if (typeId != null) {
          controller.newElementDraft(typeId);
          return;
        }
      } else if (choice.startsWith(editElementTypePrefix)) {
        final id = choice.substring(editElementTypePrefix.length);
        await _editElementType(
          context,
          current: store.customElementTypes
              .where((t) => t.id == id)
              .firstOrNull,
        );
      } else {
        controller.newElementDraft(choice);
        return;
      }
    }
  }

  /// Runs the type editor and stores its result. Returns the ID of a saved
  /// type, or null when cancelled, deleted or if saving failed.
  Future<String?> _editElementType(
    BuildContext context, {
    ElementType? current,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final usedBy = current == null
        ? 0
        : store.elements.where((e) => e.typeId == current.id).length;
    final result = await showElementTypeEditor(
      context,
      current: current,
      usedBy: usedBy,
    );
    try {
      switch (result) {
        case ElementTypeSaved(:final type):
          await store.saveElementType(type);
          return type.id;
        case ElementTypeDeleted(:final typeId):
          await store.removeElementType(typeId);
        case null:
          break;
      }
    } catch (_) {
      _snack(messenger, 'elements.save_error');
    }
    return null;
  }

  /// Opens the manuscript document that references an element.
  void openReference(String? chapterId) => controller.openManuscript(chapterId);

  /// Stops the automatic detection of [term] as a mention of [element].
  Future<void> ignoreMentionTerm(
    BuildContext context,
    NarrativeElement element,
    String term,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final policy = element.mentionPolicy;
      await store.saveElement(
        element.copyWith(
          mentionPolicy: policy.copyWith(
            ignoredTerms: [...policy.ignoredTerms, term],
          ),
        ),
      );
    } catch (_) {
      _snack(messenger, 'elements.save_error');
    }
  }

  Future<void> manageFonts(BuildContext context) => showProjectFontsDialog(
    context,
    fonts: controller.fonts,
    project: store.project ?? controller.initialProject,
  );

  // --- Gallery ------------------------------------------------------------

  Future<void> importImages(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.isImporting) return;
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'workspace.image_files'.tr(),
            extensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
          ),
        ],
      );
      if (files.isEmpty) return;
      await store.importImages(files.map((file) => file.path).toList());
    } catch (_) {
      _snack(messenger, 'workspace.import_error');
    }
  }

  Future<void> removeGalleryImage(BuildContext context, String path) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.isRemovingImage || store.isImporting) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'workspace.remove_image_title'.tr(),
      message: 'workspace.remove_image_message'.tr(
        namedArgs: {'name': p.basename(path)},
      ),
      confirmLabel: 'workspace.remove_image'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await store.removeImage(path);
    } catch (_) {
      _snack(messenger, 'workspace.remove_image_error');
    }
  }

  void showImageViewer(BuildContext context, List<String> images, int index) =>
      showGalleryViewer(
        context,
        images: images,
        initialIndex: index,
        barrierColor: context.tokens.imageScrim.withValues(alpha: .94),
      );

  // --- Project settings ---------------------------------------------------

  Future<void> saveMetadata(
    BuildContext context,
    ProjectMetadataInput input,
    bool removeCover,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.updateMetadata(input, removeCover: removeCover);
      controller.setDirty(WorkspaceTab.settings.id, false);
      controller.closeTabNow(WorkspaceTab.settings.id);
    } catch (_) {
      _snack(messenger, 'workspace.update_error');
    }
  }

  // --- Window -------------------------------------------------------------

  Future<void> toggleFullscreen(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final next = !controller.editorFullscreen;
    try {
      await WindowService.setFullScreen(next);
      controller.toggleFullscreen(next);
    } catch (_) {
      _snack(messenger, 'book.operation_error');
    }
  }

  Future<void> exitFullscreen() async {
    if (!controller.editorFullscreen) return;
    await WindowService.setFullScreen(false);
    controller.toggleFullscreen(false);
  }
}
