import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:markdown/markdown.dart' as md;

import '../markdown_extensions.dart';
import 'rich_document.dart';

/// Reads Markdown (the format chapters used before the rich editor) into a
/// Delta. `[[element:id|Name]]` becomes a mention, `<u>` an underline and
/// `![](gallery/file)` a gallery image when the file is known.
class MarkdownToDelta {
  const MarkdownToDelta({this.galleryId});

  /// Gallery ID of a file name inside `gallery/`, if it is known.
  final String? Function(String file)? galleryId;

  Delta convert(String source) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [_MentionSyntax(), _UnderlineSyntax()],
      encodeHtml: false,
    );
    final nodes = document.parseLines(const LineSplitter().convert(source));
    final writer = _Writer(galleryId);
    writer.blocks(nodes, const _Block());
    final delta = writer.delta;
    return delta.isEmpty ? RichDocument.empty() : delta;
  }
}

class _Block {
  const _Block({this.quote = false, this.list, this.indent = 0});

  final bool quote;
  final String? list;
  final int indent;

  Map<String, dynamic> get attributes => {
    if (list != null) 'list': list,
    if (list != null && indent > 0) 'indent': indent,
    if (list == null && quote) 'blockquote': true,
  };

  _Block copyWith({bool? quote, String? list, int? indent}) => _Block(
    quote: quote ?? this.quote,
    list: list ?? this.list,
    indent: indent ?? this.indent,
  );
}

class _Writer {
  _Writer(this.galleryId);

  final String? Function(String file)? galleryId;
  final delta = Delta();

  void endLine(Map<String, dynamic> attributes) =>
      delta.insert('\n', attributes.isEmpty ? null : attributes);

  void blocks(List<md.Node> nodes, _Block block) {
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.trim().isEmpty) continue;
        inline([node], const {});
        endLine(block.attributes);
        continue;
      }
      final element = node as md.Element;
      final tag = element.tag;
      switch (tag) {
        case 'p':
          inline(element.children ?? const [], const {});
          endLine(block.attributes);
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          inline(element.children ?? const [], const {});
          endLine({'header': int.parse(tag.substring(1))});
        case 'blockquote':
          blocks(element.children ?? const [], block.copyWith(quote: true));
        case 'ul' || 'ol':
          list(element, block, ordered: tag == 'ol');
        case 'pre':
          code(element);
        case 'hr':
          delta.insert(RichDocument.divider());
          endLine(const {});
        default:
          // Tables and other extensions: keep their text as a paragraph.
          final text = element.textContent.trim();
          if (text.isNotEmpty) {
            delta.insert(text.replaceAll('\n', ' '));
            endLine(block.attributes);
          }
      }
    }
  }

  void list(md.Element element, _Block block, {required bool ordered}) {
    final indent = block.list == null ? 0 : block.indent + 1;
    for (final item in element.children ?? const <md.Node>[]) {
      if (item is! md.Element || item.tag != 'li') continue;
      var type = ordered ? 'ordered' : 'bullet';
      final children = <md.Node>[];
      final nested = <md.Element>[];
      for (final child in item.children ?? const <md.Node>[]) {
        if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
          nested.add(child);
        } else if (child is md.Element && child.tag == 'input') {
          type = child.attributes.containsKey('checked')
              ? 'checked'
              : 'unchecked';
        } else if (child is md.Element && child.tag == 'p') {
          children.addAll(child.children ?? const []);
        } else {
          children.add(child);
        }
      }
      inline(children, const {});
      endLine(_Block(list: type, indent: indent).attributes);
      for (final child in nested) {
        list(
          child,
          _Block(list: type, indent: indent),
          ordered: child.tag == 'ol',
        );
      }
    }
  }

  void code(md.Element pre) {
    var text = pre.textContent;
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) delta.insert(line);
      endLine({'code-block': true});
    }
  }

  void inline(List<md.Node> nodes, Map<String, dynamic> attributes) {
    for (final node in nodes) {
      if (node is md.Text) {
        final text = node.text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
        if (text.isNotEmpty) delta.insert(text, _orNull(attributes));
        continue;
      }
      final element = node as md.Element;
      final children = element.children ?? const <md.Node>[];
      switch (element.tag) {
        case 'strong':
          inline(children, {...attributes, 'bold': true});
        case 'em':
          inline(children, {...attributes, 'italic': true});
        case 'del':
          inline(children, {...attributes, 'strike': true});
        case 'u':
          inline(children, {...attributes, 'underline': true});
        case 'code':
          delta.insert(
            element.textContent,
            _orNull({...attributes, 'code': true}),
          );
        case 'a':
          final href = element.attributes['href'];
          inline(children, {
            ...attributes,
            if (href != null && href.isNotEmpty)
              'link': Uri.decodeFull(href).replaceAll(' ', '%20'),
          });
        case 'img':
          image(element.attributes['src'] ?? '');
        case 'br':
          delta.insert(' ', _orNull(attributes));
        case 'mention':
          final id = element.attributes['id'] ?? '';
          final name = element.textContent;
          delta.insert(name, {
            ...attributes,
            RichDocument.mentionKey: RichDocument.mention(id, name),
          });
        case 'input':
          break;
        default:
          inline(children, attributes);
      }
    }
  }

  void image(String src) {
    if (src.isEmpty) return;
    if (src.startsWith('gallery://')) {
      delta.insert(
        RichDocument.galleryImage(src.substring('gallery://'.length)),
      );
      return;
    }
    if (src.startsWith('gallery/')) {
      final id = galleryId?.call(
        Uri.decodeFull(src.substring('gallery/'.length)),
      );
      if (id != null) {
        delta.insert(RichDocument.galleryImage(id));
        return;
      }
    }
    delta.insert({'image': src});
  }

  Map<String, dynamic>? _orNull(Map<String, dynamic> attributes) =>
      attributes.isEmpty ? null : attributes;
}

class _MentionSyntax extends md.InlineSyntax {
  _MentionSyntax() : super(NarrativeLinkExtension.linkPattern.pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final id = match.group(1)!;
    final name = match.group(2) ?? id;
    parser.addNode(md.Element.text('mention', name)..attributes['id'] = id);
    return true;
  }
}

class _UnderlineSyntax extends md.InlineSyntax {
  _UnderlineSyntax() : super(r'<u>(.+?)</u>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final inner = md.InlineParser(match.group(1)!, parser.document).parse();
    parser.addNode(md.Element('u', inner));
    return true;
  }
}
