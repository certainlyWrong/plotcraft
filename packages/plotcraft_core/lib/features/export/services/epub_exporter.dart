import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../domain/export_book.dart';
import '../domain/export_options.dart';
import 'export_strings.dart';
import 'html_renderer.dart';

/// An EPUB 3 file (with an NCX table of contents for older readers). Kindle
/// accepts it through "Send to Kindle".
Uint8List exportEpub(ExportBook book, ExportOptions options, {DateTime? now}) {
  final strings = ExportStrings.of(options.language);
  final meta = book.metadata;
  final author = meta.author.trim().isEmpty
      ? strings.unknownAuthor
      : meta.author.trim();
  final modified = (now ?? DateTime.now())
      .toUtc()
      .toIso8601String()
      .replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

  String imagePath(ExportImage image) =>
      'images/${image.id}${p.extension(image.fileName).toLowerCase()}';

  final renderer = HtmlRenderer(book, imageSrc: imagePath);
  final archive = Archive();
  void add(String name, String content) =>
      archive.addFile(ArchiveFile.string('OEBPS/$name', content));

  // The first entry must be `mimetype`, stored without compression.
  final mimetype = utf8.encode('application/epub+zip');
  archive.addFile(
    ArchiveFile.noCompress('mimetype', mimetype.length, mimetype),
  );
  archive.addFile(
    ArchiveFile.string(
      'META-INF/container.xml',
      '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
    ),
  );

  String page(String title, String body) =>
      '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="${escapeHtml(options.language)}" xml:lang="${escapeHtml(options.language)}">
<head>
<meta charset="utf-8"/>
<title>${escapeHtml(title)}</title>
<link rel="stylesheet" type="text/css" href="style.css"/>
</head>
<body>
$body</body>
</html>
''';

  add('style.css', HtmlRenderer.css(options.fontSize));

  final manifest = StringBuffer();
  final spine = StringBuffer();
  void item(String id, String href, String type, {String? properties}) {
    manifest.writeln(
      '    <item id="$id" href="$href" media-type="$type"'
      '${properties == null ? '' : ' properties="$properties"'}/>',
    );
  }

  item('css', 'style.css', 'text/css');
  item('nav', 'nav.xhtml', 'application/xhtml+xml', properties: 'nav');
  item('ncx', 'toc.ncx', 'application/x-dtbncx+xml');

  final cover = options.includeCover ? book.cover : null;
  if (cover != null) {
    final path = 'images/cover${p.extension(cover.fileName).toLowerCase()}';
    archive.addFile(ArchiveFile.bytes('OEBPS/$path', cover.bytes));
    item('cover-image', path, cover.mimeType, properties: 'cover-image');
    add(
      'cover.xhtml',
      page(
        meta.title,
        '<p class="cover"><img src="$path" alt="${escapeHtml(meta.title)}"/></p>\n',
      ),
    );
    item('cover', 'cover.xhtml', 'application/xhtml+xml');
    spine.writeln('    <itemref idref="cover" linear="yes"/>');
  }

  final titleBody = StringBuffer()
    ..writeln('<header class="title-page">')
    ..writeln('<h1>${escapeHtml(meta.title)}</h1>');
  if (meta.subtitle.trim().isNotEmpty) {
    titleBody.writeln(
      '<p class="subtitle">${escapeHtml(meta.subtitle.trim())}</p>',
    );
  }
  titleBody
    ..writeln(
      '<p class="author">${escapeHtml(strings.by)} ${escapeHtml(author)}</p>',
    )
    ..writeln('</header>');
  add('title.xhtml', page(meta.title, titleBody.toString()));
  item('title', 'title.xhtml', 'application/xhtml+xml');
  spine.writeln('    <itemref idref="title"/>');

  for (final image in book.images.values) {
    final path = imagePath(image);
    archive.addFile(ArchiveFile.bytes('OEBPS/$path', image.bytes));
    item('img-${image.id}', path, image.mimeType);
  }

  final navItems = StringBuffer();
  final ncxPoints = StringBuffer();
  for (var i = 0; i < book.chapters.length; i++) {
    final chapter = book.chapters[i];
    final href = 'chapter_${i + 1}.xhtml';
    add(
      href,
      page(
        chapter.title,
        '<h1>${escapeHtml(chapter.title)}</h1>\n${renderer.blocks(chapter.blocks)}',
      ),
    );
    item('c${i + 1}', href, 'application/xhtml+xml');
    spine.writeln('    <itemref idref="c${i + 1}"/>');
    navItems.writeln(
      '      <li><a href="$href">${escapeHtml(chapter.title)}</a></li>',
    );
    ncxPoints.writeln('''    <navPoint id="np${i + 1}" playOrder="${i + 1}">
      <navLabel><text>${escapeHtml(chapter.title)}</text></navLabel>
      <content src="$href"/>
    </navPoint>''');
  }

  add('nav.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="${escapeHtml(options.language)}" xml:lang="${escapeHtml(options.language)}">
<head>
<meta charset="utf-8"/>
<title>${escapeHtml(strings.contents)}</title>
<link rel="stylesheet" type="text/css" href="style.css"/>
</head>
<body>
  <nav epub:type="toc" id="toc"${options.includeToc ? '' : ' hidden="hidden"'}>
    <h1>${escapeHtml(strings.contents)}</h1>
    <ol>
$navItems    </ol>
  </nav>
</body>
</html>
''');

  final uid = 'urn:uuid:${_uuidFrom(meta.id)}';
  add('toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="$uid"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>${escapeHtml(meta.title)}</text></docTitle>
  <navMap>
$ncxPoints  </navMap>
</ncx>
''');

  final subjects = [
    if (meta.genre.trim().isNotEmpty) meta.genre.trim(),
    ...meta.tags,
  ];
  add('content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id" xml:lang="${escapeHtml(options.language)}">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">$uid</dc:identifier>
    <dc:title>${escapeHtml(meta.title)}</dc:title>
    <dc:creator>${escapeHtml(author)}</dc:creator>
    <dc:language>${escapeHtml(options.language)}</dc:language>
${meta.description.trim().isEmpty ? '' : '    <dc:description>${escapeHtml(meta.description.trim())}</dc:description>\n'}${subjects.map((s) => '    <dc:subject>${escapeHtml(s)}</dc:subject>\n').join()}    <meta property="dcterms:modified">$modified</meta>
${cover == null ? '' : '    <meta name="cover" content="cover-image"/>\n'}  </metadata>
  <manifest>
$manifest  </manifest>
  <spine toc="ncx">
$spine  </spine>
</package>
''');

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// A stable UUID-shaped identifier derived from the project id. The 64-bit
/// arithmetic uses [BigInt] because plain ints are doubles in the browser.
String _uuidFrom(String id) {
  final mask = BigInt.parse('7fffffffffffffff', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final bytes = utf8.encode(id);
  final out = StringBuffer();
  for (var round = 0; round < 2; round++) {
    for (final b in bytes) {
      hash = ((hash ^ BigInt.from(b)) * prime) & mask;
    }
    hash = ((hash ^ BigInt.from(round + 1)) * prime) & mask;
    out.write(hash.toRadixString(16).padLeft(16, '0'));
  }
  final hex = out.toString().substring(0, 32);
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
