import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/story_project.dart';

/// Finds, reads and deletes project folders. It knows nothing about where the
/// list of folders is remembered: the app keeps it in its preferences, the
/// MCP server scans a root folder.
class ProjectLibrary {
  const ProjectLibrary();

  /// The project of [folder], or null when it has no readable `project.json`.
  Future<StoryProject?> read(String folder) async {
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

  /// Every project found in [knownFolders] and in the direct subfolders of
  /// [root]. A project that appears twice (same ID) is listed once; folders
  /// without a readable manifest are skipped.
  Future<List<StoryProject>> discover({
    Iterable<String> knownFolders = const [],
    String? root,
  }) async {
    final paths = <String>{...knownFolders};
    if (root != null) {
      final directory = Directory(root);
      if (await directory.exists()) {
        try {
          await for (final entity in directory.list(followLinks: false)) {
            if (entity is Directory) paths.add(entity.path);
          }
        } on FileSystemException {
          // The folder may be on an unplugged or inaccessible volume.
        }
      }
    }
    final projects = <StoryProject>[];
    for (final path in paths) {
      final project = await read(path);
      if (project != null && !projects.any((item) => item.id == project.id)) {
        projects.add(project);
      }
    }
    return projects;
  }

  /// Removes the folder of [project] with everything in it, after checking
  /// that the manifest on disk is really this project.
  Future<void> delete(StoryProject project) async {
    final folder = project.directoryPath;
    if (folder == null) throw StateError('Project folder is unknown');
    final existing = await read(folder);
    if (existing?.id != project.id) {
      throw StateError('Project manifest does not match the selected project');
    }
    await Directory(folder).delete(recursive: true);
  }
}
