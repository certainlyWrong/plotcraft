import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/story_time.dart';

/// One element placed (or waiting to be placed) on the story's own timeline.
class ChronologyEntry {
  const ChronologyEntry({
    required this.elementId,
    required this.title,
    required this.typeId,
    required this.time,
    this.inferred = false,
  });

  final String elementId;
  final String title;
  final String typeId;
  final StoryTime time;

  /// True when [time] was not set on the element but read from the text of an
  /// event's "when" detail.
  final bool inferred;
}

/// The story's chronology: every element that says when it happens, ordered
/// by its position. Elements with only a label ("long ago") come after the
/// placed ones, in the order they were created, until the author places them.
class StoryChronology {
  const StoryChronology(this.entries);

  static const empty = StoryChronology([]);

  /// Placed entries by position, then the ones without a position.
  final List<ChronologyEntry> entries;

  int get placedCount => entries.where((e) => e.time.isPlaced).length;

  factory StoryChronology.build(Iterable<NarrativeElement> elements) {
    final placed = <(int, ChronologyEntry)>[];
    final unplaced = <ChronologyEntry>[];
    var order = 0;
    for (final element in elements) {
      var time = element.time;
      var inferred = false;
      if (time == null && element.typeId == ElementTypeCatalog.event) {
        final when = element.fields['when']?.trim() ?? '';
        if (when.isNotEmpty) {
          time = StoryTime(label: when);
          inferred = true;
        }
      }
      if (time == null || time.isEmpty) continue;
      final entry = ChronologyEntry(
        elementId: element.id,
        title: element.title,
        typeId: element.typeId,
        time: time,
        inferred: inferred,
      );
      if (time.isPlaced) {
        placed.add((order++, entry));
      } else {
        unplaced.add(entry);
      }
    }
    placed.sort((a, b) {
      final byPosition = a.$2.time.position!.compareTo(b.$2.time.position!);
      return byPosition != 0 ? byPosition : a.$1.compareTo(b.$1);
    });
    return StoryChronology([for (final p in placed) p.$2, ...unplaced]);
  }

  /// The position that puts the entry at [movedIndex] of [sequence] where it
  /// was dropped: between its nearest placed neighbours, after the previous
  /// one, before the next one, or 0 when nothing around it is placed.
  /// [sequence] is the list as it looks after the move.
  static double positionAfterMove(
    List<ChronologyEntry> sequence,
    int movedIndex,
  ) {
    double? before;
    for (var i = movedIndex - 1; i >= 0; i--) {
      final position = sequence[i].time.position;
      if (position != null) {
        before = position;
        break;
      }
    }
    double? after;
    for (var i = movedIndex + 1; i < sequence.length; i++) {
      final position = sequence[i].time.position;
      if (position != null) {
        after = position;
        break;
      }
    }
    if (before != null && after != null) return (before + after) / 2;
    if (before != null) return before + 1;
    if (after != null) return after - 1;
    return 0;
  }
}
