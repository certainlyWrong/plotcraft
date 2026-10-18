import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:path/path.dart' as p;

import '../../projects/domain/project_format.dart';
import '../../projects/domain/project_metadata_input.dart';
import '../../projects/domain/story_project.dart';
import '../data/project_workspace_repository.dart';
import '../domain/book_content.dart';
import '../domain/element_relation.dart';
import '../domain/element_type.dart';
import '../domain/element_type_catalog.dart';
import '../domain/gallery_item.dart';
import '../domain/narrative_element.dart';
import '../domain/project_font.dart';
import '../domain/rich/delta_edit.dart';
import '../domain/rich/delta_to_markdown.dart';
import '../domain/rich/markdown_to_delta.dart';
import '../domain/rich/mention_scan.dart';
import '../domain/rich/rich_document.dart';
import 'content_revision.dart';
import 'story_error.dart';

/// A chapter in the list of the book.
class ChapterInfo {
  const ChapterInfo({
    required this.id,
    required this.title,
    required this.index,
    required this.words,
    required this.revision,
  });

  final String id;
  final String title;
  final int index;
  final int words;
  final String revision;
}

/// The content of one chapter and the revision to send back when writing.
class ChapterContent {
  const ChapterContent({
    required this.id,
    required this.title,
    required this.delta,
    required this.revision,
  });

  final String id;
  final String title;
  final Delta delta;
  final String revision;
}

/// One match of a text search in the manuscript.
class SearchMatch {
  const SearchMatch({
    required this.chapterId,
    required this.chapterTitle,
    required this.start,
    required this.end,
    required this.snippet,
  });

  final String chapterId;
  final String chapterTitle;
  final int start;
  final int end;
  final String snippet;
}

/// How many replacements a replace-all made (or would make) in a chapter.
class ReplaceOutcome {
  const ReplaceOutcome(this.chapterId, this.chapterTitle, this.count);

  final String chapterId;
  final String chapterTitle;
  final int count;
}

/// An element and the revision of its file.
class ElementRecord {
  const ElementRecord(this.element, this.revision);

  final NarrativeElement element;
  final String revision;
}

/// One story project as a set of operations, without any user interface:
/// what the MCP server calls. It reads the project folder on every call, so
/// it always sees the current files, and writes go through the same
/// repositories the app uses. Writes over existing content take the revision
/// the caller last saw and are refused if the file changed since.
class StoryWorkspace {
  StoryWorkspace._(this._project, this._repo);

  /// Opens the project of [folder] (it must hold a readable `project.json`).
  ///
  /// A book is always a list of chapters, as in the app: a project that still
  /// has a single manuscript gets it converted into [firstChapterTitle].
  static Future<StoryWorkspace> open(
    StoryProject project, {
    ProjectWorkspaceRepository? repository,
    String firstChapterTitle = 'Chapter 1',
  }) async {
    if (project.directoryPath == null) {
      throw const StoryError.validation('The project has no folder.');
    }
    final workspace = StoryWorkspace._(
      project,
      repository ?? ProjectWorkspaceRepository(),
    );
    if (ProjectFormats.of(project.primaryFormat).hasManuscript) {
      final book = await workspace.loadBook();
      if (!book.chaptersEnabled) {
        final result = await workspace._repo.book.setChapterMode(
          workspace._project,
          book,
          true,
          firstChapterTitle: firstChapterTitle,
        );
        workspace._project = result.project;
      }
    }
    return workspace;
  }

  StoryProject _project;
  final ProjectWorkspaceRepository _repo;

  StoryProject get project => _project;
  String get folder => _project.directoryPath!;

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  // --- Project ----------------------------------------------------------

  Future<StoryProject> updateMetadata(
    ProjectMetadataInput input, {
    bool removeCover = false,
  }) async {
    try {
      _project = await _repo.metadata.updateMetadata(
        _project,
        input,
        removeCover: removeCover,
      );
    } on FormatException catch (error) {
      throw StoryError.validation(error.message);
    }
    return _project;
  }

  // --- Manuscript -------------------------------------------------------

  Future<BookContent> loadBook() => _repo.book.load(_project);

  File _chapterFile(String id) =>
      File(p.join(folder, 'content', 'book', 'chapters', '$id.delta.json'));

  static int wordCount(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
  }

  Future<List<ChapterInfo>> chapters() async {
    final book = await loadBook();
    return [
      for (var i = 0; i < book.chapters.length; i++)
        ChapterInfo(
          id: book.chapters[i].id,
          title: book.chapters[i].title,
          index: i,
          words: wordCount(book.chapterTexts[book.chapters[i].id] ?? ''),
          revision: await ContentRevision.ofFile(
            _chapterFile(book.chapters[i].id),
          ),
        ),
    ];
  }

  BookChapter _chapter(BookContent book, String id) {
    final found = book.chapters.where((chapter) => chapter.id == id);
    if (found.isEmpty) {
      throw StoryError.notFound(
        'Chapter "$id"',
        hint: 'Call list_chapters to see the chapter ids.',
      );
    }
    return found.first;
  }

  Future<ChapterContent> readChapter(String id) async {
    final book = await loadBook();
    final chapter = _chapter(book, id);
    return ChapterContent(
      id: id,
      title: chapter.title,
      delta: book.deltaFor(id),
      revision: await ContentRevision.ofFile(_chapterFile(id)),
    );
  }

  Future<void> _requireRevision(
    String what,
    String? baseRevision,
    String current,
  ) async {
    if (baseRevision != null && baseRevision != current) {
      throw StoryError(
        StoryErrorCode.conflict,
        '$what changed since you read it (your revision $baseRevision, '
        'current $current).',
        hint: 'Read it again, apply your change to the new content and retry.',
      );
    }
  }

  /// Saves [delta] as the content of chapter [id]; returns the new revision.
  Future<String> writeChapter(
    String id,
    Delta delta, {
    String? baseRevision,
  }) async {
    final book = await loadBook();
    _chapter(book, id);
    await _requireRevision(
      'Chapter "$id"',
      baseRevision,
      await ContentRevision.ofFile(_chapterFile(id)),
    );
    final content = delta.isEmpty ? RichDocument.empty() : delta;
    final result = await _repo.book.saveBookDocument(
      _project,
      book,
      id,
      content,
    );
    _project = result.project;
    return ContentRevision.ofFile(_chapterFile(id));
  }

  /// Adds a chapter (at [position], or at the end) and returns its id.
  Future<String> addChapter(
    String title, {
    Delta? content,
    int? position,
  }) async {
    if (title.trim().isEmpty) {
      throw const StoryError.validation('A chapter needs a title.');
    }
    final book = await loadBook();
    final added = await _repo.book.addChapter(_project, book, title);
    _project = added.project;
    final id = added.book.chapters.last.id;
    var current = added.book;
    if (content != null && !content.isEmpty) {
      final saved = await _repo.book.saveBookDocument(
        _project,
        current,
        id,
        content,
      );
      _project = saved.project;
      current = saved.book;
    }
    if (position != null && position < current.chapters.length - 1) {
      final order = [...current.chapters]
        ..removeLast()
        ..insert(
          position.clamp(0, current.chapters.length - 1),
          current.chapters.last,
        );
      final moved = await _repo.book.updateChapters(_project, current, order);
      _project = moved.project;
    }
    return id;
  }

  Future<void> renameChapter(String id, String title) async {
    if (title.trim().isEmpty) {
      throw const StoryError.validation('A chapter needs a title.');
    }
    final book = await loadBook();
    _chapter(book, id);
    final result = await _repo.book.updateChapters(_project, book, [
      for (final chapter in book.chapters)
        chapter.id == id ? BookChapter(id: id, title: title.trim()) : chapter,
    ]);
    _project = result.project;
  }

  /// Puts the chapters in the order of [ids], which must list every chapter.
  Future<void> reorderChapters(List<String> ids) async {
    final book = await loadBook();
    final known = {for (final chapter in book.chapters) chapter.id: chapter};
    if (ids.length != known.length || ids.toSet().length != ids.length) {
      throw const StoryError.validation(
        'Send every chapter id exactly once.',
        hint: 'Call list_chapters to see the chapter ids.',
      );
    }
    for (final id in ids) {
      if (!known.containsKey(id)) throw StoryError.notFound('Chapter "$id"');
    }
    final result = await _repo.book.updateChapters(_project, book, [
      for (final id in ids) known[id]!,
    ]);
    _project = result.project;
  }

  /// Moves a chapter to the archive folder of the project (recoverable).
  Future<void> removeChapter(String id) async {
    final book = await loadBook();
    _chapter(book, id);
    if (book.chapters.length <= 1) {
      throw const StoryError.validation(
        'A book needs at least one chapter, so the last one cannot be removed.',
      );
    }
    final result = await _repo.book.removeChapter(_project, book, id);
    _project = result.project;
  }

  /// Gallery lookup for the Markdown codecs.
  Future<String? Function(String)?> _galleryIds() async {
    final byFile = {
      for (final item in await _repo.gallery.items(_project))
        item.file: item.id,
    };
    return byFile.isEmpty ? null : (file) => byFile[file];
  }

  Future<String> toMarkdown(Delta delta) async {
    final byId = {
      for (final item in await _repo.gallery.items(_project))
        item.id: item.file,
    };
    return DeltaToMarkdown(galleryFile: (id) => byId[id]).convert(delta);
  }

  Future<Delta> fromMarkdown(String markdown) async =>
      MarkdownToDelta(galleryId: await _galleryIds()).convert(markdown);

  /// Matches of [query] in every chapter (or in [chapterIds]).
  Future<List<SearchMatch>> search(
    String query, {
    bool regex = false,
    bool caseSensitive = false,
    List<String>? chapterIds,
    int context = 40,
    int limit = 200,
  }) async {
    if (regex) _checkRegex(query);
    final book = await loadBook();
    final matches = <SearchMatch>[];
    for (final chapter in book.chapters) {
      if (chapterIds != null && !chapterIds.contains(chapter.id)) continue;
      final delta = book.deltaFor(chapter.id);
      final plain = DeltaEdit.text(delta);
      for (final hit in DeltaEdit.find(
        delta,
        query,
        regex: regex,
        caseSensitive: caseSensitive,
      )) {
        matches.add(
          SearchMatch(
            chapterId: chapter.id,
            chapterTitle: chapter.title,
            start: hit.start,
            end: hit.end,
            snippet: DeltaEdit.snippet(plain, hit, context: context),
          ),
        );
        if (matches.length >= limit) return matches;
      }
    }
    return matches;
  }

  void _checkRegex(String pattern) {
    try {
      RegExp(pattern);
    } on FormatException catch (error) {
      throw StoryError.validation(
        'Invalid regular expression: ${error.message}',
      );
    }
  }

  /// Replaces [query] in the manuscript. With [dryRun] nothing is written and
  /// the result says what would change.
  Future<List<ReplaceOutcome>> replaceInManuscript(
    String query,
    String replacement, {
    bool dryRun = true,
    bool regex = false,
    bool caseSensitive = false,
    List<String>? chapterIds,
  }) async {
    if (query.isEmpty) {
      throw const StoryError.validation('The text to find cannot be empty.');
    }
    if (regex) _checkRegex(query);
    final book = await loadBook();
    final outcomes = <ReplaceOutcome>[];
    for (final chapter in book.chapters) {
      if (chapterIds != null && !chapterIds.contains(chapter.id)) continue;
      final (changed, count) = DeltaEdit.replaceAll(
        book.deltaFor(chapter.id),
        query,
        replacement,
        regex: regex,
        caseSensitive: caseSensitive,
      );
      if (count == 0) continue;
      outcomes.add(ReplaceOutcome(chapter.id, chapter.title, count));
      if (!dryRun) await writeChapter(chapter.id, changed);
    }
    return outcomes;
  }

  // --- Elements ---------------------------------------------------------

  File _elementFile(String id) =>
      File(p.join(folder, 'content', 'narrative', 'elements', '$id.json'));

  Future<List<ElementRecord>> elements() async {
    final data = await _repo.load(_project);
    return [
      for (final element in data.elements)
        ElementRecord(
          element,
          await ContentRevision.ofFile(_elementFile(element.id)),
        ),
    ];
  }

  Future<ElementRecord> element(String id) async {
    final all = await elements();
    final found = all.where((record) => record.element.id == id);
    if (found.isEmpty) {
      throw StoryError.notFound(
        'Element "$id"',
        hint: 'Call list_elements to see the element ids.',
      );
    }
    return found.first;
  }

  /// Saves [element] (new or changed) and returns the stored record. When
  /// [baseRevision] is given it must be the revision last read.
  Future<ElementRecord> saveElement(
    NarrativeElement element, {
    String? baseRevision,
  }) async {
    final data = await _repo.load(_project);
    final types = [...ElementTypeCatalog.builtin, ...data.types];
    if (!types.any((type) => type.id == element.typeId)) {
      throw StoryError.validation(
        'Unknown element type "${element.typeId}".',
        hint: 'Call list_element_types to see the available types.',
      );
    }
    final ids = {for (final other in data.elements) other.id};
    for (final relation in element.relations) {
      if (relation.targetId == element.id) {
        throw const StoryError.validation(
          'An element cannot relate to itself.',
        );
      }
      if (!ids.contains(relation.targetId)) {
        throw StoryError.notFound(
          'Related element "${relation.targetId}"',
          hint: 'Create the other element first, then add the relation.',
        );
      }
    }
    await _requireRevision(
      'Element "${element.id}"',
      baseRevision,
      await ContentRevision.ofFile(_elementFile(element.id)),
    );
    try {
      final (updated, saved) = await _repo.narrative.saveElement(
        _project,
        element,
      );
      _project = updated;
      return ElementRecord(
        saved,
        await ContentRevision.ofFile(_elementFile(saved.id)),
      );
    } on FormatException catch (error) {
      throw StoryError.validation(error.message);
    }
  }

  /// Archives the element and drops the relations other elements had to it.
  Future<void> removeElement(String id) async {
    final record = await element(id);
    final all = await elements();
    _project = await _repo.narrative.removeElement(_project, record.element.id);
    for (final other in all) {
      if (other.element.id == id) continue;
      if (other.element.relations.any((relation) => relation.targetId == id)) {
        final (updated, _) = await _repo.narrative.saveElement(
          _project,
          other.element.copyWith(
            relations: RelationIndex.prune(
              other.element,
              {for (final x in all) x.element.id}..remove(id),
            ),
          ),
        );
        _project = updated;
      }
    }
  }

  /// Where an element appears in the book.
  Future<List<MentionOccurrence>> referencesTo(String elementId) async {
    final record = await element(elementId);
    return scanElementMentions(await loadBook(), record.element, 'Manuscript');
  }

  // --- Types ------------------------------------------------------------

  Future<List<ElementType>> types() async => [
    ...ElementTypeCatalog.builtin,
    ...(await _repo.load(_project)).types,
  ];

  Future<ElementType> saveType(ElementType type) async {
    if (ElementTypeCatalog.builtinById(type.id) != null) {
      throw const StoryError.validation('Built-in types cannot be changed.');
    }
    final custom = (await _repo.load(_project)).types;
    final next = [
      for (final existing in custom)
        if (existing.id != type.id) existing,
      type,
    ];
    try {
      _project = await _repo.types.save(_project, next);
    } on FormatException catch (error) {
      throw StoryError.validation(error.message);
    }
    return type;
  }

  Future<void> removeType(String id) async {
    final data = await _repo.load(_project);
    if (!data.types.any((type) => type.id == id)) {
      throw StoryError.notFound('Custom element type "$id"');
    }
    final using = data.elements.where((element) => element.typeId == id);
    if (using.isNotEmpty) {
      throw StoryError.validation(
        '${using.length} element(s) still use this type.',
        hint: 'Change their type or remove them first.',
      );
    }
    _project = await _repo.types.save(_project, [
      for (final type in data.types)
        if (type.id != id) type,
    ]);
  }

  // --- Gallery ----------------------------------------------------------

  Future<List<GalleryItem>> gallery() => _repo.gallery.items(_project);

  Future<List<GalleryItem>> importImages(List<String> paths) async {
    try {
      final result = await _repo.gallery.importImages(_project, paths);
      _project = result.project;
      return result.items;
    } on FormatException catch (error) {
      throw StoryError.validation(
        error.message,
        hint: 'Use existing png, jpg, jpeg, webp or gif files.',
      );
    }
  }

  /// Saves image bytes (for example a generated picture) in the gallery under
  /// [fileName], without overwriting anything, and returns its item.
  Future<GalleryItem> importImageData(String fileName, Uint8List bytes) async {
    final safe = p.basename(fileName);
    if (safe.isEmpty || safe.startsWith('.')) {
      throw const StoryError.validation('Invalid file name.');
    }
    final temp = await Directory.systemTemp.createTemp('plotcraft-image-');
    try {
      final file = File(p.join(temp.path, safe));
      await file.writeAsBytes(bytes);
      final before = {for (final item in await gallery()) item.id};
      final items = await importImages([file.path]);
      return items.firstWhere(
        (item) => !before.contains(item.id),
        orElse: () => items.firstWhere((item) => item.file == safe),
      );
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// Deletes a gallery image for good.
  Future<void> removeGalleryImage(String id) async {
    final items = await gallery();
    final found = items.where((item) => item.id == id && item.exists);
    if (found.isEmpty) {
      throw StoryError.notFound(
        'Gallery image "$id"',
        hint: 'Call list_gallery to see the image ids.',
      );
    }
    final result = await _repo.gallery.removeImage(_project, found.first.path);
    _project = result.project;
  }

  // --- Fonts ------------------------------------------------------------

  Future<List<ProjectFont>> fonts() => _repo.fonts.list(_project);

  Future<List<ProjectFont>> addFonts(List<String> paths) =>
      _repo.fonts.add(_project, paths);

  Future<void> removeFont(String file) async {
    final fonts = await this.fonts();
    if (!fonts.any((font) => font.file == file)) {
      throw StoryError.notFound('Font file "$file"');
    }
    await _repo.fonts.remove(_project, file);
  }

  // --- Overview ---------------------------------------------------------

  Future<Map<String, Object?>> overview() async {
    final data = await _repo.load(_project);
    return {
      'words': data.book.wordCount,
      'chapters': data.book.chapters.length,
      'elements': data.elements.length,
      'images': data.galleryItems.where((item) => item.exists).length,
    };
  }
}
