import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/export/domain/export_options.dart';
import 'package:plotcraft_core/features/export/services/book_assembler.dart';
import 'package:plotcraft_core/features/export/services/book_exporter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/project_font.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import '../tool_spec.dart';

/// Regular, bold and italic TrueType fonts of the project, for the PDF.
Future<PdfFonts?> _projectPdfFonts(List<ProjectFont> fonts) async {
  final usable = fonts
      .where((font) => p.extension(font.file).toLowerCase() == '.ttf')
      .toList();
  if (usable.isEmpty) return null;
  final family = usable.first.family;
  final sameFamily = usable.where((font) => font.family == family);
  ProjectFont? styled(bool bold, bool italic) {
    for (final font in sameFamily) {
      final style = font.style.toLowerCase();
      if (style.contains('bold') == bold &&
          style.contains('italic') == italic) {
        return font;
      }
    }
    return null;
  }

  Future<Uint8List?> read(ProjectFont? font) async =>
      font == null ? null : File(font.path).readAsBytes();

  final regular = styled(false, false) ?? sameFamily.first;
  return PdfFonts(
    regular: await File(regular.path).readAsBytes(),
    bold: await read(styled(true, false)),
    italic: await read(styled(false, true)),
    boldItalic: await read(styled(true, true)),
  );
}

List<ToolSpec> exportTools() => [
  ToolSpec(
    name: 'export_book',
    title: 'Export the book',
    description:
        'Saves the manuscript as an EPUB (for Kindle and other e-readers), '
        'a PDF or a single HTML file. Writes to the project\'s exports/ '
        'folder unless output_path is given.',
    kind: ToolKind.write,
    properties: {
      'project': Schema.string(
        description:
            'The project: its id, its folder path or its exact title '
            '(see list_projects).',
      ),
      'format': Schema.string(description: 'epub, pdf or html.'),
      'output_path': Schema.string(
        description:
            'Absolute path of the file to write. Default: '
            '<project>/exports/<title>.<format>.',
      ),
      'chapters': Schema.list(
        description: 'Chapter ids to include (see list_chapters). Default: all.',
        items: Schema.string(),
      ),
      'language': Schema.string(
        description:
            'Language of the file: en, pt or es. Sets the words the file '
            'writes itself, such as "Contents". Default: en.',
      ),
      'include_cover': Schema.bool(description: 'Default true.'),
      'include_toc': Schema.bool(description: 'Default true.'),
    },
    required: ['project', 'format'],
    handler: (call) async {
      final format = ExportFormat.parse(
        call.args.choice('format', ['epub', 'pdf', 'html']),
      )!;
      final story = await call.workspace();
      final options = ExportOptions(
        chapterIds: call.args.optStringList('chapters')?.toSet(),
        includeCover: call.args.boolean('include_cover', defaultValue: true),
        includeToc: call.args.boolean('include_toc', defaultValue: true),
        language: call.args.choice(
          'language',
          ['en', 'pt', 'es'],
          defaultValue: 'en',
        ),
        pdfFonts: format == ExportFormat.pdf
            ? await _projectPdfFonts(await story.fonts())
            : null,
      );
      final book = await BookAssembler().assemble(story.project, options);
      final bytes = await exportBook(book, format, options);

      final requested = call.args.optString('output_path');
      if (requested != null && !p.isAbsolute(requested)) {
        throw const StoryError.validation(
          'Argument "output_path" must be an absolute path.',
        );
      }
      final path =
          requested ??
          p.join(
            story.folder,
            'exports',
            '${_fileName(story.project.title)}.${format.extension}',
          );
      final target = File(path);
      await target.parent.create(recursive: true);
      final temp = File('$path.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(path);
      return {
        'path': path,
        'format': format.name,
        'bytes': bytes.length,
        'chapters': book.chapters.length,
      };
    },
  ),
];

String _fileName(String title) {
  final clean = title
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '')
      .trim();
  return clean.isEmpty ? 'book' : clean;
}
