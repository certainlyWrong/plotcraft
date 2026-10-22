import 'dart:typed_data';

/// Inline piece of text with one set of styles.
class ExportRun {
  const ExportRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? link;
}

sealed class ExportBlock {
  const ExportBlock();
}

class ParagraphBlock extends ExportBlock {
  const ParagraphBlock(this.runs, {this.align});

  final List<ExportRun> runs;

  /// `center`, `right` or `justify`; null is the default.
  final String? align;
}

class HeadingBlock extends ExportBlock {
  const HeadingBlock(this.level, this.runs, {this.align});

  /// 1 to 3.
  final int level;
  final List<ExportRun> runs;
  final String? align;
}

class ListItemBlock extends ExportBlock {
  const ListItemBlock(this.runs, {this.ordered = false, this.indent = 0});

  final List<ExportRun> runs;
  final bool ordered;
  final int indent;
}

class QuoteBlock extends ExportBlock {
  const QuoteBlock(this.runs);

  final List<ExportRun> runs;
}

class CodeBlock extends ExportBlock {
  const CodeBlock(this.text);

  final String text;
}

class DividerBlock extends ExportBlock {
  const DividerBlock();
}

class ImageBlock extends ExportBlock {
  const ImageBlock(this.imageId, {this.width, this.align});

  final String imageId;

  /// Width in logical pixels chosen in the editor, if any.
  final int? width;
  final String? align;
}

class ExportImage {
  const ExportImage({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

class ExportChapter {
  const ExportChapter({
    required this.id,
    required this.title,
    required this.blocks,
  });

  final String id;
  final String title;
  final List<ExportBlock> blocks;
}

class ExportMetadata {
  const ExportMetadata({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.author = '',
    this.description = '',
    this.genre = '',
    this.tags = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String description;
  final String genre;
  final List<String> tags;
}

class ExportBook {
  const ExportBook({
    required this.metadata,
    required this.chapters,
    this.images = const {},
    this.cover,
  });

  final ExportMetadata metadata;
  final List<ExportChapter> chapters;

  /// Gallery images used by the chapters, by gallery id.
  final Map<String, ExportImage> images;
  final ExportImage? cover;
}
