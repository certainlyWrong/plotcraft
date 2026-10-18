import '../book_content.dart';
import '../narrative_element.dart';
import 'mention_index.dart';
import 'rich_document.dart';

/// One place where an element appears in the book.
class MentionOccurrence {
  const MentionOccurrence({
    required this.chapterId,
    required this.chapterTitle,
    required this.start,
    required this.end,
    required this.snippet,
    required this.linked,
  });

  /// Null for the single manuscript.
  final String? chapterId;
  final String chapterTitle;
  final int start;
  final int end;

  /// The text around the occurrence, on one line.
  final String snippet;

  /// True when the text is linked to the element; false when only its name
  /// or an alias is written there.
  final bool linked;
}

/// Every occurrence of [element] in [book], in reading order. Names are found
/// even when the element does not allow automatic highlighting, because this
/// is the writer asking where it appears.
List<MentionOccurrence> scanElementMentions(
  BookContent book,
  NarrativeElement element,
  String manuscriptTitle, {
  int context = 36,
}) {
  final index = MentionIndex([
    element.copyWith(mentionPolicy: element.mentionPolicy.copyWith(auto: true)),
  ]);
  List<MentionOccurrence> inDocument(String? chapterId, String title) {
    final delta = book.deltaFor(chapterId);
    final text = RichDocument.plainText(delta, embed: ' ');
    return [
      for (final hit in index.scan(delta))
        if (hit.elementId == element.id)
          MentionOccurrence(
            chapterId: chapterId,
            chapterTitle: title,
            start: hit.start,
            end: hit.end,
            snippet: _snippet(text, hit.start, hit.end, context),
            linked: hit.linked,
          ),
    ];
  }

  return book.chaptersEnabled
      ? [
          for (final chapter in book.chapters)
            ...inDocument(chapter.id, chapter.title),
        ]
      : inDocument(null, manuscriptTitle);
}

String _snippet(String text, int start, int end, int context) {
  final from = (start - context).clamp(0, text.length);
  final to = (end + context).clamp(0, text.length);
  final cut = text.substring(from, to).replaceAll(RegExp(r'\s+'), ' ').trim();
  return '${from > 0 ? '…' : ''}$cut${to < text.length ? '…' : ''}';
}
