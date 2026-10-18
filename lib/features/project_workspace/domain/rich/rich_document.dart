import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Names used inside manuscript Deltas, shared by the Markdown codecs, the
/// editor and the mention index.
abstract final class RichDocument {
  /// Inline attribute on the text of a linked element: `{id, name}`.
  static const mentionKey = 'mention';

  /// Embed (own line or inline) showing a gallery image by ID.
  static const galleryImageType = 'gallery-image';

  /// Embed drawn as a horizontal rule.
  static const dividerType = 'divider';

  static const fileVersion = 1;

  /// An empty document: a single empty line.
  static Delta empty() => Delta()..insert('\n');

  /// Delta of a document loaded from the `ops` of a saved file.
  static Delta fromOps(Object? ops) {
    final delta = Delta.fromJson(ops as List<dynamic>);
    return _endsWithNewline(delta) ? delta : (delta..insert('\n'));
  }

  static bool _endsWithNewline(Delta delta) {
    if (delta.isEmpty) return false;
    final last = delta.last.data;
    return last is String && last.endsWith('\n');
  }

  /// The `{insert: {custom: ...}}` value for a custom embed of [type].
  static Map<String, dynamic> customEmbed(String type, Object data) =>
      BlockEmbed.custom(
        CustomBlockEmbed(type, data is String ? data : jsonEncode(data)),
      ).toJson();

  /// The `{type, data}` of a custom embed value, or null if [value] is not one.
  static ({String type, String data})? readCustomEmbed(Object? value) {
    if (value is! Map || value['custom'] is! String) return null;
    try {
      final embed = CustomBlockEmbed.fromJsonString(value['custom'] as String);
      return (type: embed.type, data: embed.data as String);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> galleryImage(
    String id, {
    int? width,
    String? align,
  }) => customEmbed(galleryImageType, {
    'id': id,
    'width': ?width,
    'align': ?align,
  });

  static Map<String, dynamic> divider() => customEmbed(dividerType, '1');

  /// The `{id, ...}` of a gallery image embed, or null.
  static Map<String, dynamic>? readGalleryImage(Object? value) {
    final custom = readCustomEmbed(value);
    if (custom == null || custom.type != galleryImageType) return null;
    try {
      final data = jsonDecode(custom.data);
      return data is Map<String, dynamic> && data['id'] is String ? data : null;
    } catch (_) {
      return null;
    }
  }

  static bool isDivider(Object? value) =>
      readCustomEmbed(value)?.type == dividerType;

  /// The mention attribute value `{id, name}`.
  static Map<String, dynamic> mention(String id, String name) => {
    'id': id,
    'name': name,
  };

  /// Plain text of [delta]: embeds count as one character, like Quill does.
  static String plainText(Delta delta) {
    final buffer = StringBuffer();
    for (final op in delta.toList()) {
      final data = op.data;
      buffer.write(data is String ? data : '￼');
    }
    return buffer.toString();
  }
}
