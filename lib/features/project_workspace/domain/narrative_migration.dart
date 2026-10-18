import 'dart:ui';

import '../../../core/icons/icon_ref.dart';
import 'element_type.dart';
import 'element_type_catalog.dart';
import 'narrative_element.dart';

class NarrativeUpgrade {
  const NarrativeUpgrade(
    this.elements,
    this.types, {
    required this.typesChanged,
  });

  final List<NarrativeElement> elements;

  /// Custom types, including any created for old free-text kinds.
  final List<ElementType> types;
  final bool typesChanged;
}

/// Version 1 elements carried a free-text kind ("character", "Monster"). A
/// kind that is not a known type becomes a custom type named after it, so no
/// element ends up without a type. Nothing is written to the elements.
NarrativeUpgrade upgradeLegacyKinds(
  List<NarrativeElement> elements,
  List<ElementType> customTypes,
) {
  final types = [...customTypes];
  final created = <String, ElementType>{};
  var changed = false;
  final upgraded = <NarrativeElement>[];
  for (final element in elements) {
    final raw = element.typeId.trim();
    if (ElementTypeCatalog.resolve(raw, types) != null) {
      upgraded.add(element);
      continue;
    }
    final label = raw.isEmpty ? 'note' : raw;
    final type = created.putIfAbsent(label.toLowerCase(), () {
      final id = _uniqueId(label, types);
      final next = ElementType(
        id: id,
        name: label,
        icon: const IconRef('Feather', 'bookmark'),
        color: const Color(0xFF6B7280),
      );
      types.add(next);
      changed = true;
      return next;
    });
    upgraded.add(
      NarrativeElement(
        id: element.id,
        typeId: type.id,
        title: element.title,
        aliases: element.aliases,
        summary: element.summary,
        tags: element.tags,
        icon: element.icon,
        color: element.color,
        images: element.images,
        fields: element.fields,
        sections: element.sections,
        phases: element.phases,
        relations: element.relations,
        mentionPolicy: element.mentionPolicy,
        createdAt: element.createdAt,
        updatedAt: element.updatedAt,
      ),
    );
  }
  return NarrativeUpgrade(upgraded, types, typesChanged: changed);
}

String _uniqueId(String label, List<ElementType> types) {
  final slug = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9à-öø-ÿ]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final base = 't_${slug.isEmpty ? 'type' : slug}';
  var id = base;
  var n = 2;
  while (types.any((type) => type.id == id) ||
      ElementTypeCatalog.builtinById(id) != null) {
    id = '${base}_${n++}';
  }
  return id;
}
