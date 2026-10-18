import 'narrative_element.dart';

/// Elements matching a search text, a type and a tag. Empty or null filters
/// match everything. The text is compared with the title, the aliases and the
/// tags, ignoring case.
List<NarrativeElement> filterElements(
  List<NarrativeElement> elements, {
  String query = '',
  String? typeId,
  String? tag,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final element in elements)
      if ((typeId == null || element.typeId == typeId) &&
          (tag == null || element.tags.contains(tag)) &&
          (needle.isEmpty ||
              element.title.toLowerCase().contains(needle) ||
              element.aliases.any(
                (alias) => alias.toLowerCase().contains(needle),
              ) ||
              element.tags.any((t) => t.toLowerCase().contains(needle))))
        element,
  ];
}

/// Every tag used by [elements], sorted without regard to case.
List<String> tagsOf(List<NarrativeElement> elements) =>
    ({for (final element in elements) ...element.tags}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
