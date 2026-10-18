import 'dart:io';

import 'package:crypto/crypto.dart';

/// A short fingerprint of a file's content. Whoever reads a chapter or an
/// element gets one; a write that carries it is refused when the file changed
/// in the meantime, so nobody overwrites an edit they have not seen.
abstract final class ContentRevision {
  /// Revision of a file that does not exist yet.
  static const none = 'none';

  static String ofBytes(List<int> bytes) =>
      sha256.convert(bytes).toString().substring(0, 16);

  static Future<String> ofFile(File file) async =>
      await file.exists() ? ofBytes(await file.readAsBytes()) : none;
}
