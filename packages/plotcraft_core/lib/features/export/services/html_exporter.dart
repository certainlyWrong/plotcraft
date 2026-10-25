import 'dart:convert';
import 'dart:typed_data';

import '../domain/export_book.dart';
import '../domain/export_options.dart';
import 'export_strings.dart';
import 'html_renderer.dart';

/// One self-contained HTML file: styles inline and images as data URIs.
Uint8List exportHtml(ExportBook book, ExportOptions options) {
  final strings = ExportStrings.of(options.language);
  final meta = book.metadata;
  final renderer = HtmlRenderer(book, imageSrc: HtmlRenderer.dataUri);
  final author = meta.author.trim().isEmpty
      ? strings.unknownAuthor
      : meta.author.trim();
  final out = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="${escapeHtml(options.language)}">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8"/>')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1"/>',
    )
    ..writeln('<meta name="author" content="${escapeHtml(author)}"/>')
    ..writeln('<title>${escapeHtml(meta.title)}</title>')
    ..writeln('<style>${HtmlRenderer.css(options.fontSize, standalone: true)}</style>')
    ..writeln('</head>')
    ..writeln('<body>');
  final cover = options.includeCover ? book.cover : null;
  if (cover != null) {
    out.writeln(
      '<p class="cover"><img src="${HtmlRenderer.dataUri(cover)}" alt=""/></p>',
    );
  }
  out
    ..writeln('<header class="title-page">')
    ..writeln('<h1>${escapeHtml(meta.title)}</h1>');
  if (meta.subtitle.trim().isNotEmpty) {
    out.writeln('<p class="subtitle">${escapeHtml(meta.subtitle.trim())}</p>');
  }
  out
    ..writeln('<p class="author">${escapeHtml(strings.by)} ${escapeHtml(author)}</p>')
    ..writeln('</header>');
  if (options.includeToc && book.chapters.length > 1) {
    out
      ..writeln('<nav id="toc">')
      ..writeln('<h2>${escapeHtml(strings.contents)}</h2>')
      ..writeln('<ol>');
    for (var i = 0; i < book.chapters.length; i++) {
      out.writeln(
        '<li><a href="#c$i">${escapeHtml(book.chapters[i].title)}</a></li>',
      );
    }
    out
      ..writeln('</ol>')
      ..writeln('</nav>');
  }
  for (var i = 0; i < book.chapters.length; i++) {
    final chapter = book.chapters[i];
    out
      ..writeln('<section id="c$i">')
      ..writeln('<h1>${escapeHtml(chapter.title)}</h1>')
      ..write(renderer.blocks(chapter.blocks))
      ..writeln('</section>');
  }
  out
    ..writeln('</body>')
    ..writeln('</html>');
  return Uint8List.fromList(utf8.encode(out.toString()));
}
