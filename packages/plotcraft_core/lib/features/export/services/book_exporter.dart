import 'dart:typed_data';

import '../domain/export_book.dart';
import '../domain/export_options.dart';
import 'epub_exporter.dart';
import 'html_exporter.dart';
import 'pdf_exporter.dart';

/// Writes [book] in [format].
Future<Uint8List> exportBook(
  ExportBook book,
  ExportFormat format,
  ExportOptions options,
) async => switch (format) {
  ExportFormat.epub => exportEpub(book, options),
  ExportFormat.html => exportHtml(book, options),
  ExportFormat.pdf => await exportPdf(book, options),
};
