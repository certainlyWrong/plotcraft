import 'icon_names.g.dart';

/// Reference to an icon by set and name, as stored in project files. The
/// catalog (see `tool/gen_icon_catalog.dart`) maps it back to an `IconData`.
/// Code points are never stored: building an `IconData` from a number would
/// defeat icon tree-shaking and break when the icon package changes.
class IconRef {
  const IconRef(this.set, this.name);

  /// Shown when the stored icon is missing from the catalog.
  static const fallback = IconRef('Feather', 'help_circle');

  final String set;
  final String name;

  /// True when the catalog has an icon with this set and name.
  bool get exists => IconCatalog.contains(set, name);

  Map<String, Object?> toJson() => {'set': set, 'name': name};

  /// Returns null for anything that is not a `{set, name}` map.
  static IconRef? fromJson(Object? json) {
    if (json is! Map) return null;
    final set = json['set'];
    final name = json['name'];
    return set is String && name is String ? IconRef(set, name) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is IconRef && other.set == set && other.name == name;

  @override
  int get hashCode => Object.hash(set, name);

  @override
  String toString() => 'IconRef($set.$name)';
}

/// Read access to the generated catalog for the icon picker.
abstract final class IconCatalog {
  /// Set keys in display order.
  static List<String> get sets => iconCatalogSets.keys.toList();

  static String labelOf(String set) => iconCatalogSets[set] ?? set;

  static Iterable<String> namesIn(String set) => iconNames[set] ?? const [];

  static final _lookup = <String, Set<String>>{};

  static bool contains(String set, String name) {
    final names = iconNames[set];
    if (names == null) return false;
    return (_lookup[set] ??= names.toSet()).contains(name);
  }

  /// Icon names of [set] containing every word of [query] (case-insensitive;
  /// underscores and dashes count as spaces). An empty query lists all.
  static List<String> search(String set, String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'[\s_\-]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final names = namesIn(set);
    if (words.isEmpty) return names.toList();
    return names.where((name) {
      final normalized = name.toLowerCase().replaceAll('_', ' ');
      return words.every(normalized.contains);
    }).toList();
  }
}
