import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../models/story_project.dart';
import '../domain/project_creation_input.dart';

/// Builds the initial on-disk structure of a story project.
class ProjectCreationService {
  Future<StoryProject> create(ProjectCreationInput input, String root) async {
    input.validate();
    final coverSource = input.coverSourcePath == null
        ? null
        : File(input.coverSourcePath!);
    String? coverFile;
    if (coverSource != null) {
      final extension = p.extension(coverSource.path).toLowerCase();
      if (!{'.png', '.jpg', '.jpeg', '.webp'}.contains(extension) ||
          !await coverSource.exists() ||
          await coverSource.length() > 10 * 1024 * 1024) {
        throw const FormatException('Invalid cover image');
      }
      coverFile = 'covers/cover$extension';
    }

    final now = DateTime.now();
    final project = StoryProject(
      id: now.microsecondsSinceEpoch.toString(),
      title: input.title.trim(),
      subtitle: input.subtitle.trim(),
      author: input.author.trim(),
      description: input.description.trim(),
      genre: input.genre.trim(),
      tags: input.tags.map((tag) => tag.trim()).toList(),
      createdAt: now,
      updatedAt: now,
      coverIndex: input.coverIndex,
      coverFile: coverFile,
    );
    return materialize(project, root, coverSource: coverSource);
  }

  /// Uses the same folder format when migrating a legacy project record.
  Future<StoryProject> materialize(
    StoryProject project,
    String root, {
    File? coverSource,
  }) async {
    final rawSlug = project.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9à-öø-ÿ]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final slug = rawSlug.length > 48
        ? rawSlug.substring(0, 48).replaceAll(RegExp(r'-+$'), '')
        : rawSlug;
    final folder = p.join(
      root,
      '${slug.isEmpty ? 'story' : slug}-${project.id}',
    );
    final directory = Directory(folder);
    if (await directory.exists()) {
      final manifest = File(p.join(folder, 'project.json'));
      if (await manifest.exists()) {
        try {
          final json =
              jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
          final existing = StoryProject.fromJson(json, directoryPath: folder);
          if (existing.id == project.id) return existing;
        } on FormatException {
          // Keep the collision error below for an incomplete folder.
        } on TypeError {
          // Keep the collision error below for an invalid manifest.
        }
      }
      throw FileSystemException('Project folder already exists', folder);
    }

    await directory.create(recursive: true);
    try {
      await Directory(p.join(folder, 'covers')).create();
      await Directory(p.join(folder, 'gallery')).create();
      await Directory(p.join(folder, 'content', 'book'))
          .create(recursive: true);
      await Directory(p.join(folder, 'content', 'narrative', 'elements'))
          .create(recursive: true);
      await File(p.join(folder, 'content', 'book', 'manuscript.md'))
          .writeAsString('# ${project.title}\n\n');
      await File(p.join(folder, 'content', 'book', 'book.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 1,
          'mode': 'single',
          'chapters': <Object>[],
        }),
      );
      if (coverSource != null && project.coverFile != null) {
        await coverSource.copy(p.join(folder, project.coverFile!));
      }
      final manifest = File(p.join(folder, 'project.json'));
      final temp = File('${manifest.path}.tmp');
      await temp.writeAsString(
        const JsonEncoder.withIndent('  ').convert(project.toJson()),
      );
      await temp.rename(manifest.path);
      return StoryProject.fromJson(project.toJson(), directoryPath: folder);
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }
}
