/// Where an editor font comes from.
enum EditorFontSource { bundled, project, system }

class EditorFont {
  const EditorFont({required this.family, required this.source});

  /// The name stored in documents (the `font` attribute).
  final String family;
  final EditorFontSource source;
}

/// The fonts a document can use, and how to draw them. Fonts that travel with
/// the project are registered under a project-specific name so another project
/// with a font of the same family never draws with this project's file.
class EditorFontCatalog {
  const EditorFontCatalog({
    required this.bundled,
    this.project = const [],
    this.system = const [],
    this.projectKey = '',
  });

  /// Bundled families (always available, identical everywhere).
  final List<String> bundled;

  /// Families added to the project's `fonts/` folder.
  final List<String> project;

  /// Families installed on this computer.
  final List<String> system;

  /// Identifies the project in the names its fonts are registered under.
  final String projectKey;

  /// Registered name of a project font.
  String registeredName(String family) => 'project:$projectKey:$family';

  /// Fonts in menu order: bundled, project, then system (without repeats).
  List<EditorFont> get fonts {
    final seen = <String>{};
    return [
      for (final family in bundled)
        if (seen.add(family.toLowerCase()))
          EditorFont(family: family, source: EditorFontSource.bundled),
      for (final family in project)
        if (seen.add(family.toLowerCase()))
          EditorFont(family: family, source: EditorFontSource.project),
      for (final family in system)
        if (seen.add(family.toLowerCase()))
          EditorFont(family: family, source: EditorFontSource.system),
    ];
  }

  /// Menu entries: label -> value stored in the document.
  Map<String, String> get menuItems => {
    for (final font in fonts) font.family: font.family,
  };

  EditorFontSource? sourceOf(String family) {
    final lower = family.toLowerCase();
    for (final font in fonts) {
      if (font.family.toLowerCase() == lower) return font.source;
    }
    return null;
  }

  bool isAvailable(String family) => sourceOf(family) != null;

  /// The font family to draw [family] with.
  String resolve(String family) => sourceOf(family) == EditorFontSource.project
      ? registeredName(_exact(family))
      : family;

  String _exact(String family) => project.firstWhere(
    (name) => name.toLowerCase() == family.toLowerCase(),
    orElse: () => family,
  );

  /// Families of [used] that this computer cannot draw, in order. Generic
  /// names such as `serif` are not reported.
  List<String> missing(Iterable<String> used) {
    const generic = {'serif', 'sans-serif', 'monospace', 'cursive', 'fantasy'};
    final seen = <String>{};
    return [
      for (final family in used)
        if (!generic.contains(family.toLowerCase()) &&
            !isAvailable(family) &&
            seen.add(family.toLowerCase()))
          family,
    ];
  }

  EditorFontCatalog copyWith({
    List<String>? project,
    List<String>? system,
    String? projectKey,
  }) => EditorFontCatalog(
    bundled: bundled,
    project: project ?? this.project,
    system: system ?? this.system,
    projectKey: projectKey ?? this.projectKey,
  );
}
