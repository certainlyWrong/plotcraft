import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/storage/local_storage.dart';
import '../../projects/domain/story_project.dart';
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
  });

  final StoryProject project;
  final ProjectWorkspaceStore store;
  final VoidCallback onBack;
  final LocalStorage? storage;

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
    );
    _actions = WorkspaceActions(_controller);
    windowManager.addListener(this);
    _controller.load();
  }

  @override
  void onWindowLeaveFullScreen() => _controller.toggleFullscreen(false);

  @override
  void dispose() {
    windowManager.removeListener(this);
    if (_controller.editorFullscreen) {
      windowManager.setFullScreen(false);
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
