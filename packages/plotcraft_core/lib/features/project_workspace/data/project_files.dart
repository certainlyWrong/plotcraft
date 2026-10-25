import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/time_id.dart';
import '../../projects/domain/story_project.dart';
import '../../../core/file_system.dart';

/// Low-level access to a project folder: the manifest and atomic writes.
/// Every workspace repository goes through it so the safety checks (known
/// folder, manifest belongs to the project) live in one place.
class ProjectFiles {
  const ProjectFiles();

  String folder(StoryProject project) {
    final path = project.directoryPath;
    if (path == null) throw StateError('Project folder is unknown');
    return path;
  }

  String newId() => newTimeId();

  Future<void> ensureManifest(StoryProject project) async {
    final file = fs.file(p.join(folder(project), 'project.json'));
    if (!await file.exists()) {
      throw FileSystemException('Project manifest is missing', file.path);
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['id'] != project.id) {
      throw StateError('Project manifest does not match the selected project');
    }
  }

  Future<void> writeManifest(StoryProject project) async {
    final file = fs.file(p.join(folder(project), 'project.json'));
    final temp = fs.file('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
    );
    await temp.rename(file.path);
  }

  /// Refreshes `updatedAt` in the manifest and returns the updated project.
  Future<StoryProject> touch(StoryProject project) async {
    final updated = project.copyWith();
    await writeManifest(updated);
    return updated;
  }

  Future<void> writeJson(File file, Map<String, Object?> value) async {
    await file.parent.create(recursive: true);
    final temp = fs.file('${file.path}.tmp');
    await temp.writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await temp.rename(file.path);
  }

  Future<void> writeText(File file, String value) async {
    await file.parent.create(recursive: true);
    final temp = fs.file('${file.path}.tmp');
    await temp.writeAsString(value);
    await temp.rename(file.path);
  }
}
