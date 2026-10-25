import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/app_commands.dart';
import '../../../core/platform/window_service.dart';
import '../../../core/storage/local_storage.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../../core/fonts/project_font_loader.dart';
import '../../../core/fonts/system_fonts.dart';

import 'package:plotcraft_core/features/project_workspace/data/project_files.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_fonts_repository.dart';

import '../data/project_change_watcher.dart';
import '../stores/editor_fonts_store.dart';
import '../stores/project_workspace_store.dart';
import '../stores/workspace_controller.dart';
import 'shell/workspace_shell.dart';
import 'workspace_actions.dart';

/// Entry point of an open project. It owns the controller, loads the project
/// and hands the layout to [WorkspaceShell].
class ProjectWorkspaceScreen extends StatefulWidget {
  const ProjectWorkspaceScreen({
    super.key,
    required this.project,
    required this.store,
    required this.onBack,
    this.storage,
    this.commands,
  });

  final StoryProject project;
  final ProjectWorkspaceStore store;
  final VoidCallback onBack;
  final LocalStorage? storage;

  /// Lets other parts of the app reach this workspace (the MCP bridge).
  final AppCommands? commands;

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen>
    with WindowListener {
  late final WorkspaceController _controller;
  late final WorkspaceActions _actions;

  @override
  void initState() {
    super.initState();
    _controller = WorkspaceController(
      widget.store,
      widget.project,
      widget.storage,
      EditorFontsStore(
        const ProjectFontsRepository(ProjectFiles()),
        const ProjectFontLoader(),
        const PlatformSystemFontLister(),
      ),
    );
    _actions = WorkspaceActions(_controller);
    widget.commands?.workspaceOpened(widget.project.id, _controller);
    WindowService.addListener(this);
    _controller
        .load(firstChapterTitle: 'book.first_chapter'.tr())
        .then((_) => _startWatching());
  }

  ProjectChangeWatcher? _watcher;
  StreamSubscription<void>? _watching;
  bool _reloading = false;
  bool _reloadAgain = false;

  /// Starts noticing changes other programs (the MCP server for an AI) make
  /// to the project's files.
  void _startWatching() {
    final folder = widget.store.project?.directoryPath;
    if (!mounted || folder == null || _watcher != null) return;
    _watcher = ProjectChangeWatcher(folder)..start();
    _watching = _watcher!.changes.listen((_) => _reloadFromDisk());
  }

  Future<void> _reloadFromDisk() async {
    if (_reloading) {
      _reloadAgain = true;
      return;
    }
    _reloading = true;
    try {
      do {
        _reloadAgain = false;
        var done = await _controller.reloadFromDisk();
        // The store was busy (saving): wait for it and try again.
        for (var i = 0; !done && i < 10 && mounted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          done = await _controller.reloadFromDisk();
        }
      } while (_reloadAgain && mounted);
    } finally {
      _reloading = false;
    }
  }

  @override
  void onWindowLeaveFullScreen() => _controller.toggleFullscreen(false);

  @override
  void dispose() {
    widget.commands?.workspaceClosed(_controller);
    unawaited(_watching?.cancel());
    _watcher?.dispose();
    WindowService.removeListener(this);
    if (_controller.editorFullscreen) {
      WindowService.setFullScreen(false);
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (await _actions.leave(context) && mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) => WorkspaceShell(
    project: widget.store.project ?? widget.project,
    controller: _controller,
    actions: _actions,
    onBack: _back,
  );
}
