import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/element_image.dart';
import '../domain/narrative_element.dart';
import 'project_files.dart';
import '../../../core/file_system.dart';

/// Narrative elements under `content/narrative/`.
class NarrativeRepository {
  const NarrativeRepository(this._files);

  final ProjectFiles _files;

  Future<(StoryProject, NarrativeElement)> saveElement(
    StoryProject project,
    NarrativeElement element,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(element.id) ||
        element.title.trim().isEmpty) {
      throw const FormatException('Invalid narrative element');
    }
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    final file = fs.file(
      p.join(folder, 'content', 'narrative', 'elements', '${element.id}.json'),
    );
    await file.parent.create(recursive: true);
    await _files.writeJson(file, element.toJson());
    await _pruneAttachments(folder, element);
    return (await _files.touch(project), element);
  }

  static const _attachmentExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  };
  static const _maxAttachmentBytes = 10 * 1024 * 1024;

  Directory _attachmentsDir(String folder, String elementId) => fs.directory(
    p.join(folder, 'content', 'narrative', 'attachments', elementId),
  );

  /// Copies an image from the computer into the element's own folder and
  /// returns the reference to store. Existing files are never overwritten.
  Future<ElementImage> attachImage(
    StoryProject project,
    String elementId,
    String sourcePath,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(elementId)) {
      throw const FormatException('Invalid narrative element ID');
    }
    final source = fs.file(sourcePath);
    final extension = p.extension(sourcePath).toLowerCase();
    if (!_attachmentExtensions.contains(extension) ||
        !await source.exists() ||
        await source.length() > _maxAttachmentBytes) {
      throw const FormatException('Invalid element image');
    }
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    final directory = _attachmentsDir(folder, elementId);
    await directory.create(recursive: true);
    final stem = p.basenameWithoutExtension(sourcePath);
    var destination = fs.file(p.join(directory.path, '$stem$extension'));
    var suffix = 2;
    while (await destination.exists()) {
      destination = fs.file(p.join(directory.path, '$stem-$suffix$extension'));
      suffix++;
    }
    await source.copy(destination.path);
    return ElementImage.attachment(
      p.posix.joinAll(p.split(p.relative(destination.path, from: folder))),
    );
  }

  /// Absolute path of an attachment, or null when [relativePath] does not
  /// point inside the narrative attachments folder.
  String? attachmentPath(StoryProject project, String relativePath) {
    final folder = _files.folder(project);
    final root = p.join(folder, 'content', 'narrative', 'attachments');
    final resolved = p.normalize(p.join(folder, relativePath));
    return p.isWithin(root, resolved) ? resolved : null;
  }

  /// Deletes files in the element's attachments folder that its images no
  /// longer reference (for example after the user removed an image).
  Future<void> _pruneAttachments(
    String folder,
    NarrativeElement element,
  ) async {
    final directory = _attachmentsDir(folder, element.id);
    if (!await directory.exists()) return;
    final keep = {
      for (final file in element.attachmentFiles)
        p.normalize(p.join(folder, file)),
    };
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is File && !keep.contains(p.normalize(entry.path))) {
        try {
          await entry.delete();
        } on FileSystemException {
          // An unused copy that cannot be deleted now is harmless.
        }
      }
    }
  }

  Future<StoryProject> removeElement(
    StoryProject project,
    String elementId,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(elementId)) {
      throw const FormatException('Invalid narrative element ID');
    }
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    final file = fs.file(
      p.join(folder, 'content', 'narrative', 'elements', '$elementId.json'),
    );
    if (await file.exists()) {
      final archive = fs.file(
        p.join(folder, 'content', 'narrative', 'archive', '$elementId.json'),
      );
      await archive.parent.create(recursive: true);
      await file.rename(archive.path);
    }
    return _files.touch(project);
  }

  Future<List<NarrativeElement>> load(String folder) async {
    final directory = fs.directory(
      p.join(folder, 'content', 'narrative', 'elements'),
    );
    if (!await directory.exists()) return [];
    final elements = <NarrativeElement>[];
    final entries = directory
        .list(followLinks: false)
        .where((entry) => entry is File)
        .cast<File>();
    await for (final entry in entries) {
      if (p.extension(entry.path) != '.json') continue;
      try {
        final json =
            jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
        elements.add(NarrativeElement.fromJson(json));
      } on FormatException {
        // A damaged optional element cannot prevent opening the book.
      } on TypeError {
        // Keep the source file for manual recovery.
      }
    }
    elements.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return elements;
  }
}
