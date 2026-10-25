import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/cover_image_rules.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../../projects/domain/story_project.dart';
import 'project_files.dart';
import '../../../core/file_system.dart';

/// Project identity (title, tags, ...) and the cover image in `covers/`.
class ProjectMetadataRepository {
  const ProjectMetadataRepository(this._files);

  final ProjectFiles _files;

  Future<StoryProject> updateMetadata(
    StoryProject project,
    ProjectMetadataInput input, {
    required bool removeCover,
  }) async {
    input.validate();
    await _files.ensureManifest(project);
    final folder = _files.folder(project);
    File? newCover;
    try {
      if (input.coverSourcePath != null) {
        final source = fs.file(input.coverSourcePath!);
        final extension = CoverImageRules.extensionOf(source.path);
        if (!await CoverImageRules.isValid(source.path)) {
          throw const FormatException('Invalid cover image');
        }
        final covers = fs.directory(p.join(folder, 'covers'));
        await covers.create(recursive: true);
        newCover = fs.file(
          p.join(
            covers.path,
            'cover-${DateTime.now().microsecondsSinceEpoch}$extension',
          ),
        );
        await source.copy(newCover.path);
      }
      final updated = project.copyWith(
        title: input.title.trim(),
        subtitle: input.subtitle.trim(),
        author: input.author.trim(),
        description: input.description.trim(),
        genre: input.genre.trim(),
        tags: input.tags.map((tag) => tag.trim()).toList(),
        coverIndex: input.coverIndex,
        coverFile: newCover == null
            ? null
            : p.relative(newCover.path, from: folder),
        removeCover: removeCover && newCover == null,
      );
      await _files.writeManifest(updated);
      if ((removeCover || newCover != null) && project.coverFile != null) {
        final oldCover = fs.file(p.join(folder, project.coverFile!));
        try {
          if (p.isWithin(p.join(folder, 'covers'), oldCover.path) &&
              await oldCover.exists()) {
            await oldCover.delete();
          }
        } on FileSystemException {
          // The new manifest and cover are already saved.
        }
      }
      return updated;
    } catch (_) {
      if (newCover != null && await newCover.exists()) await newCover.delete();
      rethrow;
    }
  }
}
