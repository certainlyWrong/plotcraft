import '../../../core/icons/icon_ref.dart';

/// A kind of story project. Every project has a [primaryFormat] saved in its
/// manifest; the format decides which tools the workspace offers.
class ProjectFormat {
  const ProjectFormat({
    required this.id,
    required this.icon,
    this.hasManuscript = true,
  });

  final String id;
  final IconRef icon;

  /// Whether the project has a written manuscript (chapters or one text).
  /// Formats made of images, such as manga, do not.
  final bool hasManuscript;

  String get nameKey => 'formats.$id.name';
  String get descriptionKey => 'formats.$id.description';
}

abstract final class ProjectFormats {
  static const book = ProjectFormat(
    id: 'book',
    icon: IconRef('Feather', 'book_open'),
  );

  /// Manga starts as a skeleton: elements, gallery and overview, but no
  /// manuscript and no page editor yet.
  static const manga = ProjectFormat(
    id: 'manga',
    icon: IconRef('MaterialCommunityIcons', 'book_open_page_variant'),
    hasManuscript: false,
  );

  /// Formats a new project can be created as.
  static const all = [book, manga];

  /// The format of [id]; an unknown ID (a project made by a newer version)
  /// is treated as a book so that it still opens.
  static ProjectFormat of(String id) =>
      all.where((format) => format.id == id).firstOrNull ?? book;

  static bool isKnown(String id) => all.any((format) => format.id == id);
}
