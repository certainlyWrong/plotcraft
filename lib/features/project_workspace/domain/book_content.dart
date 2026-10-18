class BookChapter {
  const BookChapter({required this.id, required this.title});

  final String id;
  final String title;

  Map<String, Object?> toJson() => {'id': id, 'title': title};

  factory BookChapter.fromJson(Map<String, dynamic> json) =>
      BookChapter(id: json['id'] as String, title: json['title'] as String);
}

/// Book files stay as Markdown. This object is the active, in-memory index.
class BookContent {
  const BookContent({
    required this.chaptersEnabled,
    required this.singleText,
    required this.chapters,
    required this.chapterTexts,
  });

  const BookContent.empty()
    : chaptersEnabled = false,
      singleText = '',
      chapters = const [],
      chapterTexts = const {};

  final bool chaptersEnabled;
  final String singleText;
  final List<BookChapter> chapters;
  final Map<String, String> chapterTexts;

  String textFor(String? chapterId) =>
      chapterId == null ? singleText : chapterTexts[chapterId] ?? '';

  String get combinedText => chaptersEnabled
      ? chapters.map((chapter) => chapterTexts[chapter.id] ?? '').join('\n\n')
      : singleText;

  int get wordCount {
    final text = combinedText.trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  BookContent withText(String? chapterId, String text) => chapterId == null
      ? BookContent(
          chaptersEnabled: chaptersEnabled,
          singleText: text,
          chapters: chapters,
          chapterTexts: chapterTexts,
        )
      : BookContent(
          chaptersEnabled: chaptersEnabled,
          singleText: singleText,
          chapters: chapters,
          chapterTexts: {...chapterTexts, chapterId: text},
        );

  Map<String, Object?> toIndexJson() => {
    'schemaVersion': 1,
    'mode': chaptersEnabled ? 'chapters' : 'single',
    'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
  };
}
