import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import '../serialize.dart';
import '../tool_spec.dart';

Schema get _project => Schema.string(
  description:
      'The project: its id, its folder path or its exact title '
      '(see list_projects).',
);

const _maxImageBytes = 8 * 1024 * 1024;

String _mimeOf(String file) => switch (p.extension(file).toLowerCase()) {
  '.png' => 'image/png',
  '.jpg' || '.jpeg' => 'image/jpeg',
  '.webp' => 'image/webp',
  '.gif' => 'image/gif',
  _ => 'application/octet-stream',
};

List<ToolSpec> assetTools() => [
  ToolSpec(
    name: 'list_gallery',
    title: 'List gallery images',
    description:
        'Lists the images of the project gallery. The "id" is what elements '
        'and chapters use to show an image.',
    kind: ToolKind.read,
    properties: {'project': _project},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      return {'images': (await story.gallery()).map(galleryJson).toList()};
    },
  ),
  ToolSpec(
    name: 'get_gallery_image',
    title: 'View a gallery image',
    description: 'Returns a gallery image so you can look at it (up to 8 MB).',
    kind: ToolKind.read,
    properties: {'project': _project, 'image_id': Schema.string()},
    required: ['project', 'image_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('image_id');
      final item = (await story.gallery())
          .where((i) => i.id == id && i.exists)
          .firstOrNull;
      if (item == null) {
        throw StoryError.notFound(
          'Gallery image "$id"',
          hint: 'Call list_gallery to see the image ids.',
        );
      }
      final file = File(item.path);
      if (await file.length() > _maxImageBytes) {
        throw const StoryError.validation('The image is larger than 8 MB.');
      }
      return WithContent(galleryJson(item), [
        ImageContent(
          data: base64Encode(await file.readAsBytes()),
          mimeType: _mimeOf(item.file),
        ),
      ]);
    },
  ),
  ToolSpec(
    name: 'import_gallery_images',
    title: 'Import images into the gallery',
    description:
        'Copies image files (png, jpg, jpeg, webp, gif) from the computer '
        'into the project gallery. Names that already exist get a suffix.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'paths': Schema.list(
        items: Schema.string(),
        description: 'Absolute paths of the image files.',
      ),
    },
    required: ['project', 'paths'],
    handler: (call) async {
      final story = await call.workspace();
      final paths = call.args.optStringList('paths') ?? const [];
      if (paths.isEmpty) {
        throw const StoryError.validation('Send at least one path.');
      }
      final before = {for (final i in await story.gallery()) i.id};
      final items = await story.importImages(paths);
      return {
        'imported': [
          for (final item in items)
            if (!before.contains(item.id)) galleryJson(item),
        ],
        'images': items.map(galleryJson).toList(),
      };
    },
  ),
  ToolSpec(
    name: 'import_gallery_image_data',
    title: 'Add an image to the gallery from data',
    description:
        'Saves an image given as base64 (for example one you generated) in '
        'the gallery under "file_name" (png, jpg, jpeg, webp or gif).',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'file_name': Schema.string(description: 'e.g. "portrait-maria.png".'),
      'data_base64': Schema.string(),
    },
    required: ['project', 'file_name', 'data_base64'],
    handler: (call) async {
      final story = await call.workspace();
      final Uint8List bytes;
      try {
        bytes = base64Decode(call.args.string('data_base64'));
      } on FormatException {
        throw const StoryError.validation('"data_base64" is not valid base64.');
      }
      if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
        throw const StoryError.validation(
          'The image must be between 1 byte and 20 MB.',
        );
      }
      final item = await story.importImageData(
        call.args.string('file_name'),
        bytes,
      );
      return {'image': galleryJson(item)};
    },
  ),
  ToolSpec(
    name: 'remove_gallery_image',
    title: 'Remove a gallery image',
    description:
        'PERMANENTLY deletes an image file from the gallery. Elements and '
        'chapters that showed it keep a missing-image placeholder. Requires '
        'confirm: true and confirm_name equal to the file name.',
    kind: ToolKind.destructive,
    properties: {
      'project': _project,
      'image_id': Schema.string(),
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(description: 'The exact file name.'),
    },
    required: ['project', 'image_id'],
    handler: (call) async {
      final story = await call.workspace();
      final id = call.args.string('image_id');
      final item = (await story.gallery())
          .where((i) => i.id == id && i.exists)
          .firstOrNull;
      if (item == null) {
        throw StoryError.notFound('Gallery image "$id"');
      }
      call.context.confirm(
        call.args,
        targetName: item.file,
        what: 'the image file "${item.file}"',
      );
      await story.removeGalleryImage(id);
      return {'removed': id};
    },
  ),
  ToolSpec(
    name: 'list_project_fonts',
    title: 'List project fonts',
    description:
        'Lists the font files stored in the project (they travel with it and '
        'can be used in the text).',
    kind: ToolKind.read,
    properties: {'project': _project},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      return {'fonts': (await story.fonts()).map(fontJson).toList()};
    },
  ),
  ToolSpec(
    name: 'add_project_fonts',
    title: 'Add fonts to the project',
    description:
        'Copies font files (ttf, otf, ttc; up to 30 MB each) into the '
        'project. Files that are not fonts are skipped.',
    kind: ToolKind.write,
    properties: {
      'project': _project,
      'paths': Schema.list(items: Schema.string()),
    },
    required: ['project', 'paths'],
    handler: (call) async {
      final story = await call.workspace();
      final paths = call.args.optStringList('paths') ?? const [];
      final added = await story.addFonts(paths);
      return {
        'added': added.map(fontJson).toList(),
        'skipped': paths.length - added.length,
      };
    },
  ),
  ToolSpec(
    name: 'remove_project_font',
    title: 'Remove a project font',
    description:
        'PERMANENTLY deletes a font file from the project. Text using it '
        'falls back to another font. Requires confirm: true and confirm_name '
        'equal to the file name.',
    kind: ToolKind.destructive,
    properties: {
      'project': _project,
      'file': Schema.string(description: 'The font file name.'),
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(description: 'The exact file name.'),
    },
    required: ['project', 'file'],
    handler: (call) async {
      final story = await call.workspace();
      final file = call.args.string('file');
      call.context.confirm(
        call.args,
        targetName: file,
        what: 'the font file "$file"',
      );
      await story.removeFont(file);
      return {'removed': file};
    },
  ),
];
