import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';

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
  ///
  /// Same shape as the editor's `BlockEmbed.custom(CustomBlockEmbed(type,
  /// data))`: the embed is a JSON string `{type: data}` under `custom`.
  static Map<String, dynamic> customEmbed(String type, Object data) => {
    'custom': jsonEncode({type: data is String ? data : jsonEncode(data)}),
  };

  /// The `{type, data}` of a custom embed value, or null if [value] is not one.
  static ({String type, String data})? readCustomEmbed(Object? value) {
    if (value is! Map || value['custom'] is! String) return null;
    try {
      final json = jsonDecode(value['custom'] as String);
      if (json is! Map || json.length != 1) return null;
      final entry = json.entries.single;
      if (entry.key is! String || entry.value is! String) return null;
      return (type: entry.key as String, data: entry.value as String);
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

  /// Plain text of [delta]. Embeds are written as [embed]: Quill counts each
  /// as one character; pass an empty string to leave them out.
  static String plainText(Delta delta, {String embed = objectReplacement}) {
    final buffer = StringBuffer();
    for (final op in delta.toList()) {
      final data = op.data;
      buffer.write(data is String ? data : embed);
    }
    return buffer.toString();
  }

  /// The character Quill uses for an embed in its plain text.
  static const objectReplacement = '\u{FFFC}';

  /// IDs of the elements mentioned in [delta], in order of appearance.
  static List<String> mentionedIds(Delta delta) {
    final ids = <String>[];
    for (final op in delta.toList()) {
      final mention = op.attributes?[mentionKey];
      if (mention is Map && mention['id'] is String) {
        final id = mention['id'] as String;
        if (!ids.contains(id)) ids.add(id);
      }
    }
    return ids;
  }

  /// IDs of the gallery images shown in [delta].
  static Set<String> galleryImageIds(Delta delta) => {
    for (final op in delta.toList())
      if (readGalleryImage(op.data) case final image?) image['id'] as String,
  };
}
