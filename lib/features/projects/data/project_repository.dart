import 'dart:io';

import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../../core/storage/local_storage.dart';
import 'sample_project_installer.dart';

/// Owns the on-disk project format. The preference store only indexes folders.
class ProjectRepository {
  ProjectRepository(
    this._storage,
    this._creation, {
    SampleProjectInstaller? sample,
  }) : _sample = sample ?? SampleProjectInstaller();

  final LocalStorage _storage;
  final ProjectCreationService _creation;
  final SampleProjectInstaller _sample;
  static const _library = ProjectLibrary();
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
    final projects = await _library.discover(
      knownFolders: indexedPaths,
      root: await projectsRoot,
    );

    // Older versions kept the complete library in SharedPreferences.
    final legacy = <StoryProject>[];
    for (final record in _storage.loadLegacyProjects()) {
      try {
        legacy.add(StoryProject.fromJson(record));
      } on TypeError {
        // Skip records that do not match the project schema.
      } on FormatException {
        // Skip records that do not match the project schema.
      }
    }
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

  /// ID of the project bundled as an example.
  Future<String> sampleId() => _sample.sampleId();

  /// Puts the bundled example into the projects folder (once) and returns
  /// the library with it, together with the example itself.
  Future<(List<StoryProject>, StoryProject)> installSample() async {
    final folder = await _sample.install(await projectsRoot);
    final projects = await load();
    final sample = projects.firstWhere(
      (project) => p.equals(project.directoryPath!, folder),
    );
    return (projects, sample);
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
    await _library.delete(project);
    final paths = _storage.loadProjectDirectories()..remove(folder);
    await _storage.saveProjectDirectories(paths);
  }

  Future<void> _saveIndex(Set<String> paths) =>
      _storage.saveProjectDirectories(paths.toList());
}
