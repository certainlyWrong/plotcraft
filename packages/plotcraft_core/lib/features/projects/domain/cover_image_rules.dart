import 'package:path/path.dart' as p;

import '../../../core/file_system.dart';

/// What a project cover image must satisfy, shared by the creation form, the
/// metadata editor and the services that copy the file into the project.
abstract final class CoverImageRules {
  static const extensions = ['png', 'jpg', 'jpeg', 'webp'];
  static const maxBytes = 10 * 1024 * 1024;

  /// Extension of [path] including the dot, lower case (for example `.png`).
  static String extensionOf(String path) => p.extension(path).toLowerCase();

  static Future<bool> isValid(String path) async {
    final file = fs.file(path);
    return extensions.contains(extensionOf(path).replaceFirst('.', '')) &&
        await file.exists() &&
        await file.length() <= maxBytes;
  }
}
