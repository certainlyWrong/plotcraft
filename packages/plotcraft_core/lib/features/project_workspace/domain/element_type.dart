import '../../../core/icons/icon_ref.dart';
import '../../../core/theme/argb_hex.dart';

enum ElementFieldKind {
  text,
  longText,
  number,
  date,
  choice,
  boolean,

  /// One other element, chosen from the project.
  element,

  /// Several other elements (for example the places of an event).
  elements,
  url,
}

/// One detail of an element type, such as "Age" or "Habitat". Built-in fields
/// have a [labelKey] (translated by the interface); custom ones a [label].
class ElementField {
  const ElementField({
    required this.id,
    this.label = '',
    this.labelKey,
    this.kind = ElementFieldKind.text,
    this.options = const [],
    this.targetTypes = const [],
  });

  final String id;
  final String label;
  final String? labelKey;
  final ElementFieldKind kind;

  /// Allowed values when [kind] is [ElementFieldKind.choice].
  final List<String> options;

  /// For [ElementFieldKind.element] and [ElementFieldKind.elements]: the
  /// element types that can be chosen. Empty means any element.
  final List<String> targetTypes;

  bool get isReference =>
      kind == ElementFieldKind.element || kind == ElementFieldKind.elements;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    if (options.isNotEmpty) 'options': options,
    if (targetTypes.isNotEmpty) 'targetTypes': targetTypes,
  };

  /// Null when the map has no usable ID.
  static ElementField? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    return ElementField(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      kind: ElementFieldKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => ElementFieldKind.text,
      ),
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      targetTypes: (json['targetTypes'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

/// A kind of story element (character, place, ...): name, icon, color and the
/// extra fields its elements offer. Built-in types live in code
/// ([ElementTypeCatalog]); custom ones are saved in `types.json`.
class ElementType {
  const ElementType({
    required this.id,
    required this.icon,
    required this.colorValue,
    this.name = '',
    this.nameKey,
    this.fields = const [],
    this.builtin = false,
  });

  final String id;
  final String name;

  /// Translation key of a built-in type's name.
  final String? nameKey;
  final IconRef icon;

  /// ARGB value of the type's color (see the `color` extension in the app).
  final int colorValue;
  final List<ElementField> fields;
  final bool builtin;

  ElementType copyWith({
    String? name,
    IconRef? icon,
    int? colorValue,
    List<ElementField>? fields,
  }) => ElementType(
    id: id,
    name: name ?? this.name,
    nameKey: nameKey,
    icon: icon ?? this.icon,
    colorValue: colorValue ?? this.colorValue,
    fields: fields ?? this.fields,
    builtin: builtin,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.toJson(),
    'color': argbToHex(colorValue),
    'fields': fields.map((field) => field.toJson()).toList(),
  };

  /// Reads a custom type; null when it has no ID or name.
  static ElementType? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return ElementType(
      id: json['id'] as String,
      name: name,
      icon: IconRef.fromJson(json['icon']) ?? IconRef.fallback,
      colorValue: parseHexArgb(json['color'] as String?) ?? 0xFF6B7280,
      fields: (json['fields'] as List<dynamic>? ?? const [])
          .map(ElementField.fromJson)
          .whereType<ElementField>()
          .toList(),
    );
  }
}
