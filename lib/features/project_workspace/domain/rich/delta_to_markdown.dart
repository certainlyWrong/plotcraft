import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'rich_document.dart';

/// Turns a manuscript Delta into Markdown. The Markdown is a readable copy for
/// other tools: structure (headings, lists, quotes, code, links, emphasis),
/// element mentions as `[[element:id|Name]]` and images, but not colors, fonts
/// or alignment, which have no Markdown form and stay in the Delta.
class DeltaToMarkdown {
  const DeltaToMarkdown({this.galleryFile});

  /// File name (inside `gallery/`) of a gallery image ID, if it is known.
  final String? Function(String id)? galleryFile;

  String convert(Delta delta) {
    final lines = _splitLines(delta);
    final out = StringBuffer();
    final orderedCounters = <int, int>{};
    String? previousKind;
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final kind = line.kind;
      if (kind == 'code') {
        final block = <_Line>[];
        while (index < lines.length && lines[index].kind == 'code') {
          block.add(lines[index++]);
        }
        _separate(out, previousKind, 'code');
        final text = block.map((l) => l.plain).join('\n');
        final fence = text.contains('```') ? '````' : '```';
        out
          ..writeln(fence)
          ..writeln(text)
          ..writeln(fence);
        previousKind = 'code';
        orderedCounters.clear();
        continue;
      }
      index++;
      final body = line.isDivider ? '---' : _inline(line);
      if (body.isEmpty && !line.isDivider) {
        // Empty paragraphs have no Markdown form; the Delta keeps them.
        continue;
      }
      var text = body;
      switch (kind) {
        case 'header':
          text = '${'#' * line.header} $body';
        case 'quote':
          text = '> $body';
        case 'bullet':
        case 'ordered':
        case 'checked':
        case 'unchecked':
          final pad = '    ' * line.indent;
          orderedCounters.removeWhere((level, _) => level > line.indent);
          final marker = switch (kind) {
            'ordered' =>
              '${orderedCounters[line.indent] = (orderedCounters[line.indent] ?? 0) + 1}.',
            'checked' => '- [x]',
            'unchecked' => '- [ ]',
            _ => '-',
          };
          text = '$pad$marker $body';
        default:
          text = line.isDivider ? '---' : _escapeLineStart(body);
      }
      if (kind != 'ordered') orderedCounters.clear();
      _separate(out, previousKind, kind);
      out.writeln(text);
      previousKind = kind;
    }
    return out.toString();
  }

  /// Blank line between blocks, except inside one list or one quote.
  void _separate(StringBuffer out, String? previous, String kind) {
    if (previous == null) return;
    final sameList =
        const {'bullet', 'ordered', 'checked', 'unchecked'}.contains(kind) &&
        const {'bullet', 'ordered', 'checked', 'unchecked'}.contains(previous);
    if (sameList) return;
    if (kind == 'quote' && previous == 'quote') {
      out.writeln('>');
      return;
    }
    out.writeln();
  }

  // --- Lines ----------------------------------------------------------------

  List<_Line> _splitLines(Delta delta) {
    final lines = <_Line>[];
    var current = <_Segment>[];
    for (final op in delta.toList()) {
      final data = op.data;
      final attributes = op.attributes ?? const <String, dynamic>{};
      if (data is String) {
        final parts = data.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            current.add(_Segment(parts[i], attributes));
          }
          if (i < parts.length - 1) {
            lines.add(_Line(current, attributes));
            current = <_Segment>[];
          }
        }
      } else if (data is Map) {
        current.add(_Segment(null, attributes, embed: data));
      }
    }
    if (current.isNotEmpty) lines.add(_Line(current, const {}));
    return lines;
  }

  // --- Inline ---------------------------------------------------------------

  String _inline(_Line line) {
    final merged = <_Segment>[];
    for (final segment in line.segments) {
      if (merged.isNotEmpty && merged.last.canMergeWith(segment)) {
        merged.last = merged.last.merge(segment);
      } else {
        merged.add(segment);
      }
    }
    return merged.map(_segment).join();
  }

  String _segment(_Segment segment) {
    final embed = segment.embed;
    if (embed != null) return _embed(embed);
    final attrs = segment.attributes;
    final text = segment.text!;
    final mention = attrs[RichDocument.mentionKey];
    if (attrs['code'] == true) return _wrapCode(text);
    var result = _escapeInline(text);
    if (mention is Map && mention['id'] is String) {
      // The marker is not escaped: it is Markdown syntax of its own.
      final name = text.replaceAll(RegExp(r'[\]\r\n|]'), ' ');
      result = '[[element:${mention['id']}|$name]]';
    }
    if (attrs['bold'] == true) result = _wrap(result, '**');
    if (attrs['italic'] == true) result = _wrap(result, '*');
    if (attrs['strike'] == true) result = _wrap(result, '~~');
    if (attrs['underline'] == true) {
      result = _wrapHtml(result, 'u');
    }
    final link = attrs['link'];
    if (link is String && link.isNotEmpty) {
      result =
          '[$result](${link.replaceAll(')', '%29').replaceAll(' ', '%20')})';
    }
    return result;
  }

  String _embed(Map embed) {
    if (embed['image'] is String) return '![](${embed['image']})';
    final gallery = RichDocument.readGalleryImage(embed);
    if (gallery != null) {
      final id = gallery['id'] as String;
      final file = galleryFile?.call(id);
      return file == null
          ? '![](gallery://$id)'
          : '![](gallery/${Uri.encodeFull(file)})';
    }
    return '';
  }

  /// Wraps [text] in [marker], keeping edge spaces outside the markers.
  String _wrap(String text, String marker) {
    final match = RegExp(r'^(\s*)(.*?)(\s*)$', dotAll: true).firstMatch(text)!;
    if (match.group(2)!.isEmpty) return text;
    return '${match.group(1)}$marker${match.group(2)}$marker${match.group(3)}';
  }

  String _wrapHtml(String text, String tag) {
    final match = RegExp(r'^(\s*)(.*?)(\s*)$', dotAll: true).firstMatch(text)!;
    if (match.group(2)!.isEmpty) return text;
    return '${match.group(1)}<$tag>${match.group(2)}</$tag>${match.group(3)}';
  }

  String _wrapCode(String text) {
    final longest = RegExp(r'`+')
        .allMatches(text)
        .fold<int>(
          0,
          (max, m) => m.group(0)!.length > max ? m.group(0)!.length : max,
        );
    final fence = '`' * (longest + 1);
    final padded = text.startsWith('`') || text.endsWith('`')
        ? ' $text '
        : text;
    return '$fence$padded$fence';
  }

  /// Escapes characters that Markdown would read as formatting.
  String _escapeInline(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      switch (c) {
        case r'\':
        case '`':
        case '*':
        case '[':
        case ']':
        case '<':
        case '~':
          buffer.write('\\$c');
        case '_':
          final before = i > 0 ? text[i - 1] : ' ';
          final after = i < text.length - 1 ? text[i + 1] : ' ';
          final word = RegExp(r'[\p{L}\p{N}]', unicode: true);
          buffer.write(
            word.hasMatch(before) && word.hasMatch(after) ? c : '\\$c',
          );
        default:
          buffer.write(c);
      }
    }
    return buffer.toString();
  }

  /// A paragraph that starts like a heading, list or quote must not become one.
  String _escapeLineStart(String text) {
    final ordered = RegExp(r'^(\d+)([.)])(\s)').firstMatch(text);
    if (ordered != null) {
      // Only the punctuation can be escaped; "\1" is not an escape.
      return '${ordered.group(1)}\\${ordered.group(2)}${text.substring(ordered.end - 1)}';
    }
    if (RegExp(r'^(#{1,6}\s|>|[-+]\s|---|===|```)').hasMatch(text)) {
      return '\\$text';
    }
    return text;
  }
}

class _Segment {
  _Segment(this.text, this.attributes, {this.embed});

  String? text;
  final Map<String, dynamic> attributes;
  final Map? embed;

  bool canMergeWith(_Segment other) =>
      embed == null &&
      other.embed == null &&
      attributes.length == other.attributes.length &&
      attributes.entries.every(
        (e) => other.attributes[e.key].toString() == e.value.toString(),
      );

  _Segment merge(_Segment other) =>
      _Segment('${text!}${other.text!}', attributes);
}

class _Line {
  _Line(this.segments, this.attributes);

  final List<_Segment> segments;

  /// Attributes of the line's newline: its block formatting.
  final Map<String, dynamic> attributes;

  String get plain => segments.map((s) => s.text ?? '').join();

  bool get isDivider =>
      segments.length == 1 &&
      segments.first.embed != null &&
      RichDocument.isDivider(segments.first.embed);

  int get header => (attributes['header'] as int?) ?? 0;

  int get indent => (attributes['indent'] as int?) ?? 0;

  String get kind {
    if (attributes['code-block'] != null && attributes['code-block'] != false) {
      return 'code';
    }
    if (header > 0) return 'header';
    if (attributes['blockquote'] == true) return 'quote';
    return switch (attributes['list']) {
      'bullet' => 'bullet',
      'ordered' => 'ordered',
      'checked' => 'checked',
      'unchecked' => 'unchecked',
      _ => 'paragraph',
    };
  }
}
