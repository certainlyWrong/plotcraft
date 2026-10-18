import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../domain/book_content.dart';
import '../domain/narrative_element.dart';
import '../../projects/domain/cover_image_rules.dart';

class ProjectWorkspaceData {
  const ProjectWorkspaceData({
    required this.book,
    required this.elements,
    required this.galleryImages,
  });

  final BookContent book;
  final List<NarrativeElement> elements;
  final List<String> galleryImages;
}

class BookWriteResult {
  const BookWriteResult(this.project, this.book);

  final StoryProject project;
  final BookContent book;
}

class GalleryImportResult {
  const GalleryImportResult({required this.project, required this.images});

  final StoryProject project;
  final List<String> images;
}

class ProjectWorkspaceRepository {
  Future<ProjectWorkspaceData> load(StoryProject project) async {
    final folder = _folder(project);
    await _ensureManifest(project);
    final gallery = Directory(p.join(folder, 'gallery'));
    final images = <String>[];
    if (await gallery.exists()) {
      await for (final entry in gallery.list(followLinks: false)) {
        if (entry is File && _isImage(entry.path)) images.add(entry.path);
      }
    }
    images.sort((a, b) => p.basename(a).compareTo(p.basename(b)));
    return ProjectWorkspaceData(
      book: await _loadBook(folder),
      elements: await _loadElements(folder),
      galleryImages: images,
    );
  }

  Future<BookWriteResult> saveBookDocument(
    StoryProject project,
    BookContent book,
    String? chapterId,
    String content,
  ) async {
    final folder = _folder(project);
    await _ensureManifest(project);
    if (book.chaptersEnabled != (chapterId != null) ||
        (chapterId != null &&
            !book.chapters.any((chapter) => chapter.id == chapterId))) {
      throw const FormatException('Invalid book document');
    }
    final file = _bookFile(folder, chapterId);
    await file.parent.create(recursive: true);
    await _writeText(file, content);
    return BookWriteResult(
      await _touch(project),
      book.withText(chapterId, content),
    );
  }

  Future<BookWriteResult> setChapterMode(
    StoryProject project,
    BookContent book,
    bool enabled,
  ) async {
    if (book.chaptersEnabled == enabled) return BookWriteResult(project, book);
    final folder = _folder(project);
    await _ensureManifest(project);
    late final BookContent next;
    if (enabled) {
      if (book.chapters.isNotEmpty) {
        final archive = File(
          p.join(folder, 'content', 'book', 'archive', 'book-${_newId()}.json'),
        );
        await _writeJson(archive, book.toIndexJson());
      }
      final chapter = BookChapter(id: _newId(), title: project.title);
      final file = _bookFile(folder, chapter.id);
      await file.parent.create(recursive: true);
      await _writeText(file, book.singleText);
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
      await _writeText(_bookFile(folder, null), '$combined\n');
      next = BookContent(
        chaptersEnabled: false,
        singleText: '$combined\n',
        chapters: book.chapters,
        chapterTexts: book.chapterTexts,
      );
    }
    await _writeBookIndex(folder, next);
    return BookWriteResult(await _touch(project), next);
  }

  Future<BookWriteResult> addChapter(
    StoryProject project,
    BookContent book,
    String title,
  ) async {
    if (!book.chaptersEnabled || title.trim().isEmpty) {
      throw const FormatException('Invalid chapter');
    }
    final folder = _folder(project);
    final chapter = BookChapter(id: _newId(), title: title.trim());
    final file = _bookFile(folder, chapter.id);
    await file.parent.create(recursive: true);
    await _writeText(file, '');
    final next = BookContent(
      chaptersEnabled: true,
      singleText: book.singleText,
      chapters: [...book.chapters, chapter],
      chapterTexts: {...book.chapterTexts, chapter.id: ''},
    );
    await _writeBookIndex(folder, next);
    return BookWriteResult(await _touch(project), next);
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
    await _writeBookIndex(_folder(project), next);
    return BookWriteResult(await _touch(project), next);
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
    final folder = _folder(project);
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
    return BookWriteResult(await _touch(project), next);
  }

  Future<(StoryProject, NarrativeElement)> saveElement(
    StoryProject project,
    NarrativeElement element,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(element.id) ||
        element.title.trim().isEmpty) {
      throw const FormatException('Invalid narrative element');
    }
    final folder = _folder(project);
    await _ensureManifest(project);
    final file = File(
      p.join(folder, 'content', 'narrative', 'elements', '${element.id}.json'),
    );
    await file.parent.create(recursive: true);
    await _writeJson(file, element.toJson());
    return (await _touch(project), element);
  }

  Future<StoryProject> removeElement(
    StoryProject project,
    String elementId,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(elementId)) {
      throw const FormatException('Invalid narrative element ID');
    }
    final folder = _folder(project);
    await _ensureManifest(project);
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
    return _touch(project);
  }

  Future<BookContent> _loadBook(String folder) async {
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

  Future<List<NarrativeElement>> _loadElements(String folder) async {
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

  Future<void> _writeBookIndex(String folder, BookContent book) async {
    final file = File(p.join(folder, 'content', 'book', 'book.json'));
    await _writeJson(file, book.toIndexJson());
  }

  Future<void> _writeJson(File file, Map<String, Object?> value) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(const JsonEncoder.withIndent('  ').convert(value));
    await temp.rename(file.path);
  }

  Future<void> _writeText(File file, String value) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(value);
    await temp.rename(file.path);
  }

  File _bookFile(String folder, String? chapterId) => File(
    chapterId == null
        ? p.join(folder, 'content', 'book', 'manuscript.md')
        : p.join(folder, 'content', 'book', 'chapters', '$chapterId.md'),
  );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<StoryProject> updateMetadata(
    StoryProject project,
    ProjectMetadataInput input, {
    required bool removeCover,
  }) async {
    input.validate();
    await _ensureManifest(project);
    final folder = _folder(project);
    File? newCover;
    try {
      if (input.coverSourcePath != null) {
        final source = File(input.coverSourcePath!);
        final extension = CoverImageRules.extensionOf(source.path);
        if (!await CoverImageRules.isValid(source.path)) {
          throw const FormatException('Invalid cover image');
        }
        final covers = Directory(p.join(folder, 'covers'));
        await covers.create(recursive: true);
        newCover = File(
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
      await _writeManifest(updated);
      if ((removeCover || newCover != null) && project.coverFile != null) {
        final oldCover = File(p.join(folder, project.coverFile!));
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

  Future<GalleryImportResult> importImages(
    StoryProject project,
    List<String> sourcePaths,
  ) async {
    await _ensureManifest(project);
    final gallery = Directory(p.join(_folder(project), 'gallery'));
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
      final updated = imported.isEmpty ? project : await _touch(project);
      final data = await load(updated);
      return GalleryImportResult(project: updated, images: data.galleryImages);
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
    await _ensureManifest(project);
    final gallery = p.normalize(p.join(_folder(project), 'gallery'));
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
      final updated = await _touch(project);
      final data = await load(updated);
      try {
        await staged.delete();
      } on FileSystemException {
        // The image is already hidden from the gallery.
      }
      return GalleryImportResult(project: updated, images: data.galleryImages);
    } catch (_) {
      if (await staged.exists()) await staged.rename(image.path);
      rethrow;
    }
  }

  Future<StoryProject> _touch(StoryProject project) async {
    final updated = project.copyWith();
    await _writeManifest(updated);
    return updated;
  }

  Future<void> _writeManifest(StoryProject project) async {
    final file = File(p.join(_folder(project), 'project.json'));
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
    );
    await temp.rename(file.path);
  }

  Future<void> _ensureManifest(StoryProject project) async {
    final file = File(p.join(_folder(project), 'project.json'));
    if (!await file.exists()) {
      throw FileSystemException('Project manifest is missing', file.path);
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['id'] != project.id) {
      throw StateError('Project manifest does not match the selected project');
    }
  }

  String _folder(StoryProject project) {
    final path = project.directoryPath;
    if (path == null) throw StateError('Project folder is unknown');
    return path;
  }

  bool _isImage(String path) => {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  }.contains(p.extension(path).toLowerCase());
}
