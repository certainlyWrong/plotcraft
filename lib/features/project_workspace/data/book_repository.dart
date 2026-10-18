import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/book_content.dart';
import 'project_files.dart';

class BookWriteResult {
  const BookWriteResult(this.project, this.book);

  final StoryProject project;
  final BookContent book;
}

/// Manuscript and chapters under `content/book/`.
class BookRepository {
  const BookRepository(this._files);

  final ProjectFiles _files;

  Future<BookWriteResult> saveBookDocument(
    StoryProject project,
    BookContent book,
    String? chapterId,
    String content,
  ) async {
    final folder = _files.folder(project);
    await _files.ensureManifest(project);
    if (book.chaptersEnabled != (chapterId != null) ||
        (chapterId != null &&
            !book.chapters.any((chapter) => chapter.id == chapterId))) {
      throw const FormatException('Invalid book document');
    }
    final file = _bookFile(folder, chapterId);
    await file.parent.create(recursive: true);
    await _files.writeText(file, content);
    return BookWriteResult(
      await _files.touch(project),
      book.withText(chapterId, content),
    );
  }

  Future<BookWriteResult> setChapterMode(
    StoryProject project,
    BookContent book,
    bool enabled,
  ) async {
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
      final chapter = BookChapter(id: _files.newId(), title: project.title);
      final file = _bookFile(folder, chapter.id);
      await file.parent.create(recursive: true);
      await _files.writeText(file, book.singleText);
      next = BookContent(
        chaptersEnabled: true,
        singleText: book.singleText,
        chapters: [chapter],
        chapterTexts: {chapter.id: book.singleText},
      );
    } else {
      final combined = book.chapters
          .map((chapter) {
            final body = (book.chapterTexts[chapter.id] ?? '').trim();
            if (body.startsWith('# ${chapter.title}\n')) return body;
            return '# ${chapter.title}\n\n$body';
          })
          .join('\n\n');
      await _files.writeText(_bookFile(folder, null), '$combined\n');
      next = BookContent(
        chaptersEnabled: false,
        singleText: '$combined\n',
        chapters: book.chapters,
        chapterTexts: book.chapterTexts,
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
    final file = _bookFile(folder, chapter.id);
    await file.parent.create(recursive: true);
    await _files.writeText(file, '');
    final next = BookContent(
      chaptersEnabled: true,
      singleText: book.singleText,
      chapters: [...book.chapters, chapter],
      chapterTexts: {...book.chapterTexts, chapter.id: ''},
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
      singleText: book.singleText,
      chapters: chapters,
      chapterTexts: book.chapterTexts,
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
      singleText: book.singleText,
      chapters: book.chapters
          .where((chapter) => chapter.id != chapterId)
          .toList(),
      chapterTexts: {...book.chapterTexts}..remove(chapterId),
    );
    await _writeBookIndex(folder, next);
    final file = _bookFile(folder, chapterId);
    if (await file.exists()) {
      final archive = File(
        p.join(folder, 'content', 'book', 'archive', '$chapterId.md'),
      );
      try {
        await archive.parent.create(recursive: true);
        await file.rename(archive.path);
      } on FileSystemException {
        // The chapter is already absent from the active index; keep its file.
      }
    }
    return BookWriteResult(await _files.touch(project), next);
  }

  Future<BookContent> load(String folder) async {
    final manuscript = _bookFile(folder, null);
    final singleText = await manuscript.exists()
        ? await manuscript.readAsString()
        : '';
    final indexFile = File(p.join(folder, 'content', 'book', 'book.json'));
    if (!await indexFile.exists()) {
      return BookContent(
        chaptersEnabled: false,
        singleText: singleText,
        chapters: const [],
        chapterTexts: const {},
      );
    }
    final json =
        jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
    final chapters = (json['chapters'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BookChapter.fromJson)
        .toList();
    final texts = <String, String>{};
    for (final chapter in chapters) {
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(chapter.id)) {
        throw const FormatException('Invalid chapter ID');
      }
      final file = _bookFile(folder, chapter.id);
      texts[chapter.id] = await file.exists() ? await file.readAsString() : '';
    }
    return BookContent(
      chaptersEnabled: json['mode'] == 'chapters' && chapters.isNotEmpty,
      singleText: singleText,
      chapters: chapters,
      chapterTexts: texts,
    );
  }

  Future<void> _writeBookIndex(String folder, BookContent book) async {
    final file = File(p.join(folder, 'content', 'book', 'book.json'));
    await _files.writeJson(file, book.toIndexJson());
  }

  File _bookFile(String folder, String? chapterId) => File(
    chapterId == null
        ? p.join(folder, 'content', 'book', 'manuscript.md')
        : p.join(folder, 'content', 'book', 'chapters', '$chapterId.md'),
  );
}
