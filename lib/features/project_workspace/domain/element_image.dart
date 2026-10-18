/// An image attached to a story element. Both forms are relative to the
/// project: a gallery image is referenced by its stable ID, an attachment by
/// the path of the copy stored for the element.
class ElementImage {
  const ElementImage.gallery(String id) : isGallery = true, value = id;

  const ElementImage.attachment(String file) : isGallery = false, value = file;

  final bool isGallery;

  /// Gallery image ID, or the attachment path inside the project.
  final String value;

  Map<String, Object?> toJson() => isGallery
      ? {'ref': 'gallery', 'id': value}
      : {'ref': 'attachment', 'file': value};

  /// Null for anything that is not a recognised image reference.
  static ElementImage? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final file = json['file'];
    return switch (json['ref']) {
      'gallery' when id is String && id.isNotEmpty => ElementImage.gallery(id),
      'attachment' when file is String && file.isNotEmpty =>
        ElementImage.attachment(file),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ElementImage &&
      other.isGallery == isGallery &&
      other.value == value;

  @override
  int get hashCode => Object.hash(isGallery, value);
}
