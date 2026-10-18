import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:plotcraft_core/features/app_bridge/bridge_protocol.dart';

import '../features/project_workspace/stores/workspace_controller.dart';

/// What the app lets other parts (the MCP bridge) do on screen: change the
/// language, open a project, and reach the workspace that is open.
class AppCommands {
  /// Set by the app widget, which is the one that can change the locale.
  Future<void> Function(Locale locale)? setLocale;

  /// The language code in use (kept up to date by the app widget).
  String currentLanguage = 'en';

  /// The project the library should open (its id); cleared when handled.
  final openProjectRequest = ValueNotifier<String?>(null);

  String? _projectId;
  WorkspaceController? _controller;

  String? get activeProjectId => _projectId;
  WorkspaceController? get activeWorkspace => _controller;

  void workspaceOpened(String projectId, WorkspaceController controller) {
    _projectId = projectId;
    _controller = controller;
  }

  void workspaceClosed(WorkspaceController controller) {
    if (identical(_controller, controller)) {
      _projectId = null;
      _controller = null;
    }
  }

  /// Opens project [id] and waits until its workspace is ready (or [timeout]).
  Future<WorkspaceController?> openProject(
    String id, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (_projectId == id && _controller != null) return _controller;
    if (_controller != null && _controller!.dirtyTabs.isNotEmpty) {
      throw const BridgeError(
        'conflict',
        'Another project is open with unsaved changes; the author has to '
            'save or close it first.',
      );
    }
    openProjectRequest.value = id;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_projectId == id && _controller != null) return _controller;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }
}
