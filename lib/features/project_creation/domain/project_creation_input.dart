enum ProjectFieldIssue { required, tooShort, tooLong, tooMany, duplicated }

class ProjectCreationInput {
  const ProjectCreationInput({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.description,
    required this.genre,
    required this.tags,
    required this.coverIndex,
    this.coverSourcePath,
  });

  final String title;
  final String subtitle;
  final String author;
  final String description;
  final String genre;
  final List<String> tags;
  final int coverIndex;
  final String? coverSourcePath;

  static ProjectFieldIssue? validateTitle(String value) {
    final length = value.trim().length;
    if (length == 0) return ProjectFieldIssue.required;
    if (length < 3) return ProjectFieldIssue.tooShort;
    if (length > 120) return ProjectFieldIssue.tooLong;
    return null;
  }

  static ProjectFieldIssue? validateSubtitle(String value) =>
      value.trim().length > 160 ? ProjectFieldIssue.tooLong : null;

  static ProjectFieldIssue? validateAuthor(String value) =>
      value.trim().length > 120 ? ProjectFieldIssue.tooLong : null;

  static ProjectFieldIssue? validateDescription(String value) =>
      value.trim().length > 2000 ? ProjectFieldIssue.tooLong : null;

  static ProjectFieldIssue? validateGenre(String value) =>
      value.trim().length > 80 ? ProjectFieldIssue.tooLong : null;

  static List<String> parseTags(String value) => value
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();

  static ProjectFieldIssue? validateTags(List<String> value) {
    if (value.length > 8) return ProjectFieldIssue.tooMany;
    if (value.any((tag) => tag.trim().isEmpty)) {
      return ProjectFieldIssue.required;
    }
    if (value.any((tag) => tag.trim().length > 40)) {
      return ProjectFieldIssue.tooLong;
    }
    final normalized = value.map((tag) => tag.trim().toLowerCase()).toSet();
    if (normalized.length != value.length) return ProjectFieldIssue.duplicated;
    return null;
  }

  void validate() {
    if (validateTitle(title) != null ||
        validateSubtitle(subtitle) != null ||
        validateAuthor(author) != null ||
        validateDescription(description) != null ||
        validateGenre(genre) != null ||
        validateTags(tags) != null ||
        coverIndex < 0 ||
        coverIndex >= 5) {
      throw const FormatException('Invalid project metadata');
    }
  }
}
