import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/core/theme/argb_hex.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/story_time.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import 'args.dart';

/// Reads the pieces of an element from tool arguments. Each reader is used
/// both when creating an element and when patching one, so the two accept
/// exactly the same shapes.
abstract final class ElementInput {
  static IconRef icon(Object? raw) {
    if (raw is! Map || raw['set'] is! String || raw['name'] is! String) {
      throw const StoryError.validation(
        'An icon is {"set": "...", "name": "..."}.',
        hint: 'Use search_icons or list_suggested_icons to find valid icons.',
      );
    }
    final ref = IconRef(raw['set'] as String, raw['name'] as String);
    if (!ref.exists) {
      throw StoryError.validation(
        'There is no icon "${ref.name}" in the set "${ref.set}".',
        hint: 'Use search_icons or list_suggested_icons to find valid icons.',
      );
    }
    return ref;
  }

  static int color(String value) {
    final argb = parseHexArgb(value);
    if (argb == null) {
      throw StoryError.validation('"$value" is not a color; use #RRGGBB.');
    }
    return argb;
  }

  static Map<String, String> stringMap(Object? raw, String name) {
    if (raw is! Map) {
      throw StoryError.validation('"$name" must be an object of strings.');
    }
    return {
      for (final entry in raw.entries)
        if ('${entry.value}'.isNotEmpty) '${entry.key}': '${entry.value}',
    };
  }

  static List<NarrativeSection> sections(
    List<Map<String, Object?>> raw,
    String Function() newId,
  ) => [
    for (final item in raw)
      NarrativeSection(
        id: (item['id'] as String?) ?? newId(),
        title: (item['title'] as String?) ?? '',
        markdown: (item['markdown'] as String?) ?? '',
      ),
  ];

  static NarrativeAnchor anchor(Object? raw) {
    if (raw == null) return const NarrativeAnchor.none();
    if (raw is! Map) {
      throw const StoryError.validation('An anchor is an object.');
    }
    switch (raw['kind']) {
      case 'none' || null:
        return const NarrativeAnchor.none();
      case 'chapter':
        final id = raw['chapter_id'];
        if (id is! String || id.isEmpty) {
          throw const StoryError.validation(
            'A chapter anchor needs "chapter_id".',
          );
        }
        return NarrativeAnchor.chapter(id);
      case 'manual':
        final label = raw['label'];
        if (label is! String || label.trim().isEmpty) {
          throw const StoryError.validation('A manual anchor needs "label".');
        }
        return NarrativeAnchor.manual(label);
    }
    throw const StoryError.validation(
      'Anchor "kind" must be none, chapter or manual.',
    );
  }

  /// An image reference: `{gallery_id}`. (Files from the computer are first
  /// imported into the gallery, then referenced by id.)
  static ElementImage image(Object? raw) {
    if (raw is Map && raw['gallery_id'] is String) {
      return ElementImage.gallery(raw['gallery_id'] as String);
    }
    if (raw is Map && raw['attachment'] is String) {
      return ElementImage.attachment(raw['attachment'] as String);
    }
    throw const StoryError.validation(
      'An image is {"gallery_id": "..."} (see list_gallery).',
    );
  }

  static List<NarrativePhase> phases(
    List<Map<String, Object?>> raw,
    String Function() newId,
  ) => [
    for (final item in raw)
      NarrativePhase(
        id: (item['id'] as String?) ?? newId(),
        title: ((item['title'] as String?) ?? '').trim(),
        description: (item['description'] as String?) ?? '',
        anchor: anchor(item['anchor']),
        fieldOverrides: item['field_overrides'] == null
            ? const {}
            : stringMap(item['field_overrides'], 'field_overrides'),
        image: item['image'] == null ? null : image(item['image']),
      ),
  ];

  static List<ElementRelation> relations(
    List<Map<String, Object?>> raw,
    String Function() newId,
  ) => [
    for (final item in raw)
      ElementRelation(
        id: (item['id'] as String?) ?? newId(),
        targetId: (item['target_id'] as String?) ?? '',
        label: (item['label'] as String?) ?? '',
        reciprocalLabel: (item['reciprocal_label'] as String?) ?? '',
        note: (item['note'] as String?) ?? '',
      ),
  ];

  /// Applies the arguments to [base] (a new element when null). Only the keys
  /// that are present change; a list that is present replaces the old one.
  static NarrativeElement apply(
    NarrativeElement base,
    Args args,
    String Function() newId,
  ) {
    var element = base;
    final title = args.optString('title');
    if (title != null && title.trim().isEmpty) {
      throw const StoryError.validation('The title cannot be empty.');
    }
    final iconRaw = args.raw['icon'];
    final colorRaw = args.optString('color');
    final aliases = args.optStringList('aliases');
    final tags = args.optStringList('tags');
    final fields = args.raw['fields'];
    final sections = args.optObjectList('sections');
    final phases = args.optObjectList('phases');
    final relations = args.optObjectList('relations');
    final images = args.optObjectList('images');
    final policy = args.optObject('mention_policy');
    final timeGiven = args.raw.containsKey('time');
    final time = timeGiven ? args.optObject('time') : null;
    final position = time?['position'];
    if (position != null && (position is! num || !position.isFinite)) {
      throw const StoryError.validation(
        'time.position must be a finite number.',
      );
    }
    final storyTime = time == null
        ? null
        : StoryTime(
            label: (time['label'] as String?) ?? '',
            position: (position as num?)?.toDouble(),
          );
    element = element.copyWith(
      typeId: args.optString('type'),
      title: title?.trim(),
      summary: args.optString('summary'),
      aliases: aliases
          ?.map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList(),
      tags: tags?.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      icon: iconRaw == null ? null : icon(iconRaw),
      colorValue: colorRaw == null ? null : color(colorRaw),
      fields: fields == null ? null : stringMap(fields, 'fields'),
      sections: sections == null
          ? null
          : ElementInput.sections(sections, newId),
      phases: phases == null ? null : ElementInput.phases(phases, newId),
      relations: relations == null
          ? null
          : ElementInput.relations(relations, newId),
      images: images == null ? null : [for (final i in images) image(i)],
      // An empty or null `time` takes the element off the timeline.
      time: storyTime != null && !storyTime.isEmpty ? storyTime : null,
      clearTime: timeGiven && (storyTime == null || storyTime.isEmpty),
      mentionPolicy: policy == null
          ? null
          : base.mentionPolicy.copyWith(
              auto: policy['auto'] as bool?,
              ignoredTerms: (policy['ignored_terms'] as List?)?.cast<String>(),
            ),
    );
    return element;
  }
}
