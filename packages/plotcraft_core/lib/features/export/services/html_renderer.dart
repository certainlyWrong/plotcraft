import 'dart:convert';

import '../domain/export_book.dart';

String escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Markup of the blocks of a chapter, valid both as HTML5 and as XHTML (the
/// EPUB needs well-formed XML).
class HtmlRenderer {
  const HtmlRenderer(this.book, {required this.imageSrc});

  final ExportBook book;

  /// The `src` of an image: a data URI in HTML, a file path in the EPUB.
  final String Function(ExportImage image) imageSrc;

  static String dataUri(ExportImage image) =>
      'data:${image.mimeType};base64,${base64Encode(image.bytes)}';

  String runs(List<ExportRun> runs) {
    final out = StringBuffer();
    for (final run in runs) {
      var html = escapeHtml(run.text);
      if (run.code) html = '<code>$html</code>';
      if (run.bold) html = '<strong>$html</strong>';
      if (run.italic) html = '<em>$html</em>';
      if (run.underline) html = '<u>$html</u>';
      if (run.strike) html = '<s>$html</s>';
      final link = run.link;
      if (link != null && link.isNotEmpty) {
        html = '<a href="${escapeHtml(link)}">$html</a>';
      }
      out.write(html);
    }
    return out.toString();
  }

  static String _alignAttr(String? align) =>
      align == null ? '' : ' class="align-$align"';

  String blocks(List<ExportBlock> blocks) {
    final out = StringBuffer();
    String? openList;
    void closeList() {
      if (openList != null) out.writeln('</$openList>');
      openList = null;
    }

    for (final block in blocks) {
      if (block is ListItemBlock) {
        final tag = block.ordered ? 'ol' : 'ul';
        if (openList != tag) {
          closeList();
          out.writeln('<$tag>');
          openList = tag;
        }
        final cls = block.indent > 0 ? ' class="indent-${block.indent}"' : '';
        out.writeln('<li$cls>${runs(block.runs)}</li>');
        continue;
      }
      closeList();
      switch (block) {
        case ParagraphBlock():
          out.writeln('<p${_alignAttr(block.align)}>${runs(block.runs)}</p>');
        case HeadingBlock():
          final level = block.level + 1; // h1 is the chapter title
          out.writeln(
            '<h$level${_alignAttr(block.align)}>${runs(block.runs)}</h$level>',
          );
        case QuoteBlock():
          out.writeln('<blockquote><p>${runs(block.runs)}</p></blockquote>');
        case CodeBlock():
          out.writeln('<pre><code>${escapeHtml(block.text)}</code></pre>');
        case DividerBlock():
          out.writeln('<hr/>');
        case ImageBlock():
          final image = book.images[block.imageId];
          if (image == null) break;
          out.writeln(
            '<figure class="align-${block.align ?? 'center'}">'
            '<img src="${escapeHtml(imageSrc(image))}" alt=""/></figure>',
          );
        case ListItemBlock():
          break;
      }
    }
    closeList();
    return out.toString();
  }

  static String css(double fontSize, {bool standalone = false}) =>
      '''
${standalone ? 'html { background: #fbf8f3; color: #222; }\n@media (prefers-color-scheme: dark) { html { background: #16161a; color: #e6e1d8; } }\nbody { max-width: 680px; margin: 0 auto; padding: 2.5em 1.2em 4em; }' : ''}
body { font-family: Georgia, "Times New Roman", serif; font-size: ${fontSize}pt; line-height: 1.7; }
h1, h2, h3, h4 { line-height: 1.25; }
h1 { font-size: 1.7em; margin: 2em 0 1em; }
p { margin: 0 0 0.9em; text-align: justify; hyphens: auto; }
p.align-center, h2.align-center, h3.align-center, h4.align-center { text-align: center; }
p.align-right, h2.align-right, h3.align-right, h4.align-right { text-align: right; }
.align-justify { text-align: justify; }
blockquote { margin: 1em 1.5em; font-style: italic; opacity: 0.85; }
pre { white-space: pre-wrap; font-size: 0.85em; }
hr { border: 0; text-align: center; margin: 1.6em 0; }
hr::after { content: "* * *"; letter-spacing: 0.5em; }
figure { margin: 1.2em 0; text-align: center; }
figure.align-left { text-align: left; }
figure.align-right { text-align: right; }
img { max-width: 100%; height: auto; }
li.indent-1 { margin-left: 1.5em; }
li.indent-2 { margin-left: 3em; }
li.indent-3 { margin-left: 4.5em; }
.title-page { text-align: center; margin: 25vh 0 3em; }
.title-page h1 { font-size: 2.4em; margin: 0 0 0.3em; }
.title-page .subtitle { font-size: 1.3em; font-style: italic; margin: 0 0 1.5em; }
.title-page .author { font-size: 1.1em; }
.cover { text-align: center; margin: 0; }
nav ol { list-style: none; padding-left: 0; }
nav li { margin: 0.4em 0; }
''';
}
