class NarrativeSection {
  const NarrativeSection({
    required this.id,
    required this.title,
    required this.markdown,
  });

  final String id;
  final String title;
  final String markdown;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'markdown': markdown,
  };

  factory NarrativeSection.fromJson(Map<String, dynamic> json) =>
      NarrativeSection(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        markdown: json['markdown'] as String? ?? '',
      );
}

class NarrativePhase {
  const NarrativePhase({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
  };

  factory NarrativePhase.fromJson(Map<String, dynamic> json) => NarrativePhase(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );
}

class NarrativeElement {
  const NarrativeElement({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.sections,
    required this.phases,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kind;
  final String title;
  final String summary;
  final List<NarrativeSection> sections;
  final List<NarrativePhase> phases;
  final DateTime createdAt;
  final DateTime updatedAt;

  NarrativeElement copyWith({
    String? kind,
    String? title,
    String? summary,
    List<NarrativeSection>? sections,
    List<NarrativePhase>? phases,
  }) => NarrativeElement(
    id: id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    sections: sections ?? this.sections,
    phases: phases ?? this.phases,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'kind': kind,
    'title': title,
    'summary': summary,
    'sections': sections.map((section) => section.toJson()).toList(),
    'phases': phases.map((phase) => phase.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NarrativeElement.fromJson(Map<String, dynamic> json) =>
      NarrativeElement(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'character',
        title: json['title'] as String,
        summary: json['summary'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NarrativeSection.fromJson)
            .toList(),
        phases: (json['phases'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NarrativePhase.fromJson)
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
