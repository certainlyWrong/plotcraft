import 'dart:convert';
import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/book_content.dart';
import '../domain/gallery_item.dart';
import '../domain/rich/chapter_merge.dart';
import '../domain/rich/delta_to_markdown.dart';
import '../domain/rich/markdown_to_delta.dart';
import '../domain/rich/rich_document.dart';
import 'project_files.dart';

class BookWriteResult {
  const BookWriteResult(this.project, this.book);

  final StoryProject project;
  final BookContent book;
}

/// Gallery images of a project, used to turn gallery IDs into file names in
/// the Markdown copy and back.
typedef GalleryLookup = Future<List<GalleryItem>> Function(
  StoryProject project,
);

/// Manuscript and chapters under `content/book/`.
///
/// Every document is saved as `<name>.delta.json`, the source of truth, plus a
/// readable `<name>.md` derived from it. Projects made before the rich editor
/// only have the `.md`; the first time one is opened it is converted to a
/// Delta, and the original is copied to `migration-backup/` first.
class BookRepository {
  const BookRepository(this._files, [this._gallery]);

  final ProjectFiles _files;
  final GalleryLookup? _gallery;

  static const _deltaVersion = RichDocument.fileVersion;

  // --- Saving ---------------------------------------------------------------

  Future<BookWriteResult> saveBookDocument(
    StoryProject project,
    BookContent book,
    String? chapterId,
    Delta content,
  ) async {
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    if (book.chaptersEnabled != (chapterId != null) ||
        (chapterId != null &&
            !book.chapters.any((chapter) => chapter.id == chapterId))) {
      throw const FormatException('Invalid book document');
    }
    await _writeDocument(project, folder, chapterId, content);
    return BookWriteResult(
      await _files.touch(project),
      book.withDelta(chapterId, content),
    );
  }

  /// Switches between one manuscript and chapters. [firstChapterTitle] names
  /// the chapter made from the manuscript; the project title is used when it
  /// is not given. A manuscript that only holds the project's title as a
  /// heading becomes an empty chapter.
  Future<BookWriteResult> setChapterMode(
    StoryProject project,
    BookContent book,
    bool enabled, {
    String? firstChapterTitle,
  }) async {
    if (book.chaptersEnabled == enabled) return BookWriteResult(project, book);
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    late final BookContent next;
    if (enabled) {
      if (book.chapters.isNotEmpty) {
        final archive = File(
          p.join(
            folder,
            'content',
            'book',
            'archive',
            'book-${_files.newId()}.json',
          ),
        );
        await _files.writeJson(archive, book.toIndexJson());
      }
      final chapter = BookChapter(
        id: _files.newId(),
        title: firstChapterTitle ?? project.title,
      );
      final onlyTitle =
          RichDocument.plainText(book.singleDelta).trim() ==
          project.title.trim();
      final content = onlyTitle ? RichDocument.empty() : book.singleDelta;
      await _writeDocument(project, folder, chapter.id, content);
      next = BookContent(
        chaptersEnabled: true,
        singleDelta: book.singleDelta,
        chapters: [chapter],
        chapterDeltas: {chapter.id: content},
      );
    } else {
      final combined = mergeChapters(book.chapters, book.deltaFor);
      await _writeDocument(project, folder, null, combined);
      next = BookContent(
        chaptersEnabled: false,
        singleDelta: combined,
        chapters: book.chapters,
        chapterDeltas: book.chapterDeltas,
      );
    }
    await _writeBookIndex(folder, next);
    return BookWriteResult(await _files.touch(project), next);
  }

  Future<BookWriteResult> addChapter(
    StoryProject project,
    BookContent book,
    String title,
  ) async {
    if (!book.chaptersEnabled || title.trim().isEmpty) {
      throw const FormatException('Invalid chapter');
    }
    final folder = _files.folder(project);
    final chapter = BookChapter(id: _files.newId(), title: title.trim());
    final empty = RichDocument.empty();
    await _writeDocument(project, folder, chapter.id, empty);
    final next = BookContent(
      chaptersEnabled: true,
      singleDelta: book.singleDelta,
      chapters: [...book.chapters, chapter],
      chapterDeltas: {...book.chapterDeltas, chapter.id: empty},
    );
    await _writeBookIndex(folder, next);
    return BookWriteResult(await _files.touch(project), next);
  }

  Future<BookWriteResult> updateChapters(
    StoryProject project,
    BookContent book,
    List<BookChapter> chapters,
  ) async {
    final currentIds = book.chapters.map((chapter) => chapter.id).toSet();
    final nextIds = chapters.map((chapter) => chapter.id).toSet();
    if (!book.chaptersEnabled ||
        chapters.length != book.chapters.length ||
        nextIds.length != chapters.length ||
        !nextIds.containsAll(currentIds) ||
        chapters.any((chapter) => chapter.title.trim().isEmpty)) {
      throw const FormatException('Invalid chapter index');
    }
    final next = BookContent(
      chaptersEnabled: true,
      singleDelta: book.singleDelta,
      chapters: chapters,
      chapterDeltas: book.chapterDeltas,
    );
    await _writeBookIndex(_files.folder(project), next);
    return BookWriteResult(await _files.touch(project), next);
  }

  Future<BookWriteResult> removeChapter(
    StoryProject project,
    BookContent book,
    String chapterId,
  ) async {
    if (!book.chaptersEnabled ||
        book.chapters.length <= 1 ||
        !book.chapters.any((chapter) => chapter.id == chapterId)) {
      throw const FormatException('Cannot remove chapter');
    }
    final folder = _files.folder(project);
    final next = BookContent(
      chaptersEnabled: true,
      singleDelta: book.singleDelta,
      chapters: book.chapters
          .where((chapter) => chapter.id != chapterId)
          .toList(),
      chapterDeltas: {...book.chapterDeltas}..remove(chapterId),
    );
    await _writeBookIndex(folder, next);
    // The chapter is already absent from the active index; if a file cannot be
    // moved it simply stays where it is.
    for (final file in [
      _deltaFile(folder, chapterId),
      _markdownFile(folder, chapterId),
    ]) {
      if (!await file.exists()) continue;
      final archive = File(
        p.join(folder, 'content', 'book', 'archive', p.basename(file.path)),
      );
      try {
        await archive.parent.create(recursive: true);
        await file.rename(archive.path);
      } on FileSystemException {
        // Keep the file.
      }
    }
    return BookWriteResult(await _files.touch(project), next);
  }

  // --- Loading --------------------------------------------------------------

  Future<BookContent> load(StoryProject project) async {
    final folder = _files.folder(project);
    final single = await _loadDocument(project, folder, null);
    final indexFile = File(p.join(folder, 'content', 'book', 'book.json'));
    if (!await indexFile.exists()) {
      return BookContent(
        chaptersEnabled: false,
        singleDelta: single,
        chapters: const [],
        chapterDeltas: const {},
      );
    }
    final json =
        jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BookChapter.fromJson)
        .toList();
    final deltas = <String, Delta>{};
    for (final chapter in chapters) {
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(chapter.id)) {
        throw const FormatException('Invalid chapter ID');
      }
      deltas[chapter.id] = await _loadDocument(project, folder, chapter.id);
    }
    return BookContent(
      chaptersEnabled: json['mode'] == 'chapters' && chapters.isNotEmpty,
      singleDelta: single,
      chapters: chapters,
      chapterDeltas: deltas,
    );
  }

  /// Reads one document: its Delta, or its Markdown converted (and backed up)
  /// when the Delta does not exist yet.
  Future<Delta> _loadDocument(
    StoryProject project,
    String folder,
    String? chapterId,
  ) async {
    final deltaFile = _deltaFile(folder, chapterId);
    final markdownFile = _markdownFile(folder, chapterId);
    if (await deltaFile.exists()) {
      try {
        final json =
            jsonDecode(await deltaFile.readAsString()) as Map<String, dynamic>;
        return RichDocument.fromOps(json['ops']);
      } on FormatException {
        // A damaged Delta must not hide a chapter whose Markdown still exists.
      } on TypeError {
        // Same: fall back to the Markdown copy below.
      }
      if (!await markdownFile.exists()) return RichDocument.empty();
    } else if (!await markdownFile.exists()) {
      return RichDocument.empty();
    }
    final source = await markdownFile.readAsString();
    final delta = MarkdownToDelta(
      galleryId: await _galleryIdLookup(project, source),
    ).convert(source);
    if (!await deltaFile.exists()) {
      await _migrate(folder, chapterId, markdownFile, deltaFile, delta);
    }
    return delta;
  }

  Future<void> _migrate(
    String folder,
    String? chapterId,
    File markdown,
    File delta,
    Delta converted,
  ) async {
    try {
      final backup = File(
        p.join(
          folder,
          'content',
          'book',
          'migration-backup',
          p.basename(markdown.path),
        ),
      );
      if (!await backup.exists()) {
        await backup.parent.create(recursive: true);
        await markdown.copy(backup.path);
      }
      await _files.writeJson(delta, _deltaJson(converted));
    } on FileSystemException {
      // A read-only project still opens; the conversion is repeated next time.
    }
  }

  Future<String? Function(String)?> _galleryIdLookup(
    StoryProject project,
    String markdown,
  ) async {
    if (_gallery == null || !markdown.contains('gallery/')) return null;
    final items = await _gallery(project);
    final byFile = {for (final item in items) item.file: item.id};
    return byFile.isEmpty ? null : (file) => byFile[file];
  }

  // --- Files ----------------------------------------------------------------

  Map<String, Object?> _deltaJson(Delta delta) => {
    'schemaVersion': _deltaVersion,
    'ops': delta.toJson(),
  };

  /// Writes the Delta and then its Markdown copy. If only the second write
  /// fails the Delta, which is what counts, is already safe.
  Future<void> _writeDocument(
    StoryProject project,
    String folder,
    String? chapterId,
    Delta delta,
  ) async {
    final deltaFile = _deltaFile(folder, chapterId);
    await deltaFile.parent.create(recursive: true);
    await _files.writeJson(deltaFile, _deltaJson(delta));
    String? Function(String)? fileOf;
    if (_gallery != null && RichDocument.galleryImageIds(delta).isNotEmpty) {
      final byId = {
        for (final item in await _gallery(project)) item.id: item.file,
      };
      fileOf = (id) => byId[id];
    }
    await _files.writeText(
      _markdownFile(folder, chapterId),
      DeltaToMarkdown(galleryFile: fileOf).convert(delta),
    );
  }

  Future<void> _writeBookIndex(String folder, BookContent book) async {
    final file = File(p.join(folder, 'content', 'book', 'book.json'));
    await _files.writeJson(file, book.toIndexJson());
  }

  File _markdownFile(String folder, String? chapterId) => File(
    chapterId == null
        ? p.join(folder, 'content', 'book', 'manuscript.md')
        : p.join(folder, 'content', 'book', 'chapters', '$chapterId.md'),
  );

  File _deltaFile(String folder, String? chapterId) => File(
    chapterId == null
        ? p.join(folder, 'content', 'book', 'manuscript.delta.json')
        : p.join(
            folder,
            'content',
            'book',
            'chapters',
            '$chapterId.delta.json',
          ),
  );
}
