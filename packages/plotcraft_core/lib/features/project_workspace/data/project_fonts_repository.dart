import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/fonts/font_file_info.dart';
import '../../projects/domain/story_project.dart';
import '../domain/project_font.dart';
import 'project_files.dart';

/// Fonts that belong to a project, kept in its `fonts/` folder so that they
/// travel with it when the folder is copied to another computer.
class ProjectFontsRepository {
  const ProjectFontsRepository(this._files);

  final ProjectFiles _files;

  static const extensions = {'.ttf', '.otf', '.ttc'};
  static const maxBytes = 30 * 1024 * 1024;

  Directory _directory(StoryProject project) =>
      Directory(p.join(_files.folder(project), 'fonts'));

  /// Valid font files in `fonts/`, sorted by family. Files that are not
  /// fonts are ignored.
  Future<List<ProjectFont>> list(StoryProject project) async {
    final directory = _directory(project);
    if (!await directory.exists()) return const [];
    final fonts = <ProjectFont>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File ||
          !extensions.contains(p.extension(entry.path).toLowerCase())) {
        continue;
      }
      final info = FontFileInfo.read(await entry.readAsBytes());
      if (info == null) continue;
      fonts.add(
        ProjectFont(
          file: p.basename(entry.path),
          family: info.family,
          style: info.style,
          path: entry.path,
        ),
      );
    }
    fonts.sort((a, b) {
      final byFamily = a.family.toLowerCase().compareTo(b.family.toLowerCase());
      return byFamily != 0 ? byFamily : a.file.compareTo(b.file);
    });
    return fonts;
  }

  /// Copies font files into the project. A file that is not a font, is too
  /// large or does not exist is skipped; the others are copied without
  /// overwriting anything. Returns what was added.
  Future<List<ProjectFont>> add(
    StoryProject project,
    List<String> sourcePaths,
  ) async {
    await _files.ensureManifest(project);
    final directory = _directory(project);
    final added = <ProjectFont>[];
    for (final path in sourcePaths) {
      final source = File(path);
      if (!extensions.contains(p.extension(path).toLowerCase()) ||
          !await source.exists() ||
          await source.length() > maxBytes) {
        continue;
      }
      final info = FontFileInfo.read(await source.readAsBytes());
      if (info == null) continue;
      await directory.create(recursive: true);
      final stem = p.basenameWithoutExtension(path);
      final extension = p.extension(path).toLowerCase();
      var destination = File(p.join(directory.path, '$stem$extension'));
      var suffix = 2;
      while (await destination.exists()) {
        destination = File(p.join(directory.path, '$stem-$suffix$extension'));
        suffix++;
      }
      await source.copy(destination.path);
      added.add(
        ProjectFont(
          file: p.basename(destination.path),
          family: info.family,
          style: info.style,
          path: destination.path,
        ),
      );
    }
    return added;
  }

  Future<void> remove(StoryProject project, String file) async {
    await _files.ensureManifest(project);
    final directory = _directory(project);
    final target = File(p.join(directory.path, p.basename(file)));
    if (p.basename(file) != file) {
      throw const FormatException('Invalid font file name');
    }
    if (await target.exists()) await target.delete();
  }
}
