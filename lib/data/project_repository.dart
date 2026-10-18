import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../features/project_creation/data/project_creation_service.dart';
import '../models/story_project.dart';
import 'local_storage.dart';

/// Owns the on-disk project format. The preference store only indexes folders.
class ProjectRepository {
  ProjectRepository(this._storage, this._creation);

  final LocalStorage _storage;
  final ProjectCreationService _creation;
  static const _folderAccess = MethodChannel('plotcraft/folder_access');

  late final Future<String> _defaultRoot = _resolveDefaultRoot();

  Future<String> _resolveDefaultRoot() async =>
      p.join((await getApplicationDocumentsDirectory()).path, 'Plotcraft');

  Future<String> get defaultRoot => _defaultRoot;

  Future<String> get projectsRoot async =>
      _storage.loadProjectsRoot() ?? await defaultRoot;

  Future<void> setProjectsRoot(String? path) async {
    if (path != null) {
      if (Platform.isMacOS) {
        throw StateError('Select macOS project folders with the native picker');
      }
      final directory = Directory(p.normalize(p.absolute(path)));
      if (!await directory.exists()) {
        throw FileSystemException('Directory does not exist', directory.path);
      }
      await _storage.saveProjectsRoot(directory.path);
    } else {
      await _storage.saveProjectsRoot(null);
    }
  }

  /// Returns false only when the user closes the picker without choosing.
  Future<bool> chooseProjectsRoot() async {
    String? path;
    String? bookmark;
    if (Platform.isMacOS) {
      final selection = await _folderAccess.invokeMapMethod<String, String>(
        'selectFolder',
        await projectsRoot,
      );
      if (selection == null) return false;
      path = selection['path'];
      bookmark = selection['bookmark'];
      if (path == null || bookmark == null) {
        throw const FormatException('Invalid folder selection');
      }
    } else {
      final current = await projectsRoot;
      path = await getDirectoryPath(
        initialDirectory: await Directory(current).exists()
            ? current
            : p.dirname(current),
        canCreateDirectories: true,
      );
      if (path == null) return false;
    }

    final directory = Directory(p.normalize(p.absolute(path)));
    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', directory.path);
    }
    if (bookmark != null) {
      final bookmarks = _storage.loadFolderBookmarks();
      bookmarks[directory.path] = bookmark;
      await _storage.saveFolderBookmarks(bookmarks);
    }
    await _storage.saveProjectsRoot(directory.path);
    return true;
  }

  Future<List<StoryProject>> load() async {
    if (Platform.isMacOS) {
      for (final bookmark in _storage.loadFolderBookmarks().values) {
        try {
          await _folderAccess.invokeMethod<String>(
            'activateBookmark',
            bookmark,
          );
        } on PlatformException {
          // Keep the indexed path so a temporarily unavailable volume can return.
        }
      }
    }
    final indexedPaths = _storage.loadProjectDirectories();
    final paths = <String>{...indexedPaths};
    final root = Directory(await projectsRoot);
    if (await root.exists()) {
      try {
        await for (final entity in root.list(followLinks: false)) {
          if (entity is Directory) paths.add(entity.path);
        }
      } on FileSystemException {
        // The selected folder may be on an unplugged or inaccessible volume.
      }
    }

    final projects = <StoryProject>[];
    for (final path in paths) {
      final project = await _read(path);
      if (project != null && !projects.any((item) => item.id == project.id)) {
        projects.add(project);
      }
    }

    // Older versions kept the complete library in SharedPreferences.
    final legacy = _storage.loadProjects();
    for (final project in legacy) {
      if (projects.any((item) => item.id == project.id)) continue;
      final migrated = await _creation.materialize(project, await projectsRoot);
      projects.add(migrated);
    }
    await _saveIndex({
      ...indexedPaths,
      ...projects.map((p) => p.directoryPath!),
    });
    if (legacy.isNotEmpty) await _storage.clearLegacyProjects();
    return projects;
  }

  Future<StoryProject?> _read(String folder) async {
    final file = File(p.join(folder, 'project.json'));
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return StoryProject.fromJson(json, directoryPath: folder);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> register(StoryProject project) async {
    final path = project.directoryPath;
    if (path == null) throw StateError('Project folder is unknown');
    final paths = {..._storage.loadProjectDirectories(), path};
    await _storage.saveProjectDirectories(paths.toList());
  }

  Future<void> delete(StoryProject project) async {
    final folder = project.directoryPath;
    if (folder == null) throw StateError('Project folder is unknown');
    final existing = await _read(folder);
    if (existing?.id != project.id) {
      throw StateError('Project manifest does not match the selected project');
    }
    await Directory(folder).delete(recursive: true);
    final paths = _storage.loadProjectDirectories()..remove(folder);
    await _storage.saveProjectDirectories(paths);
  }

  Future<void> _saveIndex(Set<String> paths) =>
      _storage.saveProjectDirectories(paths.toList());
}
