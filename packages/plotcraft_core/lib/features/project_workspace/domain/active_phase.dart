import 'narrative_anchor.dart';
import 'narrative_element.dart';

/// The phase of [element] in force while reading chapter [chapterId]: the
/// latest one anchored at or before that chapter, given the book's chapter
/// order. Phases with no chapter anchor are not tied to the text, so they are
/// never chosen. Null when none applies.
NarrativePhase? activePhaseAt(
  NarrativeElement element,
  List<String> chapterOrder,
  String? chapterId,
) {
  final current = chapterId == null ? -1 : chapterOrder.indexOf(chapterId);
  if (current < 0) return null;
  NarrativePhase? best;
  var bestIndex = -1;
  for (final phase in element.phases) {
    if (phase.anchor.kind != NarrativeAnchorKind.chapter) continue;
    final index = chapterOrder.indexOf(phase.anchor.value);
    if (index < 0 || index > current) continue;
    if (index >= bestIndex) {
      best = phase;
      bestIndex = index;
    }
  }
  return best;
}
