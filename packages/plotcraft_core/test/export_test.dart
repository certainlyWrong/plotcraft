import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:plotcraft_core/features/export/domain/export_book.dart';
import 'package:plotcraft_core/features/export/domain/export_options.dart';
import 'package:plotcraft_core/features/export/services/book_assembler.dart';
import 'package:plotcraft_core/features/export/services/book_exporter.dart';
import 'package:plotcraft_core/features/export/services/delta_blocks.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';
import 'package:test/test.dart';

// 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

ExportBook _book() => ExportBook(
  metadata: const ExportMetadata(
    id: 'p1',
    title: 'The <Book> & more',
    author: 'Ana',
    description: 'A story',
    genre: 'Fantasy',
    tags: ['dragons'],
  ),
  chapters: [
    const ExportChapter(
      id: 'c1',
      title: 'One',
      blocks: [
        ParagraphBlock([
          ExportRun('Hello “world” — '),
          ExportRun('bold', bold: true),
        ]),
        HeadingBlock(1, [ExportRun('Sub')]),
        ListItemBlock([ExportRun('a')]),
        ListItemBlock([ExportRun('b')]),
        DividerBlock(),
        ImageBlock('g_1'),
      ],
    ),
    const ExportChapter(
      id: 'c2',
      title: 'Two',
      blocks: [
        ParagraphBlock([ExportRun('Second')]),
      ],
    ),
  ],
  images: {
    'g_1': ExportImage(
      id: 'g_1',
      fileName: 'pic.png',
      mimeType: 'image/png',
      bytes: _png,
    ),
  },
  cover: ExportImage(
    id: 'cover',
    fileName: 'cover.png',
    mimeType: 'image/png',
    bytes: _png,
  ),
);

void main() {
  test('deltaToBlocks maps lines, styles and embeds', () {
    final delta = Delta()
      ..insert('Title')
      ..insert('\n', {'header': 1})
      ..insert('plain ')
      ..insert('strong', {'bold': true})
      ..insert('\n')
      ..insert('item')
      ..insert('\n', {'list': 'bullet'})
      ..insert(RichDocument.galleryImage('g_9'))
      ..insert('\n')
      ..insert(RichDocument.divider())
      ..insert('\n')
      ..insert('\n')
      ..insert('quote')
      ..insert('\n', {'blockquote': true});
    final used = <String>{};
    final blocks = deltaToBlocks(delta, used);
    expect(blocks.map((b) => b.runtimeType.toString()), [
      'HeadingBlock',
      'ParagraphBlock',
      'ListItemBlock',
      'ImageBlock',
      'DividerBlock',
      'QuoteBlock',
    ]);
    expect(used, {'g_9'});
    final paragraph = blocks[1] as ParagraphBlock;
    expect(paragraph.runs.last.bold, isTrue);
  });

  test('HTML is self-contained and escaped', () async {
    final bytes = await exportBook(
      _book(),
      ExportFormat.html,
      const ExportOptions(),
    );
    final html = utf8.decode(bytes);
    expect(html, contains('<title>The &lt;Book&gt; &amp; more</title>'));
    expect(html, contains('<strong>bold</strong>'));
    expect(html, contains('<ul>'));
    expect(html, contains('data:image/png;base64,'));
    expect(html, contains('href="#c1"'));
  });

  test('EPUB has mimetype first, stored, and a consistent manifest', () async {
    final bytes = await exportBook(
      _book(),
      ExportFormat.epub,
      const ExportOptions(language: 'pt'),
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.first.name, 'mimetype');
    expect(utf8.decode(archive.first.content), 'application/epub+zip');
    final names = archive.map((f) => f.name).toSet();
    final opf = utf8.decode(
      archive.findFile('OEBPS/content.opf')!.content as List<int>,
    );
    final hrefs = RegExp(
      r'<item [^>]*href="([^"]+)"',
    ).allMatches(opf).map((m) => m.group(1)!);
    expect(hrefs, isNotEmpty);
    for (final href in hrefs) {
      expect(names, contains('OEBPS/$href'));
    }
    expect(opf, contains('<dc:language>pt</dc:language>'));
    expect(opf, contains('<dc:subject>Fantasy</dc:subject>'));
    expect(opf, contains('properties="cover-image"'));
    final ids = RegExp(r'idref="([^"]+)"').allMatches(opf);
    expect(ids.length, 4); // cover, title, two chapters
  });

  test('PDF is produced with and without cover', () async {
    final bytes = await exportBook(
      _book(),
      ExportFormat.pdf,
      const ExportOptions(),
    );
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    final plain = await exportBook(
      _book(),
      ExportFormat.pdf,
      const ExportOptions(includeCover: false, includeToc: false),
    );
    expect(plain.length, isNot(bytes.length));
  });

  test('assembler exports a real project and honors chapter choice', () async {
    final temp = await Directory.systemTemp.createTemp('plotcraft-export-');
    addTearDown(() => temp.delete(recursive: true));
    final project = await ProjectCreationService().create(
      const ProjectMetadataInput(
        title: 'Exported',
        subtitle: '',
        author: 'Me',
        description: '',
        genre: '',
        tags: [],
        coverIndex: 0,
      ),
      temp.path,
    );
    final workspace = await StoryWorkspace.open(project);
    final first = (await workspace.chapters()).first;
    await workspace.writeChapter(
      first.id,
      Delta()..insert('Once upon a time.\n'),
    );
    final book = await BookAssembler().assemble(
      workspace.project,
      const ExportOptions(),
    );
    expect(book.chapters, hasLength(1));
    expect(
      (book.chapters.single.blocks.single as ParagraphBlock).runs.single.text,
      'Once upon a time.',
    );
    await expectLater(
      BookAssembler().assemble(
        workspace.project,
        const ExportOptions(chapterIds: {'nope'}),
      ),
      throwsA(isA<Object>()),
    );
  });
}
