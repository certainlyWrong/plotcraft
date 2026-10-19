import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_reference.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

enum StoryGraphNodeKind { element, chapter }

enum StoryGraphEdgeKind {
  /// A relation written on an element ("sister of").
  relation,

  /// A phase of an element that starts at a chapter.
  phase,

  /// An element written in a chapter, by name or by link.
  mention,

  /// A detail of an element that points to another (the places of an event).
  reference,
}

class StoryGraphNode {
  const StoryGraphNode({
    required this.id,
    required this.kind,
    required this.refId,
    required this.label,
    this.typeId,
  });

  /// Unique in the graph: `element:<id>` or `chapter:<id>`.
  final String id;
  final StoryGraphNodeKind kind;

  /// Element or chapter ID.
  final String refId;
  final String label;

  /// Element type ID; null for chapters.
  final String? typeId;
}

class StoryGraphEdge {
  const StoryGraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.kind,
    this.label = '',
    this.reciprocalLabel = '',
    this.weight = 1,
    this.labelKey,
  });

  final String sourceId;
  final String targetId;
  final StoryGraphEdgeKind kind;

  /// What the source is to the target ("sister of").
  final String label;
  final String reciprocalLabel;

  /// Translation key of [label] when it names a built-in detail.
  final String? labelKey;

  /// For mentions, how many times the element is written in the chapter.
  final int weight;

  bool touches(String nodeId) => sourceId == nodeId || targetId == nodeId;
}

/// Everything in a project that is linked to something else: elements joined
/// by relations, chapters where an element's phase begins, and chapters where
/// an element is written. Elements with no link still appear, so the whole
/// cast is visible.
class StoryGraph {
  const StoryGraph({required this.nodes, required this.edges});

  static const empty = StoryGraph(nodes: [], edges: []);

  final List<StoryGraphNode> nodes;
  final List<StoryGraphEdge> edges;

  static String elementNodeId(String id) => 'element:$id';
  static String chapterNodeId(String id) => 'chapter:$id';

  factory StoryGraph.build({
    required Iterable<NarrativeElement> elements,
    required Iterable<BookChapter> chapters,
    Iterable<ChapterPresence> presence = const [],
    List<ElementType> types = const [],
  }) {
    final elementList = elements.toList();
    final chapterById = {for (final c in chapters) c.id: c};
    final elementIds = {for (final e in elementList) e.id};

    final edges = <StoryGraphEdge>[];
    // One edge per pair of elements, even when both sides declare a relation.
    final relationByPair = <String, int>{};
    final usedChapters = <String>{};

    for (final element in elementList) {
      final source = elementNodeId(element.id);
      for (final relation in element.relations) {
        if (relation.targetId == element.id ||
            !elementIds.contains(relation.targetId)) {
          continue;
        }
        final target = elementNodeId(relation.targetId);
        final key = ([source, target]..sort()).join('|');
        final existing = relationByPair[key];
        if (existing != null) {
          final edge = edges[existing];
          // The other side wrote it first: keep its direction, fill labels.
          if (edge.label.isEmpty && edge.reciprocalLabel.isEmpty) {
            edges[existing] = StoryGraphEdge(
              sourceId: edge.sourceId,
              targetId: edge.targetId,
              kind: StoryGraphEdgeKind.relation,
              label: edge.sourceId == source
                  ? relation.label
                  : relation.reciprocalLabel,
              reciprocalLabel: edge.sourceId == source
                  ? relation.reciprocalLabel
                  : relation.label,
            );
          }
          continue;
        }
        relationByPair[key] = edges.length;
        edges.add(
          StoryGraphEdge(
            sourceId: source,
            targetId: target,
            kind: StoryGraphEdgeKind.relation,
            label: relation.label,
            reciprocalLabel: relation.reciprocalLabel,
          ),
        );
      }
      final phaseChapters = <String>{};
      for (final phase in element.phases) {
        if (phase.anchor.kind != NarrativeAnchorKind.chapter) continue;
        final chapterId = phase.anchor.value;
        if (!chapterById.containsKey(chapterId) ||
            !phaseChapters.add(chapterId)) {
          continue;
        }
        usedChapters.add(chapterId);
        edges.add(
          StoryGraphEdge(
            sourceId: source,
            targetId: chapterNodeId(chapterId),
            kind: StoryGraphEdgeKind.phase,
            label: phase.title,
          ),
        );
      }
    }

    // Details that point to elements ("where" of an event) link them too,
    // unless a relation already joins the pair.
    for (final reference in ElementReferences.all(elementList, types)) {
      final source = elementNodeId(reference.sourceId);
      final target = elementNodeId(reference.targetId);
      final key = ([source, target]..sort()).join('|');
      if (relationByPair.containsKey(key)) continue;
      relationByPair[key] = edges.length;
      edges.add(
        StoryGraphEdge(
          sourceId: source,
          targetId: target,
          kind: StoryGraphEdgeKind.reference,
          label: reference.field.label,
          labelKey: reference.field.labelKey,
        ),
      );
    }

    // Chapters link to the elements written in them, in reading order.
    for (final chapter in presence) {
      final chapterId = chapter.chapterId;
      if (chapterId == null || !chapterById.containsKey(chapterId)) continue;
      for (final entry in chapter.counts.entries) {
        if (!elementIds.contains(entry.key) || entry.value <= 0) continue;
        usedChapters.add(chapterId);
        edges.add(
          StoryGraphEdge(
            sourceId: elementNodeId(entry.key),
            targetId: chapterNodeId(chapterId),
            kind: StoryGraphEdgeKind.mention,
            weight: entry.value,
          ),
        );
      }
    }

    return StoryGraph(
      nodes: [
        for (final element in elementList)
          StoryGraphNode(
            id: elementNodeId(element.id),
            kind: StoryGraphNodeKind.element,
            refId: element.id,
            label: element.title,
            typeId: element.typeId,
          ),
        for (final chapter in chapters)
          if (usedChapters.contains(chapter.id))
            StoryGraphNode(
              id: chapterNodeId(chapter.id),
              kind: StoryGraphNodeKind.chapter,
              refId: chapter.id,
              label: chapter.title,
            ),
      ],
      edges: edges,
    );
  }

  /// Number of edges at each node.
  Map<String, int> get degrees {
    final result = {for (final node in nodes) node.id: 0};
    for (final edge in edges) {
      result[edge.sourceId] = (result[edge.sourceId] ?? 0) + 1;
      result[edge.targetId] = (result[edge.targetId] ?? 0) + 1;
    }
    return result;
  }

  /// Ids of the nodes directly linked to [nodeId].
  Set<String> neighbors(String nodeId) => {
    for (final edge in edges)
      if (edge.sourceId == nodeId)
        edge.targetId
      else if (edge.targetId == nodeId)
        edge.sourceId,
  };

  /// The graph keeping only the edges [keep] accepts (nodes stay).
  StoryGraph whereEdges(bool Function(StoryGraphEdge edge) keep) => StoryGraph(
    nodes: nodes,
    edges: [
      for (final edge in edges)
        if (keep(edge)) edge,
    ],
  );

  /// The node [startId] and every node at most [depth] links away from it.
  Set<String> reach(String startId, int depth) {
    final seen = {startId};
    var frontier = {startId};
    for (var step = 0; step < depth && frontier.isNotEmpty; step++) {
      final next = <String>{};
      for (final id in frontier) {
        for (final neighbor in neighbors(id)) {
          if (seen.add(neighbor)) next.add(neighbor);
        }
      }
      frontier = next;
    }
    return seen;
  }

  /// The graph without the nodes [keep] rejects and the edges that lose an
  /// end with them.
  StoryGraph where(bool Function(StoryGraphNode node) keep) {
    final kept = [
      for (final node in nodes)
        if (keep(node)) node,
    ];
    final ids = {for (final node in kept) node.id};
    return StoryGraph(
      nodes: kept,
      edges: [
        for (final edge in edges)
          if (ids.contains(edge.sourceId) && ids.contains(edge.targetId)) edge,
      ],
    );
  }
}
