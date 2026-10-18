import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../book_content.dart';
import 'rich_document.dart';

/// The title and block attributes of the first line of [delta].
({String text, Map<String, dynamic> attributes})? _firstLine(Delta delta) {
  final buffer = StringBuffer();
  for (final op in delta.toList()) {
    final data = op.data;
    if (data is! String) {
      buffer.write('￼');
      continue;
    }
    final newline = data.indexOf('\n');
    if (newline < 0) {
      buffer.write(data);
      continue;
    }
    buffer.write(data.substring(0, newline));
    return (
      text: buffer.toString(),
      attributes: op.attributes ?? const <String, dynamic>{},
    );
  }
  return null;
}

/// Joins the chapters into one manuscript. A chapter whose first line is
/// already its title as a heading keeps it; the others get the title as a
/// heading so the chapter boundaries stay visible.
Delta mergeChapters(
  List<BookChapter> chapters,
  Delta Function(String chapterId) deltaOf,
) {
  final merged = Delta();
  for (final chapter in chapters) {
    final delta = deltaOf(chapter.id);
    final first = _firstLine(delta);
    final hasTitle =
        first != null &&
        first.attributes['header'] == 1 &&
        first.text.trim() == chapter.title.trim();
    if (!hasTitle) {
      merged
        ..insert(chapter.title)
        ..insert('\n', {'header': 1});
    }
    if (RichDocument.plainText(delta).trim().isNotEmpty) {
      delta.toList().forEach(merged.push);
    }
  }
  return merged.isEmpty ? RichDocument.empty() : merged;
}
