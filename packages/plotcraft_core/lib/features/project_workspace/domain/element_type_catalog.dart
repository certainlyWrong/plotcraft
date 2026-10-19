import '../../../core/icons/icon_ref.dart';
import 'element_type.dart';

/// Types every project has. IDs are stable because elements refer to them.
abstract final class ElementTypeCatalog {
  static const character = 'character';
  static const place = 'place';
  static const object = 'object';
  static const creature = 'creature';
  static const organization = 'organization';
  static const event = 'event';
  static const concept = 'concept';
  static const note = 'note';

  static ElementField _field(
    String id, [
    ElementFieldKind kind = ElementFieldKind.text,
    List<String> targetTypes = const [],
  ]) => ElementField(
    id: id,
    labelKey: 'elements.fields.$id',
    kind: kind,
    targetTypes: targetTypes,
  );

  static ElementType _type(
    String id,
    IconRef icon,
    int color, [
    List<ElementField> fields = const [],
  ]) => ElementType(
    id: id,
    nameKey: 'elements.types.$id',
    icon: icon,
    colorValue: color,
    fields: fields,
    builtin: true,
  );

  static final builtin = <ElementType>[
    _type(character, const IconRef('Feather', 'user'), 0xFF7B5EA7, [
      _field('age'),
      _field('occupation'),
      _field('appearance', ElementFieldKind.longText),
      _field('personality', ElementFieldKind.longText),
    ]),
    _type(place, const IconRef('Feather', 'map_pin'), 0xFF3E9B6B, [
      _field('region'),
      _field('climate'),
    ]),
    _type(object, const IconRef('Feather', 'box'), 0xFFC9A227, [
      _field('origin'),
      _field('owner', ElementFieldKind.element, const [
        character,
        organization,
      ]),
    ]),
    _type(creature, const IconRef('RpgAwesome', 'wolf_howl'), 0xFFC0443F, [
      _field('habitat', ElementFieldKind.elements, const [place]),
      _field('abilities', ElementFieldKind.longText),
    ]),
    _type(organization, const IconRef('Feather', 'flag'), 0xFF3B7DBF, [
      _field('purpose'),
      _field('leader', ElementFieldKind.element, const [character]),
    ]),
    _type(event, const IconRef('Feather', 'calendar'), 0xFFD9822B, [
      // When it happens is the element's "time" (the timeline), not a detail.
      _field('where', ElementFieldKind.elements, const [place]),
    ]),
    _type(concept, const IconRef('Feather', 'compass'), 0xFF2E9AA3),
    _type(note, const IconRef('Feather', 'file_text'), 0xFF6B7280),
  ];

  static ElementType? builtinById(String id) =>
      builtin.where((type) => type.id == id).firstOrNull;

  /// The type for [id] among the built-in and [custom] ones; null if unknown.
  static ElementType? resolve(String id, List<ElementType> custom) =>
      builtinById(id) ?? custom.where((type) => type.id == id).firstOrNull;
}
