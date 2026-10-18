/// A gallery image with a stable ID, so elements and the text can refer to it
/// without a path. [exists] is false when the file was removed outside the app.
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.file,
    required this.path,
    required this.exists,
  });

  final String id;

  /// File name inside `gallery/`.
  final String file;

  /// Absolute path on this machine (never saved).
  final String path;
  final bool exists;
}
