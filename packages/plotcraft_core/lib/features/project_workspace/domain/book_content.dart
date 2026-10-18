import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'rich/rich_document.dart';

class BookChapter {
  const BookChapter({required this.id, required this.title});

  final String id;
  final String title;

  Map<String, Object?> toJson() => {'id': id, 'title': title};

  factory BookChapter.fromJson(Map<String, dynamic> json) =>
      BookChapter(id: json['id'] as String, title: json['title'] as String);
}

/// The manuscript in memory: one Delta for the single manuscript or one per
/// chapter. The Deltas are the source of truth; the plain-text views below
/// are for word counts, excerpts and searches.
class BookContent {
  BookContent({
    required this.chaptersEnabled,
    required this.singleDelta,
    required this.chapters,
    required this.chapterDeltas,
  });

  BookContent.empty()
    : chaptersEnabled = false,
      singleDelta = RichDocument.empty(),
      chapters = const [],
      chapterDeltas = const {};

  final bool chaptersEnabled;
  final Delta singleDelta;
  final List<BookChapter> chapters;
  final Map<String, Delta> chapterDeltas;

  Delta deltaFor(String? chapterId) => chapterId == null
      ? singleDelta
      : chapterDeltas[chapterId] ?? RichDocument.empty();

  static String _text(Delta delta) => RichDocument.plainText(delta, embed: '');

  late final String singleText = _text(singleDelta);

  late final Map<String, String> chapterTexts = {
    for (final entry in chapterDeltas.entries) entry.key: _text(entry.value),
  };

  String textFor(String? chapterId) =>
      chapterId == null ? singleText : chapterTexts[chapterId] ?? '';

  late final String combinedText = chaptersEnabled
      ? chapters.map((chapter) => chapterTexts[chapter.id] ?? '').join('\n\n')
      : singleText;

  late final int wordCount = () {
    final text = combinedText.trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }();

  BookContent withDelta(String? chapterId, Delta delta) => chapterId == null
      ? BookContent(
          chaptersEnabled: chaptersEnabled,
          singleDelta: delta,
          chapters: chapters,
          chapterDeltas: chapterDeltas,
        )
      : BookContent(
          chaptersEnabled: chaptersEnabled,
          singleDelta: singleDelta,
          chapters: chapters,
          chapterDeltas: {...chapterDeltas, chapterId: delta},
        );

  /// Where an element is mentioned: one entry per document that links to it.
  /// The chapter ID is null for the single manuscript.
  List<({String? chapterId, String title})> referencesTo(
    String elementId,
    String manuscriptTitle,
  ) {
    bool mentions(Delta delta) =>
        RichDocument.mentionedIds(delta).contains(elementId);
    if (chaptersEnabled) {
      return [
        for (final chapter in chapters)
          if (mentions(deltaFor(chapter.id)))
            (chapterId: chapter.id, title: chapter.title),
      ];
    }
    return mentions(singleDelta)
        ? [(chapterId: null, title: manuscriptTitle)]
        : const [];
  }

  Map<String, Object?> toIndexJson() => {
    'schemaVersion': 1,
    'mode': chaptersEnabled ? 'chapters' : 'single',
    'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
  };
}
