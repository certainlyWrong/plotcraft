import 'dart:typed_data';

enum ExportFormat {
  epub('epub', 'application/epub+zip'),
  pdf('pdf', 'application/pdf'),
  html('html', 'text/html');

  const ExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;

  static ExportFormat? parse(String? value) {
    for (final format in values) {
      if (format.name == value?.toLowerCase()) return format;
    }
    return null;
  }
}

/// TrueType fonts embedded in a PDF. Without them the PDF uses Helvetica,
/// which only covers Latin-1 characters.
class PdfFonts {
  const PdfFonts({
    required this.regular,
    this.bold,
    this.italic,
    this.boldItalic,
  });

  final Uint8List regular;
  final Uint8List? bold;
  final Uint8List? italic;
  final Uint8List? boldItalic;
}

class ExportOptions {
  const ExportOptions({
    this.chapterIds,
    this.includeCover = true,
    this.includeToc = true,
    this.language = 'en',
    this.fontSize = 12,
    this.pdfFonts,
  });

  /// Chapters to export, in book order; null exports all of them.
  final Set<String>? chapterIds;
  final bool includeCover;
  final bool includeToc;

  /// BCP 47 code written in the file (`en`, `pt`, `es`).
  final String language;

  /// Body text size in points (PDF) and in `pt` units (HTML, EPUB).
  final double fontSize;
  final PdfFonts? pdfFonts;
}
