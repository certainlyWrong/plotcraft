import 'element_type.dart';
import 'element_type_catalog.dart';
import 'narrative_element.dart';
import 'rich/mention_index.dart';

/// One piece of a reference detail: an element, or text that matches no
/// element (what the detail held before it could point to elements).
class ReferenceToken {
  const ReferenceToken.element(String this.elementId) : text = '';
  const ReferenceToken.text(this.text) : elementId = null;

  final String? elementId;
  final String text;

  bool get isElement => elementId != null;
}

/// A detail of one element that points to another.
class FieldReference {
  const FieldReference({
    required this.sourceId,
    required this.targetId,
    required this.field,
  });

  final String sourceId;
  final String targetId;
  final ElementField field;
}

/// Reads and writes the value of a reference detail. It is kept as plain text
/// in the element's `fields`: IDs (or leftover text) separated by commas, so
/// older projects, where the detail was free text, still open.
abstract final class ElementReferences {
  static List<String> split(String raw) => [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  static String join(Iterable<String> tokens) =>
      tokens.where((t) => t.trim().isNotEmpty).map((t) => t.trim()).join(',');

  /// Each token as an element when it is the ID, the title or an alias of one
  /// of [elements] (accents and case ignored), otherwise as text.
  static List<ReferenceToken> resolve(
    String raw,
    Iterable<NarrativeElement> elements,
  ) {
    final list = elements.toList();
    final byId = {for (final e in list) e.id: e};
    final byName = <String, String>{};
    for (final element in list) {
      for (final name in [element.title, ...element.aliases]) {
        byName.putIfAbsent(MentionIndex.fold(name.trim()), () => element.id);
      }
    }
    final seen = <String>{};
    final tokens = <ReferenceToken>[];
    for (final part in split(raw)) {
      final id = byId.containsKey(part)
          ? part
          : byName[MentionIndex.fold(part)];
      if (id == null) {
        tokens.add(ReferenceToken.text(part));
      } else if (seen.add(id)) {
        tokens.add(ReferenceToken.element(id));
      }
    }
    return tokens;
  }

  /// The elements named by [raw], in order.
  static List<String> ids(String raw, Iterable<NarrativeElement> elements) => [
    for (final token in resolve(raw, elements))
      if (token.isElement) token.elementId!,
  ];

  /// Every reference detail in [elements], resolved to the elements it points
  /// to. An element never refers to itself.
  static List<FieldReference> all(
    Iterable<NarrativeElement> elements,
    List<ElementType> customTypes,
  ) {
    final list = elements.toList();
    final result = <FieldReference>[];
    for (final element in list) {
      final type = ElementTypeCatalog.resolve(element.typeId, customTypes);
      if (type == null) continue;
      for (final field in type.fields) {
        if (!field.isReference) continue;
        final raw = element.fields[field.id];
        if (raw == null || raw.trim().isEmpty) continue;
        for (final id in ids(raw, list)) {
          if (id == element.id) continue;
          result.add(
            FieldReference(sourceId: element.id, targetId: id, field: field),
          );
        }
      }
    }
    return result;
  }
}
