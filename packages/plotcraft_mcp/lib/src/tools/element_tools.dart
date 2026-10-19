import 'package:dart_mcp/server.dart';
import 'package:plotcraft_core/features/project_workspace/domain/active_phase.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_filter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_reference.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';

import '../element_input.dart';
import '../serialize.dart';
import '../tool_spec.dart';

Schema get _project => Schema.string(
  description:
      'The project: its id, its folder path or its exact title '
      '(see list_projects).',
);

Schema get _elementId =>
    Schema.string(description: 'The element id (see list_elements).');

final _idPattern = RegExp(r'^[A-Za-z0-9_-]+$');

/// Properties shared by create_element and update_element.
Map<String, Schema> _elementProperties() => {
  'type': Schema.string(
    description:
        'The element type id: character, place, object, creature, '
        'organization, event, concept, note, or a custom type '
        '(see list_element_types).',
  ),
  'title': Schema.string(description: 'The element\'s name.'),
  'summary': Schema.string(description: 'A short description.'),
  'aliases': Schema.list(
    items: Schema.string(),
    description:
        'Other names; they are also detected in the text as mentions. '
        'Replaces the whole list.',
  ),
  'tags': Schema.list(
    items: Schema.string(),
    description: 'Replaces the list.',
  ),
  'icon': Schema.object(
    description:
        'Overrides the type icon: {"set": "Feather", "name": "user"} '
        '(see search_icons).',
  ),
  'color': Schema.string(description: 'Overrides the type color, #RRGGBB.'),
  'fields': Schema.object(
    description:
        'Values of the type\'s details by field id, e.g. {"age": "17"} '
        '(see list_element_types). Merged into the existing values; an '
        'empty string clears one.',
  ),
  'sections': Schema.list(
    items: Schema.object(),
    description:
        'Free-form notes: [{"title": "Origin", "markdown": "..."}]. '
        'Replaces the list (use add_section to add one).',
  ),
  'phases': Schema.list(
    items: Schema.object(),
    description:
        'How the element changes in the story: [{"title", "description", '
        '"anchor": {"kind": "chapter", "chapter_id": "..."} | '
        '{"kind": "manual", "label": "after the war"} | {"kind": "none"}, '
        '"field_overrides": {"age": "18"}, "image": {"gallery_id": "..."}}]. '
        'Replaces the list (use add_phase to add one).',
  ),
  'relations': Schema.list(
    items: Schema.object(),
    description:
        'Links to other elements: [{"target_id", "label": "sister of", '
        '"reciprocal_label": "sister of", "note"}]. Replaces the list (use '
        'add_relation to add one).',
  ),
  'images': Schema.list(
    items: Schema.object(),
    description:
        'Images, the first is the cover: [{"gallery_id": "g_..."}] '
        '(see list_gallery). Replaces the list.',
  ),
  'time': Schema.object(
    description:
        'When it happens in the story: {"label": "Year 312", "position": 312}. '
        'The label is free text, written the way the story tells it; the '
        'optional number only orders things on the timeline (larger = later). '
        'Send {} or null to remove it.',
  ),
  'mention_policy': Schema.object(
    description:
        '{"auto": true, "ignored_terms": ["..."]}: whether the name and '
        'aliases are highlighted in the text.',
  ),
};

/// Checks the details that point to other elements ("where" of an event) and
/// stores them as element ids, even when the caller wrote the titles. Only the
/// details in [sent] are checked, so older text in others is left alone.
Future<NarrativeElement> _checkedReferences(
  StoryWorkspace story,
  NarrativeElement element,
  Object? sent,
) async {
  if (sent is! Map) return element;
  final type = ElementTypeCatalog.resolve(element.typeId, await story.types());
  if (type == null) return element;
  final others = [
    for (final record in await story.elements())
      if (record.element.id != element.id) record.element,
  ];
  final fields = {...element.fields};
  for (final field in type.fields) {
    if (!field.isReference || !sent.containsKey(field.id)) continue;
    final raw = fields[field.id] ?? '';
    if (raw.trim().isEmpty) continue;
    final ids = <String>[];
    for (final token in ElementReferences.resolve(raw, others)) {
      if (!token.isElement) {
        throw StoryError.validation(
          'Detail "${field.id}": "${token.text}" is not an element.',
          hint:
              'Send element ids (see list_elements); create the element first.',
        );
      }
      final target = others.firstWhere((e) => e.id == token.elementId);
      if (field.targetTypes.isNotEmpty &&
          !field.targetTypes.contains(target.typeId)) {
        throw StoryError.validation(
          'Detail "${field.id}" takes ${field.targetTypes.join(' or ')} '
          'elements, but "${target.title}" is a ${target.typeId}.',
        );
      }
      ids.add(target.id);
    }
    if (field.kind == ElementFieldKind.element && ids.length > 1) {
      throw StoryError.validation('Detail "${field.id}" takes one element.');
    }
    fields[field.id] = ElementReferences.join(ids);
  }
  return element.copyWith(fields: fields);
}

Future<ElementRecord> _load(Call call) async {
  final story = await call.workspace();
  return story.element(call.args.string('element_id'));
}

/// The element after applying [change] to its list-like part, saved with the
/// revision that was read, so a concurrent edit is never lost.
Future<ElementRecord> _modify(
  Call call,
  NarrativeElement Function(NarrativeElement element, StoryWorkspace story)
  change,
) async {
  final story = await call.workspace();
  final record = await story.element(call.args.string('element_id'));
  return story.saveElement(
    change(record.element, story),
    baseRevision: call.args.optString('base_revision') ?? record.revision,
  );
}

Map<String, Object?> _withIncoming(
  ElementRecord record,
  List<ElementRecord> all,
) {
  final json = elementJson(record);
  final index = RelationIndex([for (final r in all) r.element]);
  json['incoming_relations'] = [
    for (final view in index.of(record.element.id))
      if (view.incoming)
        {
          'element_id': view.other.id,
          'title': view.other.title,
          'label': view.label,
        },
  ];
  return json;
}

List<ToolSpec> elementTools() => [
  ToolSpec(
    name: 'list_elements',
    title: 'List elements',
    description:
        'Lists the story elements (characters, places, objects...) of a '
        'project, sorted by title. Filter by text, type or tag.',
    kind: ToolKind.read,
    properties: {
      'project': _project,
      'query': Schema.string(
        description: 'Matches the title, aliases, summary or tags.',
      ),
      'type': Schema.string(description: 'Only this element type id.'),
      'tag': Schema.string(description: 'Only elements with this tag.'),
    },
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      final records = await story.elements();
      final byId = {for (final r in records) r.element.id: r};
      final matching = filterElements(
        [for (final r in records) r.element],
        query: call.args.optString('query') ?? '',
        typeId: call.args.optString('type'),
        tag: call.args.optString('tag'),
      );
      return {
        'count': matching.length,
        'elements': [for (final e in matching) elementSummaryJson(byId[e.id]!)],
      };
    },
  ),
  ToolSpec(
    name: 'get_element',
    title: 'Read an element',
    description:
        'Returns everything about an element: details, sections, phases, '
        'relations (also the ones other elements have to it), images and its '
        'revision. With chapter_id it also says which phase is in force in '
        'that chapter.',
    kind: ToolKind.read,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'chapter_id': Schema.string(
        description: 'Add the phase in force while reading this chapter.',
      ),
    },
    required: ['project', 'element_id'],
    handler: (call) async {
      final story = await call.workspace();
      final all = await story.elements();
      final record = all.firstWhere(
        (r) => r.element.id == call.args.string('element_id'),
        orElse: () => throw StoryError.notFound(
          'Element "${call.args.string('element_id')}"',
          hint: 'Call list_elements to see the element ids.',
        ),
      );
      final json = _withIncoming(record, all);
      final chapterId = call.args.optString('chapter_id');
      if (chapterId != null) {
        final order = [for (final c in await story.chapters()) c.id];
        final phase = activePhaseAt(record.element, order, chapterId);
        json['active_phase_id'] = phase?.id;
      }
      return {'element': json};
    },
  ),
  ToolSpec(
    name: 'create_element',
    title: 'Create an element',
    description:
        'Creates a story element. "type" and "title" are required; send as '
        'much of the rest as you know. Relations can only point to elements '
        'that already exist, so create the others first. The result has the '
        'new element id, which you can use in Markdown as '
        '[[element:<id>|Name]].',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'id': Schema.string(
        description:
            'Optional readable id (letters, digits, - and _), e.g. "maria". '
            'Generated when omitted.',
      ),
      ..._elementProperties(),
    },
    required: ['project', 'type', 'title'],
    handler: (call) async {
      final story = await call.workspace();
      final requested = call.args.optString('id');
      final id = requested ?? 'el_${story.newId()}';
      if (!_idPattern.hasMatch(id)) {
        throw const StoryError.validation(
          'An id can only have letters, digits, "-" and "_".',
        );
      }
      if ((await story.elements()).any((r) => r.element.id == id)) {
        throw StoryError.validation('An element with the id "$id" exists.');
      }
      final now = DateTime.now();
      final blank = NarrativeElement(
        id: id,
        typeId: call.args.string('type'),
        title: call.args.string('title').trim(),
        summary: '',
        sections: const [],
        phases: const [],
        createdAt: now,
        updatedAt: now,
      );
      final record = await story.saveElement(
        await _checkedReferences(
          story,
          ElementInput.apply(blank, call.args, story.newId),
          call.args.raw['fields'],
        ),
      );
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'update_element',
    title: 'Update an element',
    description:
        'Changes an element. Only the properties you send change; "fields" '
        'are merged, while aliases, tags, sections, phases, relations and '
        'images that you send replace the old lists (read the element first '
        'and send the whole list, or use the add_/remove_ tools). Send '
        'base_revision from get_element to avoid overwriting a newer change.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'base_revision': Schema.string(
        description: 'The revision you last read.',
      ),
      ..._elementProperties(),
    },
    required: ['project', 'element_id'],
    handler: (call) async {
      final story = await call.workspace();
      final record = await story.element(call.args.string('element_id'));
      var element = ElementInput.apply(record.element, call.args, story.newId);
      final fields = call.args.raw['fields'];
      if (fields != null) {
        final merged = {
          ...record.element.fields,
          for (final e in (fields as Map).entries) '${e.key}': '${e.value}',
        }..removeWhere((_, value) => value.isEmpty);
        element = element.copyWith(fields: merged);
      }
      final saved = await story.saveElement(
        await _checkedReferences(story, element, fields),
        baseRevision: call.args.optString('base_revision'),
      );
      return {'element': elementJson(saved)};
    },
  ),
  ToolSpec(
    name: 'delete_element',
    title: 'Delete an element',
    description:
        'Removes an element: its file is archived in the project\'s '
        'content/narrative/archive folder (recoverable by hand), relations '
        'other elements had to it are dropped, and links in the text keep '
        'their names but point nowhere. Requires confirm: true and '
        'confirm_name equal to the element title.',
    kind: ToolKind.destructive,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(description: 'The exact element title.'),
    },
    required: ['project', 'element_id'],
    handler: (call) async {
      final record = await _load(call);
      call.context.confirm(
        call.args,
        targetName: record.element.title,
        what: 'the element "${record.element.title}" and its relations',
      );
      final story = await call.workspace();
      await story.removeElement(record.element.id);
      return {'removed': record.element.id};
    },
  ),
  ToolSpec(
    name: 'add_relation',
    title: 'Add a relation',
    description:
        'Links an element to another: "label" is what this element is to the '
        'other ("sister of"); "reciprocal_label" what the other is to this '
        'one (defaults to the same label). The other element sees it too.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'target_id': Schema.string(description: 'The other element id.'),
      'label': Schema.string(),
      'reciprocal_label': Schema.string(),
      'note': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'target_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final args = call.args;
        return element.copyWith(
          relations: [
            ...element.relations,
            ElementRelation(
              id: story.newId(),
              targetId: args.string('target_id'),
              label: args.optString('label') ?? '',
              reciprocalLabel: args.optString('reciprocal_label') ?? '',
              note: args.optString('note') ?? '',
            ),
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'update_relation',
    title: 'Update a relation',
    description:
        'Changes the label, reciprocal label, note or target of a relation.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'relation_id': Schema.string(),
      'target_id': Schema.string(),
      'label': Schema.string(),
      'reciprocal_label': Schema.string(),
      'note': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'relation_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('relation_id');
        if (!element.relations.any((r) => r.id == id)) {
          throw StoryError.notFound('Relation "$id"');
        }
        return element.copyWith(
          relations: [
            for (final r in element.relations)
              r.id == id
                  ? r.copyWith(
                      targetId: call.args.optString('target_id'),
                      label: call.args.optString('label'),
                      reciprocalLabel: call.args.optString('reciprocal_label'),
                      note: call.args.optString('note'),
                    )
                  : r,
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'remove_relation',
    title: 'Remove a relation',
    description: 'Removes one relation from an element.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'relation_id': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'relation_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('relation_id');
        if (!element.relations.any((r) => r.id == id)) {
          throw StoryError.notFound('Relation "$id"');
        }
        return element.copyWith(
          relations: [
            for (final r in element.relations)
              if (r.id != id) r,
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'add_phase',
    title: 'Add a phase',
    description:
        'Adds a phase: a moment in the element\'s life, optionally anchored '
        'to the chapter where it starts, with details that change then. '
        'anchor: {"kind": "chapter", "chapter_id": "..."}, {"kind": '
        '"manual", "label": "after the war"} or {"kind": "none"}.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'title': Schema.string(),
      'description': Schema.string(),
      'anchor': Schema.object(),
      'field_overrides': Schema.object(
        description: 'Details that differ in this phase, by field id.',
      ),
      'image': Schema.object(description: '{"gallery_id": "..."}'),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'title'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final phases = ElementInput.phases([call.args.raw], story.newId);
        return element.copyWith(phases: [...element.phases, ...phases]);
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'update_phase',
    title: 'Update a phase',
    description: 'Changes a phase. Only the properties you send change.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'phase_id': Schema.string(),
      'title': Schema.string(),
      'description': Schema.string(),
      'anchor': Schema.object(),
      'field_overrides': Schema.object(),
      'image': Schema.object(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'phase_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('phase_id');
        final old = element.phases.where((p) => p.id == id).firstOrNull;
        if (old == null) throw StoryError.notFound('Phase "$id"');
        final raw = call.args.raw;
        final merged = <String, Object?>{
          'id': id,
          'title': raw['title'] ?? old.title,
          'description': raw['description'] ?? old.description,
        };
        final rebuilt = ElementInput.phases([merged], story.newId).single;
        final next = rebuilt.copyWith(
          anchor: raw['anchor'] == null
              ? old.anchor
              : ElementInput.anchor(raw['anchor']),
          fieldOverrides: raw['field_overrides'] == null
              ? old.fieldOverrides
              : ElementInput.stringMap(
                  raw['field_overrides'],
                  'field_overrides',
                ),
          image: raw['image'] == null
              ? old.image
              : ElementInput.image(raw['image']),
        );
        return element.copyWith(
          phases: [for (final p in element.phases) p.id == id ? next : p],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'remove_phase',
    title: 'Remove a phase',
    description: 'Removes one phase from an element.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'phase_id': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'phase_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('phase_id');
        if (!element.phases.any((p) => p.id == id)) {
          throw StoryError.notFound('Phase "$id"');
        }
        return element.copyWith(
          phases: [
            for (final p in element.phases)
              if (p.id != id) p,
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'add_section',
    title: 'Add a section',
    description:
        'Adds a free-form note to an element (a titled block of Markdown), '
        'for backstory, rules, lore or research.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'title': Schema.string(),
      'markdown': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'title', 'markdown'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final sections = ElementInput.sections([call.args.raw], story.newId);
        return element.copyWith(sections: [...element.sections, ...sections]);
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'update_section',
    title: 'Update a section',
    description: 'Changes the title or text of a section.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'section_id': Schema.string(),
      'title': Schema.string(),
      'markdown': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'section_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('section_id');
        final old = element.sections.where((s) => s.id == id).firstOrNull;
        if (old == null) throw StoryError.notFound('Section "$id"');
        return element.copyWith(
          sections: [
            for (final s in element.sections)
              s.id == id
                  ? NarrativeSection(
                      id: id,
                      title: call.args.optString('title') ?? old.title,
                      markdown: call.args.optString('markdown') ?? old.markdown,
                    )
                  : s,
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'remove_section',
    title: 'Remove a section',
    description: 'Removes one section from an element.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'section_id': Schema.string(),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'section_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        final id = call.args.string('section_id');
        if (!element.sections.any((s) => s.id == id)) {
          throw StoryError.notFound('Section "$id"');
        }
        return element.copyWith(
          sections: [
            for (final s in element.sections)
              if (s.id != id) s,
          ],
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'set_element_images',
    title: 'Set the images of an element',
    description:
        'Sets the images of an element; the first is its cover. Each image '
        'is {"gallery_id": "g_..."} (see list_gallery) or {"path": '
        '"/absolute/file.png"}, which is first imported into the gallery.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'images': Schema.list(items: Schema.object()),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id', 'images'],
    handler: (call) async {
      final story = await call.workspace();
      final record = await story.element(call.args.string('element_id'));
      final raw = call.args.optObjectList('images') ?? const [];
      final refs = <Map<String, Object?>>[];
      for (final item in raw) {
        if (item['path'] is String) {
          final before = {for (final i in await story.gallery()) i.id};
          final items = await story.importImages([item['path'] as String]);
          final added = items.firstWhere(
            (i) => !before.contains(i.id) && i.exists,
            orElse: () => items.firstWhere(
              (i) => i.file == (item['path'] as String).split('/').last,
            ),
          );
          refs.add({'gallery_id': added.id});
        } else {
          refs.add(item);
        }
      }
      final saved = await story.saveElement(
        record.element.copyWith(
          images: [for (final r in refs) ElementInput.image(r)],
        ),
        baseRevision: call.args.optString('base_revision') ?? record.revision,
      );
      return {'element': elementJson(saved)};
    },
  ),
  ToolSpec(
    name: 'set_mention_policy',
    title: 'Set how an element is detected in the text',
    description:
        '"auto": whether the element\'s name and aliases are highlighted in '
        'the manuscript; "ignored_terms": names or aliases not to detect '
        '(for example a common word that is also a name).',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'auto': Schema.bool(),
      'ignored_terms': Schema.list(items: Schema.string()),
      'base_revision': Schema.string(),
    },
    required: ['project', 'element_id'],
    handler: (call) async {
      final record = await _modify(call, (element, story) {
        return element.copyWith(
          mentionPolicy: element.mentionPolicy.copyWith(
            auto: call.args.optBool('auto'),
            ignoredTerms: call.args.optStringList('ignored_terms'),
          ),
        );
      });
      return {'element': elementJson(record)};
    },
  ),
  ToolSpec(
    name: 'get_element_references',
    title: 'Where an element appears',
    description:
        'Lists where the element\'s name or aliases are written in the '
        'manuscript, and whether each one is linked to the element.',
    kind: ToolKind.read,
    properties: {'project': _project, 'element_id': _elementId},
    required: ['project', 'element_id'],
    handler: (call) async {
      final story = await call.workspace();
      final occurrences = await story.referencesTo(
        call.args.string('element_id'),
      );
      return {
        'count': occurrences.length,
        'linked': occurrences.where((o) => o.linked).length,
        'occurrences': occurrences.map(occurrenceJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'get_active_phase',
    title: 'Phase of an element in a chapter',
    description:
        'Says which phase of the element is in force while reading a chapter '
        '(the latest one anchored at or before it), or null.',
    kind: ToolKind.read,
    properties: {
      'project': _project,
      'element_id': _elementId,
      'chapter_id': Schema.string(),
    },
    required: ['project', 'element_id', 'chapter_id'],
    handler: (call) async {
      final story = await call.workspace();
      final record = await story.element(call.args.string('element_id'));
      final order = [for (final c in await story.chapters()) c.id];
      final phase = activePhaseAt(
        record.element,
        order,
        call.args.string('chapter_id'),
      );
      if (phase == null) return {'phase': null};
      final json = (elementJson(record)['phases']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((p) => p['id'] == phase.id);
      return {'phase': json};
    },
  ),
];
