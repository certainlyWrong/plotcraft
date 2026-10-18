import 'narrative_element.dart';

/// A directed link from one element to another ("Maria — sister of — Lia").
/// It is stored on the source element only; the target sees it through
/// [RelationIndex], so the two sides can never disagree.
class ElementRelation {
  const ElementRelation({
    required this.id,
    required this.targetId,
    this.label = '',
    this.reciprocalLabel = '',
    this.note = '',
  });

  final String id;
  final String targetId;

  /// What the source is to the target ("sister of").
  final String label;

  /// What the target is to the source; falls back to [label] when empty.
  final String reciprocalLabel;
  final String note;

  ElementRelation copyWith({
    String? targetId,
    String? label,
    String? reciprocalLabel,
    String? note,
  }) => ElementRelation(
    id: id,
    targetId: targetId ?? this.targetId,
    label: label ?? this.label,
    reciprocalLabel: reciprocalLabel ?? this.reciprocalLabel,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'targetId': targetId,
    'label': label,
    'reciprocalLabel': reciprocalLabel,
    'note': note,
  };

  /// Null when the map has no ID or target.
  static ElementRelation? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final targetId = json['targetId'];
    if (id is! String || targetId is! String || targetId.isEmpty) return null;
    return ElementRelation(
      id: id,
      targetId: targetId,
      label: json['label'] as String? ?? '',
      reciprocalLabel: json['reciprocalLabel'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

/// A relation seen from one element: the other element and the label that
/// describes what [other] is to the element being viewed.
class ResolvedRelation {
  const ResolvedRelation({
    required this.relation,
    required this.other,
    required this.label,
    required this.incoming,
  });

  final ElementRelation relation;
  final NarrativeElement other;
  final String label;

  /// True when the relation is stored on [other] and points to this element.
  final bool incoming;
}

/// Both directions of every relation, derived in memory from the elements.
class RelationIndex {
  RelationIndex(List<NarrativeElement> elements)
    : _byId = {for (final element in elements) element.id: element} {
    for (final source in elements) {
      for (final relation in source.relations) {
        final target = _byId[relation.targetId];
        if (target == null || target.id == source.id) continue;
        (_views[source.id] ??= []).add(
          ResolvedRelation(
            relation: relation,
            other: target,
            label: relation.label,
            incoming: false,
          ),
        );
        (_views[target.id] ??= []).add(
          ResolvedRelation(
            relation: relation,
            other: source,
            label: relation.reciprocalLabel.isEmpty
                ? relation.label
                : relation.reciprocalLabel,
            incoming: true,
          ),
        );
      }
    }
  }

  final Map<String, NarrativeElement> _byId;
  final Map<String, List<ResolvedRelation>> _views = {};

  List<ResolvedRelation> of(String elementId) => _views[elementId] ?? const [];

  /// Relations of [element] whose target no longer exists, removed.
  static List<ElementRelation> prune(
    NarrativeElement element,
    Set<String> existingIds,
  ) => element.relations
      .where(
        (relation) =>
            existingIds.contains(relation.targetId) &&
            relation.targetId != element.id,
      )
      .toList();
}
