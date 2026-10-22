import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../../project_workspace/domain/rich/rich_document.dart';
import '../domain/export_book.dart';

/// Turns a manuscript Delta into export blocks. Colors and fonts are left out
/// on purpose: e-readers and printed pages work better with their own.
List<ExportBlock> deltaToBlocks(Delta delta, Set<String> usedImages) {
  final blocks = <ExportBlock>[];
  var runs = <ExportRun>[];
  var codeLines = <String>[];

  void flushCode() {
    if (codeLines.isEmpty) return;
    blocks.add(CodeBlock(codeLines.join('\n')));
    codeLines = [];
  }

  void endLine(Map<String, dynamic>? attrs) {
    final line = runs;
    runs = [];
    final isCode = attrs?['code-block'] != null;
    if (!isCode) flushCode();
    final empty = line.every((run) => run.text.trim().isEmpty);
    if (isCode) {
      codeLines.add(line.map((run) => run.text).join());
      return;
    }
    if (empty) return;
    final align = attrs?['align'] as String?;
    final header = attrs?['header'];
    final list = attrs?['list'];
    if (header is int) {
      blocks.add(HeadingBlock(header.clamp(1, 3), line, align: align));
    } else if (list != null) {
      blocks.add(
        ListItemBlock(
          line,
          ordered: list == 'ordered',
          indent: (attrs?['indent'] as int?) ?? 0,
        ),
      );
    } else if (attrs?['blockquote'] != null) {
      blocks.add(QuoteBlock(line));
    } else {
      blocks.add(ParagraphBlock(line, align: align));
    }
  }

  void flushInline() {
    if (runs.any((run) => run.text.trim().isNotEmpty)) endLine(null);
    runs = [];
  }

  for (final op in delta.toList()) {
    final data = op.data;
    final attrs = op.attributes;
    if (data is String) {
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          runs.add(
            ExportRun(
              parts[i],
              bold: attrs?['bold'] == true,
              italic: attrs?['italic'] == true,
              underline: attrs?['underline'] == true,
              strike: attrs?['strike'] == true,
              code: attrs?['code'] == true,
              link: attrs?['link'] as String?,
            ),
          );
        }
        if (i < parts.length - 1) endLine(attrs);
      }
    } else {
      final image = RichDocument.readGalleryImage(data);
      if (image != null) {
        flushInline();
        flushCode();
        final id = image['id'] as String;
        usedImages.add(id);
        blocks.add(
          ImageBlock(
            id,
            width: (image['width'] as num?)?.round(),
            align: image['align'] as String?,
          ),
        );
      } else if (RichDocument.isDivider(data)) {
        flushInline();
        flushCode();
        blocks.add(const DividerBlock());
      }
    }
  }
  flushInline();
  flushCode();
  return blocks;
}
