import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/narrative_element.dart';
import 'project_files.dart';

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
    final file = File(
      p.join(folder, 'content', 'narrative', 'elements', '${element.id}.json'),
    );
    await file.parent.create(recursive: true);
    await _files.writeJson(file, element.toJson());
    return (await _files.touch(project), element);
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
    final file = File(
      p.join(folder, 'content', 'narrative', 'elements', '$elementId.json'),
    );
    if (await file.exists()) {
      final archive = File(
        p.join(folder, 'content', 'narrative', 'archive', '$elementId.json'),
      );
      await archive.parent.create(recursive: true);
      await file.rename(archive.path);
    }
    return _files.touch(project);
  }

  Future<List<NarrativeElement>> load(String folder) async {
    final directory = Directory(
      p.join(folder, 'content', 'narrative', 'elements'),
    );
    if (!await directory.exists()) return [];
    final elements = <NarrativeElement>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File || p.extension(entry.path) != '.json') continue;
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
