import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'rich_document.dart';

/// A stretch of a document's plain text (offsets count an embed as one
/// character, like the editor does).
class TextHit {
  const TextHit(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is TextHit && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TextHit($start, $end)';
}

/// Edits of a manuscript [Delta] without an editor: replace, insert, delete
/// and format ranges, find and replace text, and put block embeds on their own
/// line. Every function returns a new Delta and keeps the formatting of the
/// text around the change.
abstract final class DeltaEdit {
  /// Plain text of [delta]; offsets into it are the offsets used below.
  static String text(Delta delta) => RichDocument.plainText(delta);

  /// Attributes inherited by text typed at [offset]: the inline formatting of
  /// the character before it (or at it, at the start), without the link to an
  /// element, which belongs to that exact text.
  static Map<String, dynamic>? inlineAttributesAt(Delta delta, int offset) {
    var position = 0;
    Map<String, dynamic>? found;
    for (final op in delta.toList()) {
      final length = op.length ?? 0;
      final before = offset > 0 ? offset - 1 : 0;
      if (before < position + length) {
        found = op.attributes;
        break;
      }
      position += length;
    }
    if (found == null) return null;
    final inherited = {
      for (final entry in found.entries)
        if (_inline.contains(entry.key)) entry.key: entry.value,
    };
    return inherited.isEmpty ? null : inherited;
  }

  static const _inline = {
    'bold',
    'italic',
    'underline',
    'strike',
    'color',
    'background',
    'font',
    'size',
  };

  /// Replaces [length] characters from [start] with [replacement].
  static Delta replaceRange(
    Delta delta,
    int start,
    int length,
    String replacement, {
    Map<String, dynamic>? attributes,
  }) {
    _checkRange(delta, start, length);
    final change = Delta()
      ..retain(start)
      ..delete(length);
    if (replacement.isNotEmpty) {
      change.insert(
        replacement,
        attributes ?? inlineAttributesAt(delta, start + (length > 0 ? 1 : 0)),
      );
    }
    return delta.compose(change);
  }

  static Delta insertText(
    Delta delta,
    int offset,
    String value, {
    Map<String, dynamic>? attributes,
  }) => replaceRange(delta, offset, 0, value, attributes: attributes);

  static Delta deleteRange(Delta delta, int start, int length) {
    _checkRange(delta, start, length);
    return delta.compose(
      Delta()
        ..retain(start)
        ..delete(length),
    );
  }

  /// Applies [attributes] to a range; a null value removes that attribute.
  static Delta formatRange(
    Delta delta,
    int start,
    int length,
    Map<String, dynamic> attributes,
  ) {
    _checkRange(delta, start, length);
    return delta.compose(
      Delta()
        ..retain(start)
        ..retain(length, attributes),
    );
  }

  /// Links the text of a range to an element (the text itself is unchanged).
  static Delta linkMention(
    Delta delta,
    int start,
    int length,
    String elementId,
    String name,
  ) => formatRange(delta, start, length, {
    RichDocument.mentionKey: RichDocument.mention(elementId, name),
  });

  /// Puts [embed] (an `insert` value such as [RichDocument.divider]) on a
  /// line of its own at [offset], adding a line break before and after it
  /// where the text around it needs one.
  static Delta insertEmbedLine(
    Delta delta,
    int offset,
    Map<String, dynamic> embed,
  ) {
    final plain = text(delta);
    if (offset < 0 || offset > plain.length) {
      throw RangeError.range(offset, 0, plain.length, 'offset');
    }
    final needsBefore = offset > 0 && plain[offset - 1] != '\n';
    final needsAfter = offset >= plain.length || plain[offset] != '\n';
    final change = Delta()..retain(offset);
    if (needsBefore) change.insert('\n');
    change.insert(embed);
    if (needsAfter) change.insert('\n');
    return delta.compose(change);
  }

  /// Every place where [query] occurs. Without [regex] the search ignores
  /// case and accents' case only (plain, literal text); with it, [query] is a
  /// regular expression.
  static List<TextHit> find(
    Delta delta,
    String query, {
    bool caseSensitive = false,
    bool regex = false,
  }) {
    if (query.isEmpty) return const [];
    final plain = text(delta);
    final pattern = RegExp(
      regex ? query : RegExp.escape(query),
      caseSensitive: caseSensitive,
      multiLine: true,
    );
    return [
      for (final match in pattern.allMatches(plain))
        if (match.end > match.start) TextHit(match.start, match.end),
    ];
  }

  /// Replaces every occurrence of [query]; returns the new Delta and how many
  /// were replaced. With [regex], `$1`-style groups are not expanded: the
  /// replacement is literal text.
  static (Delta, int) replaceAll(
    Delta delta,
    String query,
    String replacement, {
    bool caseSensitive = false,
    bool regex = false,
  }) {
    final hits = find(delta, query, caseSensitive: caseSensitive, regex: regex);
    var result = delta;
    // From the end, so earlier offsets stay valid.
    for (final hit in hits.reversed) {
      result = replaceRange(result, hit.start, hit.length, replacement);
    }
    return (result, hits.length);
  }

  /// A few words around [hit], for showing a search result.
  static String snippet(String plain, TextHit hit, {int context = 40}) {
    final from = (hit.start - context).clamp(0, plain.length);
    final to = (hit.end + context).clamp(0, plain.length);
    final body = plain
        .substring(from, to)
        .replaceAll('￼', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${from > 0 ? '…' : ''}$body${to < plain.length ? '…' : ''}';
  }

  static void _checkRange(Delta delta, int start, int length) {
    final size = text(delta).length;
    if (start < 0 || length < 0 || start + length > size) {
      throw RangeError(
        'Range $start+$length is outside the document (length $size)',
      );
    }
  }
}
