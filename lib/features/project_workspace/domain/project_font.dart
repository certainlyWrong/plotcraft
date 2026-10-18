/// A font file in the project's `fonts/` folder.
class ProjectFont {
  const ProjectFont({
    required this.file,
    required this.family,
    required this.style,
    required this.path,
  });

  /// File name inside `fonts/`.
  final String file;
  final String family;
  final String style;

  /// Absolute path on this computer (never saved).
  final String path;
}
