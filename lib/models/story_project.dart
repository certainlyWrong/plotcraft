class StoryProject {
  const StoryProject({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.coverIndex,
    this.subtitle = '',
    this.author = '',
    this.genre = '',
    this.tags = const [],
    this.directoryPath,
    this.primaryFormat = 'book',
    this.coverFile,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int coverIndex;
  final String subtitle;
  final String author;
  final String genre;
  final List<String> tags;

  /// Local folder containing project.json. It is not stored in the manifest.
  final String? directoryPath;
  final String primaryFormat;

  /// Relative path to a cover image inside this project, when provided.
  final String? coverFile;

  StoryProject copyWith({
    String? title,
    String? description,
    String? subtitle,
    String? author,
    String? genre,
    List<String>? tags,
    int? coverIndex,
    String? coverFile,
    bool removeCover = false,
  }) => StoryProject(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    subtitle: subtitle ?? this.subtitle,
    author: author ?? this.author,
    genre: genre ?? this.genre,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    coverIndex: coverIndex ?? this.coverIndex,
    directoryPath: directoryPath,
    primaryFormat: primaryFormat,
    coverFile: removeCover ? null : coverFile ?? this.coverFile,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subtitle': subtitle,
    'author': author,
    'genre': genre,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'coverIndex': coverIndex,
    'schemaVersion': 1,
    'primaryFormat': primaryFormat,
    'coverFile': coverFile,
  };

  factory StoryProject.fromJson(
    Map<String, dynamic> json, {
    String? directoryPath,
  }) => StoryProject(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    author: json['author'] as String? ?? '',
    genre: json['genre'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    coverIndex: json['coverIndex'] as int? ?? 0,
    directoryPath: directoryPath,
    primaryFormat: json['primaryFormat'] as String? ?? 'book',
    coverFile: json['coverFile'] as String?,
  );
}
