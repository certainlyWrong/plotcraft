import 'dart:ui';

import '../../../core/icons/icon_ref.dart';
import '../../../core/theme/color_hex.dart';
import 'element_image.dart';

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

/// Controls how an element is detected in the text without being linked.
class MentionPolicy {
  const MentionPolicy({this.auto = true, this.ignoredTerms = const []});

  /// Highlight the element's name and aliases wherever they appear.
  final bool auto;

  /// Names or aliases that must not be detected for this element.
  final List<String> ignoredTerms;

  MentionPolicy copyWith({bool? auto, List<String>? ignoredTerms}) =>
      MentionPolicy(
        auto: auto ?? this.auto,
        ignoredTerms: ignoredTerms ?? this.ignoredTerms,
      );

  Map<String, Object?> toJson() => {'auto': auto, 'ignoredTerms': ignoredTerms};

  factory MentionPolicy.fromJson(Object? json) => json is Map
      ? MentionPolicy(
          auto: json['auto'] as bool? ?? true,
          ignoredTerms: (json['ignoredTerms'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
        )
      : const MentionPolicy();
}

/// A character, place, object... of the story. `schemaVersion` 2 replaced the
/// free-text `kind` by [typeId]; version 1 files are still read (the old kind
/// becomes the type ID and is upgraded by `upgradeLegacyKinds`).
class NarrativeElement {
  const NarrativeElement({
    required this.id,
    required this.typeId,
    required this.title,
    required this.summary,
    required this.sections,
    required this.phases,
    required this.createdAt,
    required this.updatedAt,
    this.aliases = const [],
    this.tags = const [],
    this.icon,
    this.color,
    this.images = const [],
    this.fields = const {},
    this.mentionPolicy = const MentionPolicy(),
  });

  static const schemaVersion = 2;

  final String id;
  final String typeId;
  final String title;

  /// Other names the element is known by; also used to detect mentions.
  final List<String> aliases;
  final String summary;
  final List<String> tags;

  /// Overrides of the type's icon and color for this element.
  final IconRef? icon;
  final Color? color;
  final List<ElementImage> images;

  /// Values of the type's fields, by field ID.
  final Map<String, String> fields;
  final List<NarrativeSection> sections;
  final List<NarrativePhase> phases;
  final MentionPolicy mentionPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  NarrativeElement copyWith({
    String? typeId,
    String? title,
    List<String>? aliases,
    String? summary,
    List<String>? tags,
    IconRef? icon,
    Color? color,
    bool clearIcon = false,
    bool clearColor = false,
    List<ElementImage>? images,
    Map<String, String>? fields,
    List<NarrativeSection>? sections,
    List<NarrativePhase>? phases,
    MentionPolicy? mentionPolicy,
  }) => NarrativeElement(
    id: id,
    typeId: typeId ?? this.typeId,
    title: title ?? this.title,
    aliases: aliases ?? this.aliases,
    summary: summary ?? this.summary,
    tags: tags ?? this.tags,
    icon: clearIcon ? null : icon ?? this.icon,
    color: clearColor ? null : color ?? this.color,
    images: images ?? this.images,
    fields: fields ?? this.fields,
    sections: sections ?? this.sections,
    phases: phases ?? this.phases,
    mentionPolicy: mentionPolicy ?? this.mentionPolicy,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'typeId': typeId,
    'title': title,
    'aliases': aliases,
    'summary': summary,
    'tags': tags,
    if (icon != null) 'icon': icon!.toJson(),
    if (color != null) 'color': colorToHex(color!),
    'images': images.map((image) => image.toJson()).toList(),
    'fields': fields,
    'sections': sections.map((section) => section.toJson()).toList(),
    'phases': phases.map((phase) => phase.toJson()).toList(),
    'mentionPolicy': mentionPolicy.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static List<String> _strings(Object? value) =>
      (value as List<dynamic>? ?? const []).whereType<String>().toList();

  factory NarrativeElement.fromJson(Map<String, dynamic> json) =>
      NarrativeElement(
        id: json['id'] as String,
        // Version 1 stored a free-text `kind`.
        typeId: (json['typeId'] ?? json['kind']) as String? ?? 'character',
        title: json['title'] as String,
        aliases: _strings(json['aliases']),
        summary: json['summary'] as String? ?? '',
        tags: _strings(json['tags']),
        icon: IconRef.fromJson(json['icon']),
        color: parseHexColor(json['color'] as String?),
        images: (json['images'] as List<dynamic>? ?? const [])
            .map(ElementImage.fromJson)
            .whereType<ElementImage>()
            .toList(),
        fields: {
          for (final entry
              in (json['fields'] as Map<String, dynamic>? ?? const {}).entries)
            if (entry.value is String) entry.key: entry.value as String,
        },
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NarrativeSection.fromJson)
            .toList(),
        phases: (json['phases'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NarrativePhase.fromJson)
            .toList(),
        mentionPolicy: MentionPolicy.fromJson(json['mentionPolicy']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
