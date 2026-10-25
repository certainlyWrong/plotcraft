import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:path/path.dart' as p;

import '../../project_workspace/data/project_workspace_repository.dart';
import '../../project_workspace/services/story_error.dart';
import '../../projects/domain/story_project.dart';
import '../domain/export_book.dart';
import '../domain/export_options.dart';
import 'delta_blocks.dart';
import '../../../core/file_system.dart';

/// Reads a project from disk and builds the [ExportBook] to write. It only
/// reads: a project with a single manuscript is exported as one chapter
/// without being converted.
class BookAssembler {
  BookAssembler({ProjectWorkspaceRepository? repository})
    : _repo = repository ?? ProjectWorkspaceRepository();

  final ProjectWorkspaceRepository _repo;

  static const _mimeByExtension = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
  };

  /// [deltaFor] replaces the text of a chapter (null for the single
  /// manuscript), for example with edits not saved yet.
  Future<ExportBook> assemble(
    StoryProject project,
    ExportOptions options, {
    Delta? Function(String? chapterId)? deltaFor,
  }) async {
    if (project.directoryPath == null) {
      throw const StoryError.validation('The project has no folder.');
    }
    final book = await _repo.book.load(project);
    final used = <String>{};
    final chapters = <ExportChapter>[];
    Delta deltaOf(String? id) => deltaFor?.call(id) ?? book.deltaFor(id);

    if (book.chaptersEnabled) {
      for (final chapter in book.chapters) {
        final chosen = options.chapterIds;
        if (chosen != null && !chosen.contains(chapter.id)) continue;
        chapters.add(
          ExportChapter(
            id: chapter.id,
            title: chapter.title,
            blocks: deltaToBlocks(deltaOf(chapter.id), used),
          ),
        );
      }
    } else {
      chapters.add(
        ExportChapter(
          id: 'manuscript',
          title: project.title,
          blocks: deltaToBlocks(deltaOf(null), used),
        ),
      );
    }
    if (chapters.isEmpty) {
      throw const StoryError.validation(
        'There are no chapters to export.',
        hint: 'Call list_chapters to see the chapter ids.',
      );
    }

    final images = <String, ExportImage>{};
    for (final item in await _repo.gallery.items(project)) {
      if (!used.contains(item.id) || !item.exists) continue;
      final mime = _mimeByExtension[p.extension(item.file).toLowerCase()];
      if (mime == null) continue;
      images[item.id] = ExportImage(
        id: item.id,
        fileName: item.file,
        mimeType: mime,
        bytes: await fs.file(item.path).readAsBytes(),
      );
    }

    return ExportBook(
      metadata: ExportMetadata(
        id: project.id,
        title: project.title,
        subtitle: project.subtitle,
        author: project.author,
        description: project.description,
        genre: project.genre,
        tags: project.tags,
      ),
      chapters: chapters,
      images: images,
      cover: options.includeCover ? await _cover(project) : null,
    );
  }

  Future<ExportImage?> _cover(StoryProject project) async {
    final relative = project.coverFile;
    if (relative == null || relative.isEmpty) return null;
    final file = fs.file(p.join(project.directoryPath!, relative));
    final mime = _mimeByExtension[p.extension(file.path).toLowerCase()];
    if (mime == null || !await file.exists()) return null;
    return ExportImage(
      id: 'cover',
      fileName: p.basename(file.path),
      mimeType: mime,
      bytes: await file.readAsBytes(),
    );
  }
}
