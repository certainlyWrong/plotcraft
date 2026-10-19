import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

/// What happens to one element in one chapter.
class MatrixCell {
  const MatrixCell({this.mentions = 0, this.phases = const []});

  static const none = MatrixCell();

  /// How many times the element is written in the chapter.
  final int mentions;

  /// Titles of the element's phases that start at the chapter.
  final List<String> phases;

  bool get isEmpty => mentions == 0 && phases.isEmpty;
}

class MatrixRow {
  const MatrixRow({
    required this.elementId,
    required this.title,
    required this.typeId,
    required this.cells,
    required this.firstChapter,
  });

  final String elementId;
  final String title;
  final String typeId;

  /// One cell per chapter, in reading order.
  final List<MatrixCell> cells;

  /// Index of the first chapter where the element shows up.
  final int firstChapter;

  int get totalMentions => cells.fold(0, (sum, cell) => sum + cell.mentions);
}

/// Chapters across, elements down: who appears where, and where each phase of
/// an element begins. Elements that appear nowhere are left out.
class StoryMatrix {
  const StoryMatrix({required this.chapters, required this.rows});

  static const empty = StoryMatrix(chapters: [], rows: []);

  final List<BookChapter> chapters;
  final List<MatrixRow> rows;

  factory StoryMatrix.build({
    required Iterable<NarrativeElement> elements,
    required Iterable<BookChapter> chapters,
    required Iterable<ChapterPresence> presence,
  }) {
    final chapterList = chapters.toList();
    final indexOf = {
      for (var i = 0; i < chapterList.length; i++) chapterList[i].id: i,
    };
    final mentions = {
      for (final item in presence)
        if (item.chapterId != null) item.chapterId!: item.counts,
    };
    final rows = <MatrixRow>[];
    for (final element in elements) {
      final phasesAt = <int, List<String>>{};
      for (final phase in element.phases) {
        if (phase.anchor.kind != NarrativeAnchorKind.chapter) continue;
        final index = indexOf[phase.anchor.value];
        if (index == null) continue;
        (phasesAt[index] ??= []).add(phase.title);
      }
      final cells = [
        for (var i = 0; i < chapterList.length; i++)
          MatrixCell(
            mentions: mentions[chapterList[i].id]?[element.id] ?? 0,
            phases: phasesAt[i] ?? const [],
          ),
      ];
      final first = cells.indexWhere((cell) => !cell.isEmpty);
      if (first < 0) continue;
      rows.add(
        MatrixRow(
          elementId: element.id,
          title: element.title,
          typeId: element.typeId,
          cells: cells,
          firstChapter: first,
        ),
      );
    }
    rows.sort((a, b) {
      final byFirst = a.firstChapter.compareTo(b.firstChapter);
      if (byFirst != 0) return byFirst;
      final byMentions = b.totalMentions.compareTo(a.totalMentions);
      return byMentions != 0 ? byMentions : a.title.compareTo(b.title);
    });
    return StoryMatrix(chapters: chapterList, rows: rows);
  }
}
