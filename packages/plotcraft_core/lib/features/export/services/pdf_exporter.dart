import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/export_book.dart';
import '../domain/export_options.dart';
import 'export_strings.dart';

/// A PDF with cover, title page, table of contents (with links and
/// bookmarks) and every chapter starting on a new page.
///
/// Pass [ExportOptions.pdfFonts] for full Unicode text; without them the PDF
/// uses Helvetica and replaces characters outside Latin-1 with look-alikes.
Future<Uint8List> exportPdf(ExportBook book, ExportOptions options) async {
  final strings = ExportStrings.of(options.language);
  final meta = book.metadata;
  final fonts = options.pdfFonts;
  final author = meta.author.trim().isEmpty
      ? strings.unknownAuthor
      : meta.author.trim();

  String clean(String text) => fonts == null ? _latin1(text) : text;

  pw.Font? font(Uint8List? bytes) =>
      bytes == null ? null : pw.Font.ttf(ByteData.sublistView(bytes));
  final theme = fonts == null
      ? pw.ThemeData.withFont(
          base: pw.Font.times(),
          bold: pw.Font.timesBold(),
          italic: pw.Font.timesItalic(),
          boldItalic: pw.Font.timesBoldItalic(),
        )
      : () {
          final base = font(fonts.regular)!;
          return pw.ThemeData.withFont(
            base: base,
            bold: font(fonts.bold) ?? base,
            italic: font(fonts.italic) ?? base,
            boldItalic: font(fonts.boldItalic) ?? font(fonts.bold) ?? base,
          );
        }();

  final size = options.fontSize;
  final doc = pw.Document(
    title: meta.title,
    author: author,
    subject: meta.description,
    keywords: meta.tags.join(', '),
    creator: 'Plotcraft',
    theme: theme,
  );
  final format = PdfPageFormat.a5.copyWith(
    marginLeft: 56,
    marginRight: 56,
    marginTop: 60,
    marginBottom: 64,
  );
  pw.ImageProvider? decode(ExportImage image) {
    if (image.mimeType != 'image/png' && image.mimeType != 'image/jpeg') {
      return null;
    }
    try {
      return pw.MemoryImage(image.bytes);
    } catch (_) {
      return null;
    }
  }

  final cover = options.includeCover && book.cover != null
      ? decode(book.cover!)
      : null;
  if (cover != null) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(cover, fit: pw.BoxFit.contain)),
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (_) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              clean(meta.title),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: size * 2.3,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (meta.subtitle.trim().isNotEmpty) ...[
              pw.SizedBox(height: size),
              pw.Text(
                clean(meta.subtitle.trim()),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: size * 1.3,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
            pw.SizedBox(height: size * 3),
            pw.Text(
              clean('${strings.by} $author'),
              style: pw.TextStyle(fontSize: size * 1.1),
            ),
          ],
        ),
      ),
    ),
  );

  if (options.includeToc && book.chapters.length > 1) {
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              clean(strings.contents),
              style: pw.TextStyle(
                fontSize: size * 1.6,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: size * 1.2),
            for (var i = 0; i < book.chapters.length; i++)
              pw.Link(
                destination: 'chapter-$i',
                child: pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: size * 0.5),
                  child: pw.Text(
                    clean(book.chapters[i].title),
                    style: pw.TextStyle(fontSize: size),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  for (var i = 0; i < book.chapters.length; i++) {
    final chapter = book.chapters[i];
    final widgets = <pw.Widget>[
      pw.Outline(
        name: 'chapter-$i',
        title: clean(chapter.title),
        child: pw.Padding(
          padding: pw.EdgeInsets.only(bottom: size * 1.5, top: size),
          child: pw.Text(
            clean(chapter.title),
            style: pw.TextStyle(
              fontSize: size * 1.6,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
      ..._blocks(chapter.blocks, book, size, clean, decode, fonts != null),
    ];
    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (_) => widgets,
        footer: (context) => pw.Center(
          child: pw.Text(
            '${context.pageNumber}',
            style: pw.TextStyle(fontSize: size * 0.8),
          ),
        ),
      ),
    );
  }

  return doc.save();
}

List<pw.Widget> _blocks(
  List<ExportBlock> blocks,
  ExportBook book,
  double size,
  String Function(String) clean,
  pw.ImageProvider? Function(ExportImage) decode,
  bool unicode,
) {
  pw.TextAlign? align(String? value) => switch (value) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    'justify' => pw.TextAlign.justify,
    _ => null,
  };

  pw.Widget rich(
    List<ExportRun> runs, {
    pw.TextAlign? textAlign,
    double? fontSize,
    pw.FontWeight? weight,
    pw.FontStyle? style,
  }) => pw.RichText(
    textAlign: textAlign ?? pw.TextAlign.justify,
    text: pw.TextSpan(
      style: pw.TextStyle(
        fontSize: fontSize ?? size,
        lineSpacing: size * 0.5,
        fontWeight: weight,
        fontStyle: style,
      ),
      children: [
        for (final run in runs)
          pw.TextSpan(
            text: clean(run.text),
            annotation: run.link == null || run.link!.isEmpty
                ? null
                : pw.AnnotationUrl(run.link!),
            style: pw.TextStyle(
              fontWeight: run.bold ? pw.FontWeight.bold : null,
              fontStyle: run.italic ? pw.FontStyle.italic : null,
              decoration: run.underline
                  ? pw.TextDecoration.underline
                  : run.strike
                  ? pw.TextDecoration.lineThrough
                  : null,
              color: run.link == null ? null : PdfColors.blue800,
            ),
          ),
      ],
    ),
  );

  final out = <pw.Widget>[];
  var number = 0;
  for (final block in blocks) {
    if (block is! ListItemBlock) number = 0;
    switch (block) {
      case ParagraphBlock():
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: size * 0.7),
            child: rich(block.runs, textAlign: align(block.align)),
          ),
        );
      case HeadingBlock():
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(top: size * 0.6, bottom: size * 0.6),
            child: rich(
              block.runs,
              textAlign: align(block.align) ?? pw.TextAlign.left,
              fontSize: size * (1.5 - 0.15 * block.level),
              weight: pw.FontWeight.bold,
            ),
          ),
        );
      case ListItemBlock():
        number = block.ordered ? number + 1 : 0;
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(
              left: size * 1.2 * (block.indent + 1),
              bottom: size * 0.3,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: size * 1.6,
                  child: pw.Text(
                    block.ordered ? '$number.' : (unicode ? '•' : '-'),
                    style: pw.TextStyle(fontSize: size),
                  ),
                ),
                pw.Expanded(
                  child: rich(block.runs, textAlign: pw.TextAlign.left),
                ),
              ],
            ),
          ),
        );
      case QuoteBlock():
        out.add(
          pw.Container(
            margin: pw.EdgeInsets.only(left: size, bottom: size * 0.7),
            padding: pw.EdgeInsets.only(left: size),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey500, width: 1.5),
              ),
            ),
            child: rich(block.runs, style: pw.FontStyle.italic),
          ),
        );
      case CodeBlock():
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: size * 0.7),
            child: pw.Text(
              clean(block.text),
              style: pw.TextStyle(
                fontSize: size * 0.85,
                font: unicode ? null : pw.Font.courier(),
              ),
            ),
          ),
        );
      case DividerBlock():
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: size),
            child: pw.Center(
              child: pw.Text('*  *  *', style: pw.TextStyle(fontSize: size)),
            ),
          ),
        );
      case ImageBlock():
        final source = book.images[block.imageId];
        final image = source == null ? null : decode(source);
        if (image == null) break;
        out.add(
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: size * 0.6),
            child: pw.Center(
              child: pw.Container(
                constraints: const pw.BoxConstraints(maxHeight: 360),
                child: pw.Image(image, fit: pw.BoxFit.scaleDown),
              ),
            ),
          ),
        );
    }
  }
  return out;
}

/// Replaces what Helvetica/Times cannot draw (anything outside Latin-1) with
/// the closest plain characters.
String _latin1(String text) {
  const map = {
    '‘': "'",
    '’': "'",
    '‚': ',',
    '“': '"',
    '”': '"',
    '„': '"',
    '–': '-',
    '—': '-',
    '…': '...',
    '•': '-',
    '€': 'EUR',
    ' ': ' ',
  };
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    out.write(rune < 256 ? char : map[char] ?? '?');
  }
  return out.toString();
}
