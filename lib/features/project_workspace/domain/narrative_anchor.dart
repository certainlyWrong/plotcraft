enum NarrativeAnchorKind { none, chapter, manual }

/// Where in the story a phase of an element begins: at a chapter of the book,
/// at a point the author describes ("after the war"), or nowhere in
/// particular.
class NarrativeAnchor {
  const NarrativeAnchor.none() : kind = NarrativeAnchorKind.none, value = '';

  const NarrativeAnchor.chapter(String chapterId)
    : kind = NarrativeAnchorKind.chapter,
      value = chapterId;

  const NarrativeAnchor.manual(String label)
    : kind = NarrativeAnchorKind.manual,
      value = label;

  final NarrativeAnchorKind kind;

  /// Chapter ID for [NarrativeAnchorKind.chapter], the label for
  /// [NarrativeAnchorKind.manual].
  final String value;

  Map<String, Object?> toJson() => switch (kind) {
    NarrativeAnchorKind.none => {'kind': 'none'},
    NarrativeAnchorKind.chapter => {'kind': 'chapter', 'id': value},
    NarrativeAnchorKind.manual => {'kind': 'manual', 'label': value},
  };

  /// Anything unreadable becomes [NarrativeAnchor.none].
  factory NarrativeAnchor.fromJson(Object? json) {
    if (json is Map) {
      final id = json['id'];
      final label = json['label'];
      switch (json['kind']) {
        case 'chapter' when id is String && id.isNotEmpty:
          return NarrativeAnchor.chapter(id);
        case 'manual' when label is String && label.trim().isNotEmpty:
          return NarrativeAnchor.manual(label);
      }
    }
    return const NarrativeAnchor.none();
  }

  @override
  bool operator ==(Object other) =>
      other is NarrativeAnchor && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}
