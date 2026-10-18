import 'package:dart_mcp/server.dart';
import 'package:plotcraft_core/core/icons/icon_ref.dart';
import 'package:plotcraft_core/core/icons/suggested_icons.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import '../element_input.dart';
import '../serialize.dart';
import '../tool_spec.dart';

Schema get _project => Schema.string(
  description:
      'The project: its id, its folder path or its exact title '
      '(see list_projects).',
);

final _kinds = ElementFieldKind.values.map((kind) => kind.name).toList();

String _slug(String text) {
  final slug = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'field' : slug;
}

List<ElementField> _fields(List<Map<String, Object?>> raw) {
  final used = <String>{};
  return [
    for (final item in raw)
      () {
        final label = ((item['label'] as String?) ?? '').trim();
        if (label.isEmpty) {
          throw const StoryError.validation('Every detail needs a "label".');
        }
        final kindName = (item['kind'] as String?) ?? 'text';
        if (!_kinds.contains(kindName)) {
          throw StoryError.validation(
            'Unknown detail kind "$kindName".',
            hint: 'Use one of ${_kinds.join(', ')}.',
          );
        }
        var id = (item['id'] as String?) ?? _slug(label);
        final base = id;
        for (var n = 2; !used.add(id); n++) {
          id = '${base}_$n';
        }
        return ElementField(
          id: id,
          label: label,
          kind: ElementFieldKind.values.byName(kindName),
          options: [
            for (final option in (item['options'] as List?) ?? const [])
              '$option',
          ],
        );
      }(),
  ];
}

Map<String, Schema> get _typeProperties => {
  'name': Schema.string(description: 'The type name, e.g. "Spell".'),
  'icon': Schema.object(
    description: '{"set": "Feather", "name": "star"} (see search_icons).',
  ),
  'color': Schema.string(description: '#RRGGBB.'),
  'fields': Schema.list(
    items: Schema.object(),
    description:
        'The details every element of this type has: [{"label": "Level", '
        '"kind": "number"}]. kind is one of ${_kinds.join(', ')}; "choice" '
        'also takes "options": ["a", "b"]. Replaces the list; keep the "id" '
        'of existing details so their values stay.',
  ),
};

List<ToolSpec> typeTools() => [
  ToolSpec(
    name: 'list_element_types',
    title: 'List element types',
    description:
        'Lists the types an element can have: the built-in ones (character, '
        'place, object, creature, organization, event, concept, note) and the '
        'project\'s own, each with the details (fields) its elements have.',
    kind: ToolKind.read,
    properties: {'project': _project},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      return {'types': (await story.types()).map(typeJson).toList()};
    },
  ),
  ToolSpec(
    name: 'create_element_type',
    title: 'Create an element type',
    description:
        'Creates a custom element type (for example "Spell" or "Faction") '
        'with its own icon, color and details.',
    kind: ToolKind.write,
    properties: _typeProperties,
    required: ['project', 'name'],
    handler: (call) async {
      final story = await call.workspace();
      final name = call.args.string('name').trim();
      if (name.isEmpty) {
        throw const StoryError.validation('A type needs a name.');
      }
      final type = ElementType(
        id: 't_${story.newId()}',
        name: name,
        icon: call.args.has('icon')
            ? ElementInput.icon(call.args.raw['icon'])
            : const IconRef('Feather', 'star'),
        colorValue: call.args.has('color')
            ? ElementInput.color(call.args.string('color'))
            : 0xFF7B5EA7,
        fields: _fields(call.args.optObjectList('fields') ?? const []),
      );
      return {'type': typeJson(await story.saveType(type))};
    },
  ),
  ToolSpec(
    name: 'update_element_type',
    title: 'Update an element type',
    description:
        'Changes a custom type. Only what you send changes. Built-in types '
        'cannot be changed.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'type_id': Schema.string(description: 'The custom type id.'),
      ..._typeProperties,
    },
    required: ['project', 'type_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('type_id');
      final current = (await story.types())
          .where((t) => t.id == id)
          .firstOrNull;
      if (current == null) {
        throw StoryError.notFound(
          'Element type "$id"',
          hint: 'Call list_element_types to see the type ids.',
        );
      }
      final fields = call.args.optObjectList('fields');
      final updated = current.copyWith(
        name: call.args.optString('name')?.trim(),
        icon: call.args.has('icon')
            ? ElementInput.icon(call.args.raw['icon'])
            : null,
        colorValue: call.args.has('color')
            ? ElementInput.color(call.args.string('color'))
            : null,
        fields: fields == null ? null : _fields(fields),
      );
      return {'type': typeJson(await story.saveType(updated))};
    },
  ),
  ToolSpec(
    name: 'delete_element_type',
    title: 'Delete an element type',
    description:
        'Deletes a custom type. It is refused while any element still uses '
        'it. Requires confirm: true and confirm_name equal to the type name.',
    kind: ToolKind.destructive,
    properties: {
      'project': _project,
      'type_id': Schema.string(),
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(description: 'The exact type name.'),
    },
    required: ['project', 'type_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('type_id');
      final type = (await story.types()).where((t) => t.id == id).firstOrNull;
      if (type == null || type.builtin) {
        throw StoryError.notFound('Custom element type "$id"');
      }
      call.context.confirm(
        call.args,
        targetName: type.name,
        what: 'the element type "${type.name}"',
      );
      await story.removeType(id);
      return {'removed': id};
    },
  ),
  ToolSpec(
    name: 'list_icon_sets',
    title: 'List icon sets',
    description: 'Lists the icon sets elements and types can use.',
    kind: ToolKind.read,
    handler: (call) async => {
      'sets': [
        for (final set in IconCatalog.sets)
          {
            'set': set,
            'label': IconCatalog.labelOf(set),
            'icons': IconCatalog.namesIn(set).length,
          },
      ],
    },
  ),
  ToolSpec(
    name: 'search_icons',
    title: 'Search icons',
    description:
        'Finds icons by name words (e.g. "sword", "map pin"). Without "set" '
        'it searches every set. Use the result as {"set", "name"}.',
    kind: ToolKind.read,
    properties: {
      'query': Schema.string(),
      'set': Schema.string(description: 'Only this set (see list_icon_sets).'),
      'limit': Schema.int(minimum: 1, maximum: 200),
    },
    required: ['query'],
    handler: (call) async {
      final query = call.args.string('query');
      final only = call.args.optString('set');
      if (only != null && !IconCatalog.sets.contains(only)) {
        throw StoryError.validation(
          'Unknown icon set "$only".',
          hint: 'Use one of ${IconCatalog.sets.join(', ')}.',
        );
      }
      final limit = call.args.optInt('limit') ?? 40;
      final found = <Map<String, Object?>>[];
      for (final set in only == null ? IconCatalog.sets : [only]) {
        for (final name in IconCatalog.search(set, query)) {
          found.add({'set': set, 'name': name});
          if (found.length >= limit) return {'icons': found, 'truncated': true};
        }
      }
      return {'icons': found, 'truncated': false};
    },
  ),
  ToolSpec(
    name: 'list_suggested_icons',
    title: 'Suggested icons',
    description:
        'Hand-picked icons for stories, in groups: people, places, objects, '
        'creatures, organizations, magic, events and notes.',
    kind: ToolKind.read,
    handler: (call) async => {
      'groups': [
        for (final group in suggestedIconGroups)
          {
            'group': group.id,
            'icons': [for (final icon in group.icons) iconJson(icon)],
          },
      ],
    },
  ),
];
