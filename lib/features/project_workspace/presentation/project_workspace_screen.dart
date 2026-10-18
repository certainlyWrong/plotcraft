import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import '../../projects/domain/story_project.dart';
import '../../../core/ui/plotcraft_button.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../stores/project_workspace_store.dart';
import '../domain/book_content.dart';
import '../domain/narrative_element.dart';
import 'widgets/book_editor.dart';
import 'widgets/narrative_workspace.dart';
import 'widgets/project_metadata_editor.dart';
import 'widgets/project_overview.dart';
import 'widgets/gallery_image_viewer.dart';
import 'widgets/gallery_mosaic.dart';
import 'widgets/workspace_inspector.dart';
import 'widgets/workspace_sidebar.dart';
import '../../../core/theme/plotcraft_tokens.dart';
import '../../../core/ui/plotcraft_dialog.dart';
import '../../../core/ui/plotcraft_text_field.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({
    super.key,
    required this.project,
    required this.store,
    required this.onBack,
  });

  final StoryProject project;
  final ProjectWorkspaceStore store;
  final VoidCallback onBack;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen>
    with WindowListener {
  final _manuscriptController = TextEditingController();
  final _narrativeKey = GlobalKey<NarrativeWorkspaceState>();
  Timer? _autosaveTimer;
  String? _selectedChapterId;
  String? _selectedElementId;
  bool _editorFullscreen = false;
  WorkspaceSection _section = WorkspaceSection.overview;
  bool _dirty = false;
  bool _loadFailed = false;
  bool _editingProject = false;
  bool _metadataDirty = false;
  bool _inspectorHidden = false;
  bool _inspectorOverlayOpen = false;
  double? _lastViewportWidth;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _load();
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted && _editorFullscreen) {
      setState(() => _editorFullscreen = false);
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_editorFullscreen;
    try {
      await windowManager.setFullScreen(next);
      if (mounted) setState(() => _editorFullscreen = next);
    } catch (_) {
      if (mounted) _showBookError();
    }
  }

  Future<void> _exitEditorFullscreen() async {
    if (!_editorFullscreen) return;
    await windowManager.setFullScreen(false);
    if (mounted) setState(() => _editorFullscreen = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    if (_lastViewportWidth != null && _lastViewportWidth != width) {
      _inspectorOverlayOpen = false;
    }
    _lastViewportWidth = width;
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      await widget.store.load(widget.store.project ?? widget.project);
      if (mounted) {
        final book = widget.store.book;
        _selectedChapterId = book.chaptersEnabled
            ? book.chapters.any((chapter) => chapter.id == _selectedChapterId)
                  ? _selectedChapterId
                  : book.chapters.firstOrNull?.id
            : null;
        _manuscriptController.text = book.textFor(_selectedChapterId);
        setState(() => _dirty = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    if (_editorFullscreen) unawaited(windowManager.setFullScreen(false));
    _autosaveTimer?.cancel();
    _manuscriptController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (!_dirty) return true;
    if (widget.store.isSaving) return false;
    _autosaveTimer?.cancel();
    final chapterId = _selectedChapterId;
    final text = _manuscriptController.text;
    try {
      await widget.store.saveBookDocument(chapterId, text);
      if (mounted) {
        final current =
            chapterId == _selectedChapterId &&
            text == _manuscriptController.text;
        setState(() => _dirty = !current);
        if (!current) _scheduleAutosave();
        return current;
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('workspace.save_error'.tr())));
      }
      return false;
    }
  }

  Future<void> _back() async {
    if (_section == WorkspaceSection.elements &&
        !await (_narrativeKey.currentState?.confirmLeave() ??
            Future.value(true))) {
      return;
    }
    if (!await _leaveEditor()) return;
    if (await _save() && mounted) {
      await _exitEditorFullscreen();
      if (mounted) widget.onBack();
    }
  }

  Future<void> _selectSection(WorkspaceSection section) async {
    if (_section == WorkspaceSection.elements &&
        section != _section &&
        !await (_narrativeKey.currentState?.confirmLeave() ??
            Future.value(true))) {
      return;
    }
    if (!await _leaveEditor()) return;
    if (section == _section) return;
    if (_section == WorkspaceSection.manuscript && !await _save()) return;
    if (_editorFullscreen) await _exitEditorFullscreen();
    if (mounted) {
      setState(() {
        _section = section;
        _editorFullscreen = false;
      });
    }
  }

  void _onBookChanged() {
    setState(() => _dirty = true);
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _dirty && !widget.store.isSaving) _save();
    });
  }

  Future<bool> _saveBeforeBookChange() async {
    if (widget.store.isSaving || widget.store.isBookUpdating) return false;
    return _save();
  }

  Future<void> _selectChapter(String id) async {
    if (_selectedChapterId == id || !await _saveBeforeBookChange()) return;
    if (!mounted) return;
    setState(() {
      _selectedChapterId = id;
      _manuscriptController.text = widget.store.book.textFor(id);
      _dirty = false;
    });
  }

  Future<void> _toggleChapters() async {
    if (!await _saveBeforeBookChange() || !mounted) return;
    final enabling = !widget.store.book.chaptersEnabled;
    final confirmed = await showConfirmDialog(
      context,
      title: enabling ? 'book.enable_title'.tr() : 'book.disable_title'.tr(),
      message: enabling
          ? 'book.enable_message'.tr()
          : 'book.disable_message'.tr(),
      confirmLabel: 'book.convert'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.setChapterMode(enabling);
      if (mounted) {
        setState(() {
          _selectedChapterId = enabling
              ? widget.store.book.chapters.first.id
              : null;
          _manuscriptController.text = widget.store.book.textFor(
            _selectedChapterId,
          );
          _dirty = false;
        });
      }
    } catch (_) {
      _showBookError();
    }
  }

  Future<String?> _chapterTitle([String? current]) async {
    final controller = TextEditingController(text: current ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PlotcraftDialog(
        title: current == null ? 'book.add_chapter'.tr() : 'book.rename'.tr(),
        content: PlotcraftTextField(
          controller: controller,
          autofocus: true,
          label: 'book.chapter_title'.tr(),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          PlotcraftButton(
            label: 'preferences.cancel'.tr(),
            variant: PlotcraftButtonVariant.text,
            onPressed: () => Navigator.pop(context),
          ),
          PlotcraftButton(
            label: 'workspace.save_project'.tr(),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
          ),
        ],
      ),
    );
    controller.dispose();
    return title;
  }

  Future<void> _addChapter() async {
    if (!await _saveBeforeBookChange() || !mounted) return;
    final title = await _chapterTitle();
    if (title == null || !mounted) return;
    try {
      final id = await widget.store.addChapter(title);
      if (id != null && mounted) {
        setState(() {
          _selectedChapterId = id;
          _manuscriptController.text = widget.store.book.textFor(id);
          _dirty = false;
        });
      }
    } catch (_) {
      _showBookError();
    }
  }

  Future<void> _renameChapter(BookChapter chapter) async {
    if (!await _saveBeforeBookChange() || !mounted) return;
    final title = await _chapterTitle(chapter.title);
    if (title == null || !mounted) return;
    try {
      await widget.store.updateChapters(
        widget.store.book.chapters
            .map(
              (item) => item.id == chapter.id
                  ? BookChapter(id: item.id, title: title)
                  : item,
            )
            .toList(),
      );
    } catch (_) {
      _showBookError();
    }
  }

  Future<void> _moveChapter(BookChapter chapter, int direction) async {
    if (!await _saveBeforeBookChange()) return;
    final chapters = [...widget.store.book.chapters];
    final index = chapters.indexWhere((item) => item.id == chapter.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= chapters.length) return;
    chapters.removeAt(index);
    chapters.insert(target, chapter);
    try {
      await widget.store.updateChapters(chapters);
    } catch (_) {
      _showBookError();
    }
  }

  Future<void> _removeChapter(BookChapter chapter) async {
    if (!await _saveBeforeBookChange() || !mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'book.remove_chapter'.tr(),
      message: 'book.remove_message'.tr(),
      confirmLabel: 'book.remove_chapter'.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.removeChapter(chapter.id);
      if (mounted && _selectedChapterId == chapter.id) {
        setState(() {
          _selectedChapterId = widget.store.book.chapters.first.id;
          _manuscriptController.text = widget.store.book.textFor(
            _selectedChapterId,
          );
          _dirty = false;
        });
      }
    } catch (_) {
      _showBookError();
    }
  }

  void _showBookError() {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('book.operation_error'.tr())));
    }
  }

  Future<void> _openElement(String id) async {
    if (!await _saveBeforeBookChange() || !mounted) return;
    if (_editorFullscreen) await _exitEditorFullscreen();
    if (!mounted) return;
    setState(() {
      _selectedElementId = id;
      _section = WorkspaceSection.elements;
      _editorFullscreen = false;
    });
  }

  Future<void> _openReference(String? chapterId) async {
    if (!await (_narrativeKey.currentState?.confirmLeave() ??
            Future.value(true)) ||
        !mounted) {
      return;
    }
    setState(() {
      _selectedChapterId = chapterId;
      _manuscriptController.text = widget.store.book.textFor(chapterId);
      _section = WorkspaceSection.manuscript;
      _dirty = false;
    });
  }

  Future<bool> _leaveEditor() async {
    if (!_editingProject) return true;
    if (widget.store.isUpdating) return false;
    if (_metadataDirty) {
      final discard = await showConfirmDialog(
        context,
        title: 'workspace.discard_title'.tr(),
        message: 'workspace.discard_message'.tr(),
        confirmLabel: 'workspace.discard'.tr(),
        destructive: true,
      );
      if (!discard) return false;
    }
    if (mounted) {
      setState(() {
        _editingProject = false;
        _metadataDirty = false;
      });
    }
    return true;
  }

  Future<void> _importImages() async {
    if (widget.store.isImporting) return;
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'workspace.image_files'.tr(),
            extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
          ),
        ],
      );
      if (files.isEmpty) return;
      await widget.store.importImages(files.map((file) => file.path).toList());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('workspace.import_error'.tr())));
      }
    }
  }

  Future<void> _saveProjectMetadata(
    ProjectMetadataInput input,
    bool removeCover,
  ) async {
    try {
      await widget.store.updateMetadata(input, removeCover: removeCover);
      if (mounted) {
        setState(() {
          _editingProject = false;
          _metadataDirty = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('workspace.update_error'.tr())));
      }
    }
  }

  Future<void> _removeGalleryImage(String imagePath) async {
    if (widget.store.isRemovingImage || widget.store.isImporting) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'workspace.remove_image_title'.tr(),
      message: 'workspace.remove_image_message'.tr(
        namedArgs: {'name': p.basename(imagePath)},
      ),
      confirmLabel: 'workspace.remove_image'.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.removeImage(imagePath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('workspace.remove_image_error'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final project = widget.store.project ?? widget.project;
      final loading = widget.store.isLoading;
      final saving = widget.store.isSaving;
      final manuscript = widget.store.manuscript;
      final images = widget.store.galleryImages.toList();
      final words = widget.store.wordCount;
      final importing = widget.store.isImporting;
      final updating = widget.store.isUpdating;
      final removingImage = widget.store.isRemovingImage;
      final book = widget.store.book;
      final elements = widget.store.elements.toList();
      final bookBusy = widget.store.isBookUpdating;

      if (_editorFullscreen &&
          _section == WorkspaceSection.manuscript &&
          !loading &&
          !_loadFailed &&
          !_editingProject) {
        return Scaffold(
          body: SafeArea(child: _bookEditor(book, elements, saving, bookBusy)),
        );
      }

      return LayoutBuilder(
        builder: (context, viewport) {
          final compactNavigation = viewport.maxWidth < 1200;
          final mainWidth =
              viewport.maxWidth - (compactNavigation ? 72.0 : 236.0);
          final galleryFocused = _section == WorkspaceSection.gallery;
          final inlineInspector =
              !galleryFocused && mainWidth >= 1100 && !_inspectorHidden;
          final overlayInspector =
              !galleryFocused && mainWidth < 1100 && _inspectorOverlayOpen;
          final content = loading
              ? const Center(child: CircularProgressIndicator())
              : _loadFailed
              ? _loadError(context)
              : _editingProject
              ? ProjectMetadataEditor(
                  project: project,
                  saving: updating,
                  onSave: _saveProjectMetadata,
                  onCancel: () => _selectSection(WorkspaceSection.overview),
                  onChanged: () => _metadataDirty = true,
                )
              : switch (_section) {
                  WorkspaceSection.overview => ProjectOverview(
                    project: project,
                    manuscript: manuscript,
                    images: images,
                    wordCount: words,
                    isImporting: importing,
                    onOpenManuscript: () =>
                        _selectSection(WorkspaceSection.manuscript),
                    onOpenGallery: () =>
                        _selectSection(WorkspaceSection.gallery),
                    onImportImages: _importImages,
                  ),
                  WorkspaceSection.manuscript => _bookEditor(
                    book,
                    elements,
                    saving,
                    bookBusy,
                  ),
                  WorkspaceSection.elements => NarrativeWorkspace(
                    key: _narrativeKey,
                    store: widget.store,
                    book: book,
                    initialElementId: _selectedElementId,
                    onOpenReference: _openReference,
                  ),
                  WorkspaceSection.gallery => _galleryPage(
                    context,
                    images,
                    importing,
                    removingImage,
                  ),
                };

          void toggleInspector() {
            setState(() {
              if (mainWidth >= 1100) {
                _inspectorHidden = !_inspectorHidden;
              } else {
                _inspectorOverlayOpen = !_inspectorOverlayOpen;
              }
            });
          }

          final inspector = WorkspaceInspector(
            project: project,
            section: _section,
            wordCount: words,
            imageCount: images.length,
            onEditProject: () => setState(() {
              _metadataDirty = false;
              _editingProject = true;
              _inspectorOverlayOpen = false;
            }),
            onClose: toggleInspector,
            overlay: overlayInspector,
          );

          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  WorkspaceSidebar(
                    project: project,
                    compact: compactNavigation,
                    selected: _section,
                    onSelect: _selectSection,
                    onBack: _back,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _topBar(
                                    context,
                                    project,
                                    saving: saving,
                                    inspectorOpen:
                                        inlineInspector || overlayInspector,
                                    onToggleInspector: toggleInspector,
                                    showInspectorToggle: !galleryFocused,
                                  ),
                                  Expanded(child: content),
                                ],
                              ),
                            ),
                            if (inlineInspector) inspector,
                          ],
                        ),
                        if (overlayInspector) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: toggleInspector,
                              child: const ColoredBox(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 66,
                            right: 0,
                            bottom: 0,
                            child: inspector,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Widget _topBar(
    BuildContext context,
    StoryProject project, {
    required bool saving,
    required bool inspectorOpen,
    required VoidCallback onToggleInspector,
    required bool showInspectorToggle,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'workspace.eyebrow'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${project.title}  /  ${_sectionName.tr()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_section == WorkspaceSection.manuscript && (_dirty || saving))
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                saving ? 'workspace.saving'.tr() : 'workspace.unsaved'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: saving
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (showInspectorToggle)
            IconButton(
              tooltip:
                  (inspectorOpen
                          ? 'workspace.close_inspector'
                          : 'workspace.open_inspector')
                      .tr(),
              onPressed: onToggleInspector,
              isSelected: inspectorOpen,
              icon: const Icon(Feather.sidebar, size: 19),
              selectedIcon: const Icon(Feather.sidebar, size: 19),
            ),
        ],
      ),
    );
  }

  String get _sectionName => switch (_section) {
    WorkspaceSection.overview => 'workspace.overview',
    WorkspaceSection.manuscript => 'workspace.manuscript',
    WorkspaceSection.elements => 'elements.title',
    WorkspaceSection.gallery => 'workspace.gallery',
  };

  Widget _loadError(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('workspace.load_error'.tr()),
        const SizedBox(height: 12),
        PlotcraftButton(
          onPressed: _load,
          label: 'workspace.retry'.tr(),
          variant: PlotcraftButtonVariant.secondary,
        ),
      ],
    ),
  );

  Widget _bookEditor(
    BookContent book,
    List<NarrativeElement> elements,
    bool saving,
    bool busy,
  ) => BookEditor(
    key: ValueKey(_selectedChapterId ?? 'single'),
    book: book,
    projectFolder: (widget.store.project ?? widget.project).directoryPath ?? '',
    chapterId: _selectedChapterId,
    controller: _manuscriptController,
    elements: elements,
    dirty: _dirty,
    saving: saving,
    busy: busy,
    fullscreen: _editorFullscreen,
    onChanged: _onBookChanged,
    onSave: _save,
    onToggleFullscreen: _toggleFullscreen,
    onToggleChapters: _toggleChapters,
    onSelectChapter: _selectChapter,
    onAddChapter: _addChapter,
    onRenameChapter: _renameChapter,
    onMoveChapter: _moveChapter,
    onRemoveChapter: _removeChapter,
    onOpenElement: _openElement,
  );

  Widget _galleryPage(
    BuildContext context,
    List<String> images,
    bool importing,
    bool removingImage,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (importing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'workspace.add_images'.tr(),
                    onPressed: _importImages,
                    icon: const Icon(Feather.plus),
                  ),
                IconButton(
                  tooltip: 'workspace.refresh_gallery'.tr(),
                  onPressed: importing ? null : _load,
                  icon: const Icon(Feather.refresh_cw),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: images.isEmpty
              ? Center(
                  child: IconButton(
                    tooltip: 'workspace.add_images'.tr(),
                    onPressed: importing ? null : _importImages,
                    iconSize: 34,
                    icon: Icon(
                      Feather.plus,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GalleryMosaic(
                  images: images,
                  removingImage: removingImage,
                  importing: importing,
                  onSelect: (index) => _showImageViewer(images, index),
                  onRemove: _removeGalleryImage,
                ),
        ),
      ],
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: context.tokens.imageScrim.withValues(alpha: .94),
      builder: (_) =>
          GalleryImageViewer(images: images, initialIndex: initialIndex),
    );
  }
}
