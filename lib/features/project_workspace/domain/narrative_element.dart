import '../../../core/icons/icon_ref.dart';
import '../../../core/theme/argb_hex.dart';
import 'element_image.dart';
import 'element_relation.dart';
import 'narrative_anchor.dart';

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

/// A moment in the life of an element: how it changes as the story goes on.
/// It can start at a chapter, override some of the element's details and show
/// its own image (one of the element's images).
class NarrativePhase {
  const NarrativePhase({
    required this.id,
    required this.title,
    required this.description,
    this.anchor = const NarrativeAnchor.none(),
    this.fieldOverrides = const {},
    this.image,
  });

  final String id;
  final String title;
  final String description;
  final NarrativeAnchor anchor;

  /// Values of the type's details that differ in this phase, by field ID.
  final Map<String, String> fieldOverrides;
  final ElementImage? image;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'anchor': anchor.toJson(),
    if (fieldOverrides.isNotEmpty) 'fieldOverrides': fieldOverrides,
    if (image != null) 'image': image!.toJson(),
  };

  factory NarrativePhase.fromJson(Map<String, dynamic> json) => NarrativePhase(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    anchor: NarrativeAnchor.fromJson(json['anchor']),
    fieldOverrides: {
      for (final entry
          in (json['fieldOverrides'] as Map<String, dynamic>? ?? const {})
              .entries)
        if (entry.value is String && (entry.value as String).isNotEmpty)
          entry.key: entry.value as String,
    },
    image: ElementImage.fromJson(json['image']),
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
    this.colorValue,
    this.images = const [],
    this.fields = const {},
    this.relations = const [],
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
  final int? colorValue;
  final List<ElementImage> images;

  /// Values of the type's fields, by field ID.
  final Map<String, String> fields;
  final List<NarrativeSection> sections;
  final List<NarrativePhase> phases;

  /// Links to other elements, stored on this (source) element only.
  final List<ElementRelation> relations;
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
    int? colorValue,
    bool clearIcon = false,
    bool clearColor = false,
    List<ElementImage>? images,
    Map<String, String>? fields,
    List<NarrativeSection>? sections,
    List<NarrativePhase>? phases,
    List<ElementRelation>? relations,
    MentionPolicy? mentionPolicy,
  }) => NarrativeElement(
    id: id,
    typeId: typeId ?? this.typeId,
    title: title ?? this.title,
    aliases: aliases ?? this.aliases,
    summary: summary ?? this.summary,
    tags: tags ?? this.tags,
    icon: clearIcon ? null : icon ?? this.icon,
    colorValue: clearColor ? null : colorValue ?? this.colorValue,
    images: images ?? this.images,
    fields: fields ?? this.fields,
    sections: sections ?? this.sections,
    phases: phases ?? this.phases,
    relations: relations ?? this.relations,
    mentionPolicy: mentionPolicy ?? this.mentionPolicy,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  /// Project-relative paths of the files copied for this element.
  Set<String> get attachmentFiles => {
    for (final image in [
      ...images,
      for (final phase in phases)
        if (phase.image != null) phase.image!,
    ])
      if (!image.isGallery) image.value,
  };

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'typeId': typeId,
    'title': title,
    'aliases': aliases,
    'summary': summary,
    'tags': tags,
    if (icon != null) 'icon': icon!.toJson(),
    if (colorValue != null) 'color': argbToHex(colorValue!),
    'images': images.map((image) => image.toJson()).toList(),
    'fields': fields,
    'sections': sections.map((section) => section.toJson()).toList(),
    'phases': phases.map((phase) => phase.toJson()).toList(),
    'relations': relations.map((relation) => relation.toJson()).toList(),
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
        colorValue: parseHexArgb(json['color'] as String?),
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
        relations: (json['relations'] as List<dynamic>? ?? const [])
            .map(ElementRelation.fromJson)
            .whereType<ElementRelation>()
            .toList(),
        mentionPolicy: MentionPolicy.fromJson(json['mentionPolicy']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
