import 'package:dart_mcp/server.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/delta_edit.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_index.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';

import '../args.dart';
import '../serialize.dart';
import '../tool_spec.dart';

Schema get _project => Schema.string(
  description:
      'The project: its id, its folder path or its exact title '
      '(see list_projects).',
);

Schema get _chapter =>
    Schema.string(description: 'The chapter id (see list_chapters).');

const _markdownHelp =
    'Markdown with these extras: [[element:<element id>|Name]] links a name '
    'to an element, ![](gallery://<image id>) shows a gallery image and --- '
    'is a divider. Colors and fonts are not Markdown: use edit_chapter '
    '(format_text) afterwards.';

String _requireNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw StoryError.validation('"$name" cannot be empty.');
  }
  return value;
}

/// The Delta given as Markdown (`markdown`) or as Quill ops (`delta_ops`).
Future<Delta> _contentFromArgs(StoryWorkspace story, Args args) async {
  final markdown = args.optString('markdown');
  final ops = args.raw['delta_ops'];
  if ((markdown == null) == (ops == null)) {
    throw const StoryError.validation(
      'Send exactly one of "markdown" or "delta_ops".',
    );
  }
  if (markdown != null) return story.fromMarkdown(markdown);
  if (ops is! List) {
    throw const StoryError.validation('"delta_ops" must be a list of ops.');
  }
  try {
    return RichDocument.fromOps(ops);
  } catch (_) {
    throw const StoryError.validation(
      '"delta_ops" is not a valid Quill Delta.',
      hint: 'Each op is {"insert": "text", "attributes": {...}}.',
    );
  }
}

List<TextHit> _locate(Delta delta, Map<String, Object?> op, String key) {
  final find = op[key];
  if (find is! String || find.isEmpty) {
    throw StoryError.validation('Operation needs a non-empty "$key".');
  }
  final hits = DeltaEdit.find(
    delta,
    find,
    caseSensitive: op['case_sensitive'] == true,
  );
  if (hits.isEmpty) {
    throw StoryError(
      StoryErrorCode.notFound,
      'The text "${find.length > 60 ? '${find.substring(0, 60)}…' : find}" '
      'is not in the chapter.',
      hint: 'Use get_chapter or search_manuscript to see the current text.',
    );
  }
  final occurrence = op['occurrence'] ?? 1;
  if (occurrence == 'all') return hits;
  if (occurrence is! int || occurrence < 1 || occurrence > hits.length) {
    throw StoryError.validation(
      '"occurrence" must be "all" or a number from 1 to ${hits.length}.',
    );
  }
  return [hits[occurrence - 1]];
}

TextHit _range(Delta delta, Map<String, Object?> op) {
  if (op['find'] != null) return _locate(delta, op, 'find').first;
  final start = op['start'];
  final end = op['end'];
  if (start is! int || end is! int || end < start) {
    throw const StoryError.validation(
      'Give "find" (text) or "start" and "end" (offsets).',
    );
  }
  return TextHit(start, end);
}

/// Offset where an embed goes: after the text "after_text" or at "offset".
int _embedOffset(Delta delta, Map<String, Object?> op) {
  if (op['after_text'] != null) {
    return _locate(delta, {
      'find': op['after_text'],
      'occurrence': op['occurrence'],
      'case_sensitive': op['case_sensitive'],
    }, 'find').first.end;
  }
  final offset = op['offset'];
  if (offset is! int) {
    throw const StoryError.validation('Give "after_text" or "offset".');
  }
  return offset;
}

/// Inline formats in an operation: bold, italic, underline, strike, color,
/// background, font and size. A key set to false or "" removes that format.
Map<String, dynamic> _inlineAttributes(Map<String, Object?> op) {
  const flags = ['bold', 'italic', 'underline', 'strike'];
  const texts = ['color', 'background', 'font', 'size'];
  final attributes = <String, dynamic>{};
  for (final key in flags) {
    if (op.containsKey(key)) attributes[key] = op[key] == true ? true : null;
  }
  for (final key in texts) {
    if (op.containsKey(key)) {
      final value = op[key];
      attributes[key] = value is String && value.isNotEmpty ? value : null;
    }
  }
  return attributes;
}

/// Line formats in an operation: align, indent, header, list and quote. A key
/// set to false (or an alignment of "left", an indent of 0) removes it.
Map<String, dynamic> _blockAttributes(Map<String, Object?> op) {
  final attributes = <String, dynamic>{};
  if (op.containsKey('align')) {
    final value = op['align'];
    const allowed = ['left', 'center', 'right', 'justify'];
    if (value != false && value != null && !allowed.contains(value)) {
      throw const StoryError.validation(
        '"align" is one of left, center, right, justify (or false).',
      );
    }
    attributes['align'] = value == 'left' || value == false ? null : value;
  }
  if (op.containsKey('indent')) {
    final value = op['indent'];
    if (value != false &&
        value != null &&
        (value is! int || value < 0 || value > 8)) {
      throw const StoryError.validation('"indent" is a number from 0 to 8.');
    }
    attributes['indent'] = value is int && value > 0 ? value : null;
  }
  if (op.containsKey('header')) {
    final value = op['header'];
    if (value != false &&
        value != null &&
        (value is! int || value < 1 || value > 3)) {
      throw const StoryError.validation('"header" is 1, 2 or 3 (or false).');
    }
    attributes['header'] = value is int ? value : null;
  }
  if (op.containsKey('list')) {
    final value = op['list'];
    const allowed = ['bullet', 'ordered', 'checked', 'unchecked'];
    if (value != false && value != null && !allowed.contains(value)) {
      throw const StoryError.validation(
        '"list" is one of bullet, ordered, checked, unchecked (or false).',
      );
    }
    attributes['list'] = value is String ? value : null;
  }
  if (op.containsKey('quote')) {
    attributes['blockquote'] = op['quote'] == true ? true : null;
  }
  return attributes;
}

Future<(Delta, Map<String, Object?>)> _apply(
  StoryWorkspace story,
  Delta delta,
  Map<String, Object?> op,
) async {
  final kind = op['op'];
  switch (kind) {
    case 'replace_text':
      final hits = _locate(delta, op, 'find');
      final replacement = (op['replace'] as String?) ?? '';
      var result = delta;
      for (final hit in hits.reversed) {
        result = DeltaEdit.replaceRange(
          result,
          hit.start,
          hit.length,
          replacement,
        );
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'insert_after_text' || 'insert_before_text':
      final hits = _locate(delta, op, 'find');
      final text = op['text'];
      if (text is! String || text.isEmpty) {
        throw const StoryError.validation(
          'Operation needs a non-empty "text".',
        );
      }
      final style = _inlineAttributes(op);
      var result = delta;
      for (final hit in hits.reversed) {
        result = DeltaEdit.insertText(
          result,
          kind == 'insert_after_text' ? hit.end : hit.start,
          text,
          attributes: style.isEmpty ? null : style,
        );
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'insert_at_offset':
      final offset = op['offset'];
      final text = op['text'];
      if (offset is! int || text is! String || text.isEmpty) {
        throw const StoryError.validation(
          'insert_at_offset needs an integer "offset" and a "text".',
        );
      }
      final style = _inlineAttributes(op);
      return (
        DeltaEdit.insertText(
          delta,
          offset,
          text,
          attributes: style.isEmpty ? null : style,
        ),
        {'op': kind, 'matches': 1},
      );
    case 'delete_text':
      final hits = op['find'] != null
          ? _locate(delta, op, 'find')
          : [_range(delta, op)];
      var result = delta;
      for (final hit in hits.reversed) {
        result = DeltaEdit.deleteRange(result, hit.start, hit.length);
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'format_text':
      final inline = _inlineAttributes(op);
      final block = _blockAttributes(op);
      if (inline.isEmpty && block.isEmpty) {
        throw const StoryError.validation(
          'format_text needs at least one of bold, italic, underline, strike, '
          'color, background, font, size, align, indent, header, list or quote.',
          hint: 'Use false (or "") to remove a format.',
        );
      }
      final hits = op['find'] != null
          ? _locate(delta, op, 'find')
          : [_range(delta, op)];
      var result = delta;
      for (final hit in hits) {
        if (inline.isNotEmpty) {
          result = DeltaEdit.formatRange(result, hit.start, hit.length, inline);
        }
        if (block.isNotEmpty) {
          result = DeltaEdit.formatLines(result, hit.start, hit.length, block);
        }
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'clear_format':
      final hits = op['find'] != null
          ? _locate(delta, op, 'find')
          : [_range(delta, op)];
      var result = delta;
      for (final hit in hits) {
        result = DeltaEdit.clearFormat(result, hit.start, hit.length);
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'link_mention':
      final id = op['element_id'];
      if (id is! String) {
        throw const StoryError.validation('link_mention needs "element_id".');
      }
      final element = (await story.element(id)).element;
      final hits = _locate(delta, op, 'find');
      var result = delta;
      for (final hit in hits) {
        result = DeltaEdit.linkMention(
          result,
          hit.start,
          hit.length,
          element.id,
          element.title,
        );
      }
      return (result, {'op': kind, 'matches': hits.length});
    case 'insert_divider':
      return (
        DeltaEdit.insertEmbedLine(
          delta,
          _embedOffset(delta, op),
          RichDocument.divider(),
        ),
        {'op': kind, 'matches': 1},
      );
    case 'insert_gallery_image':
      final id = op['gallery_id'];
      if (id is! String) {
        throw const StoryError.validation(
          'insert_gallery_image needs "gallery_id".',
        );
      }
      final items = await story.gallery();
      if (!items.any((item) => item.id == id && item.exists)) {
        throw StoryError.notFound(
          'Gallery image "$id"',
          hint: 'Call list_gallery to see the image ids.',
        );
      }
      return (
        DeltaEdit.insertEmbedLine(
          delta,
          _embedOffset(delta, op),
          RichDocument.galleryImage(
            id,
            width: op['width'] as int?,
            align: op['align'] as String?,
          ),
        ),
        {'op': kind, 'matches': 1},
      );
  }
  throw StoryError.validation(
    'Unknown operation "$kind".',
    hint:
        'Use replace_text, insert_after_text, insert_before_text, '
        'insert_at_offset, delete_text, format_text, link_mention, '
        'insert_divider or insert_gallery_image.',
  );
}

Map<String, Object?> _chapterBody(
  ChapterContent chapter,
  String format,
  String markdown,
  Args args,
) {
  final plain = DeltaEdit.text(chapter.delta);
  final words = StoryWorkspace.wordCount(
    RichDocument.plainText(chapter.delta, embed: ''),
  );
  final start = args.optInt('start') ?? 0;
  final end = args.optInt('end') ?? plain.length;
  final Object content = switch (format) {
    'delta' => chapter.delta.toJson(),
    'text' => plain.substring(
      start.clamp(0, plain.length),
      end.clamp(0, plain.length),
    ),
    _ => markdown,
  };
  return {
    'id': chapter.id,
    'title': chapter.title,
    'revision': chapter.revision,
    'words': words,
    'format': format,
    'content': content,
    'elements_linked': RichDocument.mentionedIds(chapter.delta),
  };
}

List<ToolSpec> manuscriptTools() => [
  ToolSpec(
    name: 'list_chapters',
    title: 'List chapters',
    description:
        'Lists the chapters of a book in reading order with word counts and '
        'revisions.',
    kind: ToolKind.read,
    properties: {'project': _project},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      return {
        'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'get_chapter',
    title: 'Read a chapter',
    description:
        'Reads a chapter. "format" is markdown (default), text (plain text; '
        'the offsets of edit_chapter count in this text, where an embedded '
        'image or divider is the single character U+FFFC) or delta (Quill '
        'ops with colors and fonts). The result has the "revision" to send '
        'back as base_revision when you write. $_markdownHelp',
    kind: ToolKind.read,
    properties: {
      'project': _project,
      'chapter_id': _chapter,
      'format': Schema.string(description: 'markdown, text or delta.'),
      'start': Schema.int(description: 'text format only: first offset.'),
      'end': Schema.int(description: 'text format only: end offset.'),
    },
    required: ['project', 'chapter_id'],
    handler: (call) async {
      final story = await call.workspace();
      final format = call.args.choice('format', [
        'markdown',
        'text',
        'delta',
      ], defaultValue: 'markdown');
      final chapter = await story.readChapter(call.args.string('chapter_id'));
      final markdown = format == 'markdown'
          ? await story.toMarkdown(chapter.delta)
          : '';
      return _chapterBody(chapter, format, markdown, call.args);
    },
  ),
  ToolSpec(
    name: 'write_chapter',
    title: 'Write a chapter',
    description:
        'Writes the text of a chapter. mode "replace" (default) replaces '
        'everything and needs base_revision from get_chapter unless the '
        'chapter is empty; "append" and "prepend" add to it. Give the text as '
        '"markdown" or as "delta_ops". $_markdownHelp',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'chapter_id': _chapter,
      'markdown': Schema.string(description: 'The text, in Markdown.'),
      'delta_ops': Schema.list(
        items: Schema.object(),
        description: 'The text as Quill Delta ops (alternative to markdown).',
      ),
      'mode': Schema.string(
        description: 'replace (default), append or prepend.',
      ),
      'base_revision': Schema.string(
        description: 'The revision you last read (required to replace).',
      ),
    },
    required: ['project', 'chapter_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('chapter_id');
      final mode = call.args.choice('mode', [
        'replace',
        'append',
        'prepend',
      ], defaultValue: 'replace');
      final incoming = await _contentFromArgs(story, call.args);
      final current = await story.readChapter(id);
      final empty = DeltaEdit.text(current.delta).trim().isEmpty;
      final base = call.args.optString('base_revision');
      if (mode == 'replace' && !empty && base == null) {
        throw const StoryError.validation(
          'Replacing existing text needs "base_revision".',
          hint:
              'Call get_chapter, read the text, and send its revision. '
              'Use mode "append" to add text without it.',
        );
      }
      final Delta next = switch (mode) {
        'append' => empty ? incoming : current.delta.concat(incoming),
        'prepend' => empty ? incoming : incoming.concat(current.delta),
        _ => incoming,
      };
      final revision = await story.writeChapter(
        id,
        next,
        baseRevision: mode == 'replace' ? base : (base ?? current.revision),
      );
      return {
        'id': id,
        'revision': revision,
        'words': StoryWorkspace.wordCount(
          RichDocument.plainText(next, embed: ''),
        ),
      };
    },
  ),
  ToolSpec(
    name: 'edit_chapter',
    title: 'Edit part of a chapter',
    description:
        'Applies precise edits to a chapter, in order, keeping the formatting '
        'around them. Each operation is an object with "op": '
        'replace_text {find, replace, occurrence (number or "all"), '
        'case_sensitive}; insert_after_text / insert_before_text {find, text}; '
        'insert_at_offset {offset, text} (insert ops also take bold, italic, '
        'underline, strike, color, background, font, size for the new text); '
        'delete_text {find | start, end}; '
        'format_text {find | start, end, bold, italic, underline, strike, '
        'color "#RRGGBB", background, font, size, and line formats: header '
        '1-3, list bullet|ordered|checked|unchecked, quote, indent 0-8, align '
        'left|center|right|justify; false or "" removes; a line format applies '
        'to every line the text touches}; '
        'clear_format {find | start, end} (removes inline and line formats '
        'and web links, keeps element links); '
        'link_mention {find, element_id}; insert_divider {after_text | offset}; '
        'insert_gallery_image {gallery_id, after_text | offset}. If any '
        'operation fails nothing is saved.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'chapter_id': _chapter,
      'operations': Schema.list(
        items: Schema.object(),
        minItems: 1,
        description: 'The edits, applied in order.',
      ),
      'base_revision': Schema.string(
        description: 'The revision you last read (recommended).',
      ),
    },
    required: ['project', 'chapter_id', 'operations'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('chapter_id');
      final operations = call.args.optObjectList('operations') ?? const [];
      if (operations.isEmpty) {
        throw const StoryError.validation('Send at least one operation.');
      }
      final chapter = await story.readChapter(id);
      var delta = chapter.delta;
      final applied = <Map<String, Object?>>[];
      for (final op in operations) {
        final (next, summary) = await _apply(story, delta, op);
        delta = next;
        applied.add(summary);
      }
      final revision = await story.writeChapter(
        id,
        delta,
        baseRevision: call.args.optString('base_revision') ?? chapter.revision,
      );
      return {'id': id, 'revision': revision, 'applied': applied};
    },
  ),
  ToolSpec(
    name: 'add_chapter',
    title: 'Add a chapter',
    description:
        'Adds a chapter at the end (or at "position", counting from 0), '
        'optionally with its first text. $_markdownHelp',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'title': Schema.string(description: 'The chapter title.'),
      'markdown': Schema.string(description: 'The first text, in Markdown.'),
      'position': Schema.int(minimum: 0, description: 'Where to insert it.'),
    },
    required: ['project', 'title'],
    handler: (call) async {
      final story = await call.workspace();
      final markdown = call.args.optString('markdown');
      final id = await story.addChapter(
        call.args.string('title'),
        content: markdown == null ? null : await story.fromMarkdown(markdown),
        position: call.args.optInt('position'),
      );
      return {
        'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
        'new_chapter_id': id,
      };
    },
  ),
  ToolSpec(
    name: 'rename_chapter',
    title: 'Rename a chapter',
    description: 'Changes the title of a chapter.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'chapter_id': _chapter,
      'title': Schema.string(),
    },
    required: ['project', 'chapter_id', 'title'],
    handler: (call) async {
      final story = await call.workspace();
      await story.renameChapter(
        call.args.string('chapter_id'),
        _requireNonEmpty(call.args.string('title'), 'title'),
      );
      return {
        'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'reorder_chapters',
    title: 'Reorder chapters',
    description:
        'Sets the reading order. "chapter_ids" must list every chapter '
        'exactly once.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _project,
      'chapter_ids': Schema.list(items: Schema.string()),
    },
    required: ['project', 'chapter_ids'],
    handler: (call) async {
      final story = await call.workspace();
      await story.reorderChapters(
        call.args.optStringList('chapter_ids') ?? const [],
      );
      return {
        'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'remove_chapter',
    title: 'Remove a chapter',
    description:
        'Removes a chapter from the book. Its files are moved to the '
        'project\'s content/book/archive folder, so the text can be '
        'recovered by hand, but it leaves the manuscript. The last chapter '
        'cannot be removed. Requires confirm: true and confirm_name equal to '
        'the chapter title.',
    kind: ToolKind.destructive,
    properties: {
      'project': _project,
      'chapter_id': _chapter,
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(description: 'The exact chapter title.'),
    },
    required: ['project', 'chapter_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('chapter_id');
      final chapter = await story.readChapter(id);
      call.context.confirm(
        call.args,
        targetName: chapter.title,
        what: 'the chapter "${chapter.title}" (it leaves the manuscript)',
      );
      await story.removeChapter(id);
      return {
        'removed': id,
        'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'search_manuscript',
    title: 'Search the manuscript',
    description:
        'Finds text in every chapter (or in "chapter_ids"). Offsets are '
        'positions in the chapter\'s plain text (see get_chapter format '
        'text).',
    kind: ToolKind.read,
    properties: {
      'project': _project,
      'query': Schema.string(),
      'regex': Schema.bool(
        description: 'Treat the query as a regular expression.',
      ),
      'case_sensitive': Schema.bool(),
      'chapter_ids': Schema.list(items: Schema.string()),
      'limit': Schema.int(minimum: 1, maximum: 1000),
    },
    required: ['project', 'query'],
    handler: (call) async {
      final story = await call.workspace();
      final matches = await story.search(
        call.args.string('query'),
        regex: call.args.boolean('regex'),
        caseSensitive: call.args.boolean('case_sensitive'),
        chapterIds: call.args.optStringList('chapter_ids'),
        limit: call.args.optInt('limit') ?? 200,
      );
      return {
        'count': matches.length,
        'matches': [
          for (final match in matches)
            {
              'chapter_id': match.chapterId,
              'chapter_title': match.chapterTitle,
              'start': match.start,
              'end': match.end,
              'snippet': match.snippet,
            },
        ],
      };
    },
  ),
  ToolSpec(
    name: 'replace_in_manuscript',
    title: 'Find and replace in the manuscript',
    description:
        'Replaces text in every chapter (or in "chapter_ids"), keeping '
        'formatting. By default it only simulates (dry_run: true) and says '
        'how many replacements each chapter would get; send dry_run: false '
        'to apply them.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'find': Schema.string(),
      'replace': Schema.string(),
      'regex': Schema.bool(),
      'case_sensitive': Schema.bool(),
      'chapter_ids': Schema.list(items: Schema.string()),
      'dry_run': Schema.bool(description: 'Default true.'),
    },
    required: ['project', 'find', 'replace'],
    handler: (call) async {
      final story = await call.workspace();
      final dryRun = call.args.boolean('dry_run', defaultValue: true);
      final outcomes = await story.replaceInManuscript(
        call.args.string('find'),
        call.args.string('replace'),
        dryRun: dryRun,
        regex: call.args.boolean('regex'),
        caseSensitive: call.args.boolean('case_sensitive'),
        chapterIds: call.args.optStringList('chapter_ids'),
      );
      return {
        'dry_run': dryRun,
        'total': outcomes.fold<int>(0, (sum, o) => sum + o.count),
        'chapters': [
          for (final outcome in outcomes)
            {
              'chapter_id': outcome.chapterId,
              'chapter_title': outcome.chapterTitle,
              'replacements': outcome.count,
            },
        ],
      };
    },
  ),
  ToolSpec(
    name: 'link_mentions',
    title: 'Link detected names to elements',
    description:
        'Turns the plain-text names and aliases of elements that are written '
        'in the chapters into links to those elements (the text does not '
        'change). Limit it with chapter_id or element_id. dry_run: true only '
        'counts.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'chapter_id': Schema.string(description: 'Only this chapter.'),
      'element_id': Schema.string(description: 'Only this element.'),
      'dry_run': Schema.bool(),
    },
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      final onlyChapter = call.args.optString('chapter_id');
      final onlyElement = call.args.optString('element_id');
      final dryRun = call.args.boolean('dry_run');
      final elements = [for (final r in await story.elements()) r.element];
      final index = MentionIndex([
        for (final element in elements)
          if (onlyElement == null || element.id == onlyElement) element,
      ]);
      final byId = {for (final element in elements) element.id: element};
      final results = <Map<String, Object?>>[];
      for (final info in await story.chapters()) {
        if (onlyChapter != null && info.id != onlyChapter) continue;
        final chapter = await story.readChapter(info.id);
        final hits = index.scan(chapter.delta, includeLinked: false);
        if (hits.isEmpty) continue;
        var delta = chapter.delta;
        for (final hit in hits.reversed) {
          delta = DeltaEdit.linkMention(
            delta,
            hit.start,
            hit.end - hit.start,
            hit.elementId,
            byId[hit.elementId]!.title,
          );
        }
        if (!dryRun) {
          await story.writeChapter(
            info.id,
            delta,
            baseRevision: chapter.revision,
          );
        }
        results.add({
          'chapter_id': info.id,
          'chapter_title': info.title,
          'linked': hits.length,
        });
      }
      return {
        'dry_run': dryRun,
        'total': results.fold<int>(0, (sum, r) => sum + (r['linked']! as int)),
        'chapters': results,
      };
    },
  ),
  ToolSpec(
    name: 'get_manuscript_stats',
    title: 'Manuscript statistics',
    description:
        'Word counts per chapter and in total, with an estimated reading '
        'time (220 words per minute).',
    kind: ToolKind.read,
    properties: {'project': _project},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      final chapters = await story.chapters();
      final total = chapters.fold<int>(0, (sum, c) => sum + c.words);
      return {
        'total_words': total,
        'chapters': chapters.length,
        'estimated_reading_minutes': (total / 220).ceil(),
        'per_chapter': [
          for (final chapter in chapters)
            {'id': chapter.id, 'title': chapter.title, 'words': chapter.words},
        ],
      };
    },
  ),
];
