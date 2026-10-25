import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/gallery_item.dart';
import 'project_files.dart';
import '../../../core/file_system.dart';

class GalleryImportResult {
  const GalleryImportResult({
    required this.project,
    required this.images,
    required this.items,
  });

  final StoryProject project;

  /// Paths of the images that exist, sorted by name.
  final List<String> images;
  final List<GalleryItem> items;
}

/// Reference images under `gallery/`.
class GalleryRepository {
  const GalleryRepository(this._files);

  final ProjectFiles _files;

  /// Image files in `gallery/`, sorted by name.
  Future<List<String>> list(StoryProject project) async => [
    for (final item in await items(project))
      if (item.exists) item.path,
  ];

  /// Gallery images with their stable IDs, from `gallery/index.json`. Files
  /// that appeared in the folder get an ID; entries whose file disappeared
  /// are kept (marked missing) so references to them stay valid if the file
  /// comes back.
  Future<List<GalleryItem>> items(StoryProject project) async {
    final folder = _files.folder(project);
    final directory = fs.directory(p.join(folder, 'gallery'));
    final names = <String>{};
    if (await directory.exists()) {
      await for (final entry in directory.list(followLinks: false)) {
        if (entry is File && _isImage(entry.path)) {
          names.add(p.basename(entry.path));
        }
      }
    }
    final entries = await _readIndex(folder);
    final known = entries.map((entry) => entry.file).toSet();
    final usedIds = entries.map((entry) => entry.id).toSet();
    var changed = false;
    for (final name in names.toList()..sort()) {
      if (known.contains(name)) continue;
      var id = 'g_${_files.newId()}';
      var n = 2;
      while (!usedIds.add(id)) {
        id = 'g_${_files.newId()}_${n++}';
      }
      entries.add((id: id, file: name));
      changed = true;
    }
    if (changed) await _writeIndex(folder, entries);
    final items = [
      for (final entry in entries)
        GalleryItem(
          id: entry.id,
          file: entry.file,
          path: p.join(directory.path, entry.file),
          exists: names.contains(entry.file),
        ),
    ]..sort((a, b) => a.file.compareTo(b.file));
    return items;
  }

  File _indexFile(String folder) =>
      fs.file(p.join(folder, 'gallery', 'index.json'));

  Future<List<({String id, String file})>> _readIndex(String folder) async {
    final file = _indexFile(folder);
    if (!await file.exists()) return [];
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final seenIds = <String>{};
      final seenFiles = <String>{};
      return [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          if (item is Map &&
              item['id'] is String &&
              item['file'] is String &&
              seenIds.add(item['id'] as String) &&
              seenFiles.add(item['file'] as String))
            (id: item['id'] as String, file: item['file'] as String),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> _writeIndex(
    String folder,
    List<({String id, String file})> entries,
  ) => _files.writeJson(_indexFile(folder), {
    'schemaVersion': 1,
    'items': [
      for (final entry in entries) {'id': entry.id, 'file': entry.file},
    ],
  });

  Future<GalleryImportResult> importImages(
    StoryProject project,
    List<String> sourcePaths,
  ) async {
    await _files.ensureManifest(project);
    final gallery = fs.directory(p.join(_files.folder(project), 'gallery'));
    await gallery.create(recursive: true);
    final imported = <File>[];
    try {
      for (final path in sourcePaths) {
        final source = fs.file(path);
        if (!_isImage(path) || !await source.exists()) {
          throw const FormatException('Invalid gallery image');
        }
        if (p.equals(p.dirname(source.absolute.path), gallery.absolute.path)) {
          continue;
        }
        final extension = p.extension(path).toLowerCase();
        final stem = p.basenameWithoutExtension(path);
        var destination = fs.file(p.join(gallery.path, '$stem$extension'));
        var suffix = 2;
        while (await destination.exists()) {
          destination = fs.file(
            p.join(gallery.path, '$stem-$suffix$extension'),
          );
          suffix++;
        }
        imported.add(await source.copy(destination.path));
      }
      final updated = imported.isEmpty ? project : await _files.touch(project);
      final items = await this.items(updated);
      return GalleryImportResult(
        project: updated,
        images: [
          for (final item in items)
            if (item.exists) item.path,
        ],
        items: items,
      );
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
    final image = fs.file(normalized);
    if (!await image.exists()) {
      throw FileSystemException('Gallery image is missing', normalized);
    }
    final staged = fs.file(
      '${image.path}.${DateTime.now().microsecondsSinceEpoch}.removing',
    );
    await image.rename(staged.path);
    try {
      final updated = await _files.touch(project);
      final folder = _files.folder(project);
      final remaining = (await _readIndex(folder))
          .where((entry) => entry.file != p.basename(normalized))
          .toList();
      await _writeIndex(folder, remaining);
      final items = await this.items(updated);
      try {
        await staged.delete();
      } on FileSystemException {
        // The image is already hidden from the gallery.
      }
      return GalleryImportResult(
        project: updated,
        images: [
          for (final item in items)
            if (item.exists) item.path,
        ],
        items: items,
      );
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
