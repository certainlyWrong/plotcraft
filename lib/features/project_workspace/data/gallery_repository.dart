import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import 'project_files.dart';

class GalleryImportResult {
  const GalleryImportResult({required this.project, required this.images});

  final StoryProject project;
  final List<String> images;
}

/// Reference images under `gallery/`.
class GalleryRepository {
  const GalleryRepository(this._files);

  final ProjectFiles _files;

  /// Image files in `gallery/`, sorted by name.
  Future<List<String>> list(StoryProject project) async {
    final gallery = Directory(p.join(_files.folder(project), 'gallery'));
    final images = <String>[];
    if (await gallery.exists()) {
      await for (final entry in gallery.list(followLinks: false)) {
        if (entry is File && _isImage(entry.path)) images.add(entry.path);
      }
    }
    images.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
    return images;
  }

  Future<GalleryImportResult> importImages(
    StoryProject project,
    List<String> sourcePaths,
  ) async {
    await _files.ensureManifest(project);
    final gallery = Directory(p.join(_files.folder(project), 'gallery'));
    await gallery.create(recursive: true);
    final imported = <File>[];
    try {
      for (final path in sourcePaths) {
        final source = File(path);
        if (!_isImage(path) || !await source.exists()) {
          throw const FormatException('Invalid gallery image');
        }
        if (p.equals(p.dirname(source.absolute.path), gallery.absolute.path)) {
          continue;
        }
        final extension = p.extension(path).toLowerCase();
        final stem = p.basenameWithoutExtension(path);
        var destination = File(p.join(gallery.path, '$stem$extension'));
        var suffix = 2;
        while (await destination.exists()) {
          destination = File(p.join(gallery.path, '$stem-$suffix$extension'));
          suffix++;
        }
        imported.add(await source.copy(destination.path));
      }
      final updated = imported.isEmpty ? project : await _files.touch(project);
      final images = await list(updated);
      return GalleryImportResult(project: updated, images: images);
    } catch (_) {
      for (final file in imported) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
  }

  Future<GalleryImportResult> removeImage(
    StoryProject project,
    String imagePath,
  ) async {
    await _files.ensureManifest(project);
    final gallery = p.normalize(p.join(_files.folder(project), 'gallery'));
    final normalized = p.normalize(imagePath);
    if (!p.equals(p.dirname(normalized), gallery) || !_isImage(normalized)) {
      throw const FormatException('Invalid gallery image path');
    }
    final image = File(normalized);
    if (!await image.exists()) {
      throw FileSystemException('Gallery image is missing', normalized);
    }
    final staged = File(
      '${image.path}.${DateTime.now().microsecondsSinceEpoch}.removing',
    );
    await image.rename(staged.path);
    try {
      final updated = await _files.touch(project);
      final images = await list(updated);
      try {
        await staged.delete();
      } on FileSystemException {
        // The image is already hidden from the gallery.
      }
      return GalleryImportResult(project: updated, images: images);
    } catch (_) {
      if (await staged.exists()) await staged.rename(image.path);
      rethrow;
    }
  }

  bool _isImage(String path) => {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  }.contains(p.extension(path).toLowerCase());
}
