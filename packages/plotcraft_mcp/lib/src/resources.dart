import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import 'context.dart';
import 'guides.dart';
import 'serialize.dart';

const _json = JsonEncoder.withIndent('  ');

ReadResourceResult _text(
  String uri,
  String text, [
  String mime = 'text/plain',
]) => ReadResourceResult(
  contents: [TextResourceContents(uri: uri, text: text, mimeType: mime)],
);

ReadResourceResult _data(String uri, Object? data) =>
    _text(uri, _json.convert(data), 'application/json');

/// Resources: the guides and the content of every project, by URI.
void registerResources(ResourcesSupport server, ToolContext context) {
  server
    ..addResource(
      Resource(
        uri: 'plotcraft://guide/data-model',
        name: 'Plotcraft data model',
        description:
            'How projects, chapters, elements and the gallery fit '
            'together. Read it before writing.',
        mimeType: 'text/markdown',
      ),
      (request) => _text(request.uri, dataModelGuide, 'text/markdown'),
    )
    ..addResource(
      Resource(
        uri: 'plotcraft://guide/markdown',
        name: 'Markdown in chapters',
        description:
            'The Markdown extensions for mentions, images and '
            'dividers.',
        mimeType: 'text/markdown',
      ),
      (request) => _text(request.uri, markdownGuide, 'text/markdown'),
    )
    ..addResource(
      Resource(
        uri: 'plotcraft://projects',
        name: 'Projects',
        description: 'Every project the server can see.',
        mimeType: 'application/json',
      ),
      (request) async => _data(request.uri, {
        'projects': (await context.projects()).map(projectJson).toList(),
      }),
    )
    ..addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'plotcraft://projects/{project}',
        name: 'Project',
        description: 'A project and its overview.',
        mimeType: 'application/json',
      ),
      (request) async {
        final parts = _parts(request.uri);
        if (parts == null || parts.length != 1) return null;
        final story = await context.workspace(parts[0]);
        return _data(request.uri, {
          'project': projectJson(story.project),
          'overview': await story.overview(),
          'chapters': (await story.chapters()).map(chapterInfoJson).toList(),
        });
      },
    )
    ..addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'plotcraft://projects/{project}/chapters/{chapter}',
        name: 'Chapter',
        description: 'The Markdown text of a chapter.',
        mimeType: 'text/markdown',
      ),
      (request) async {
        final parts = _parts(request.uri);
        if (parts == null || parts.length != 3 || parts[1] != 'chapters') {
          return null;
        }
        final story = await context.workspace(parts[0]);
        final chapter = await story.readChapter(parts[2]);
        return _text(
          request.uri,
          '# ${chapter.title}\n\n${await story.toMarkdown(chapter.delta)}',
          'text/markdown',
        );
      },
    )
    ..addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'plotcraft://projects/{project}/elements/{element}',
        name: 'Element',
        description: 'Everything stored about an element.',
        mimeType: 'application/json',
      ),
      (request) async {
        final parts = _parts(request.uri);
        if (parts == null || parts.length != 3 || parts[1] != 'elements') {
          return null;
        }
        final story = await context.workspace(parts[0]);
        return _data(request.uri, elementJson(await story.element(parts[2])));
      },
    )
    ..addResourceTemplate(
      ResourceTemplate(
        uriTemplate: 'plotcraft://projects/{project}/gallery/{image}',
        name: 'Gallery image',
        description: 'An image of the project gallery.',
      ),
      (request) async {
        final parts = _parts(request.uri);
        if (parts == null || parts.length != 3 || parts[1] != 'gallery') {
          return null;
        }
        final story = await context.workspace(parts[0]);
        final item = (await story.gallery())
            .where((i) => i.id == parts[2] && i.exists)
            .firstOrNull;
        if (item == null) {
          throw StoryError.notFound('Gallery image "${parts[2]}"');
        }
        final mime = switch (p.extension(item.file).toLowerCase()) {
          '.png' => 'image/png',
          '.jpg' || '.jpeg' => 'image/jpeg',
          '.webp' => 'image/webp',
          _ => 'image/gif',
        };
        return ReadResourceResult(
          contents: [
            BlobResourceContents(
              uri: request.uri,
              blob: base64Encode(await File(item.path).readAsBytes()),
              mimeType: mime,
            ),
          ],
        );
      },
    );
}

/// The segments after `plotcraft://projects/`, or null for other URIs.
List<String>? _parts(String uri) {
  const prefix = 'plotcraft://projects/';
  if (!uri.startsWith(prefix)) return null;
  return [
    for (final part in uri.substring(prefix.length).split('/'))
      if (part.isNotEmpty) Uri.decodeComponent(part),
  ];
}
