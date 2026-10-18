import 'package:dart_mcp/server.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:plotcraft_core/features/projects/domain/project_format.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';

import '../serialize.dart';
import '../tool_spec.dart';

const _projectArg =
    'The project: its id, its folder path or its exact title (see '
    'list_projects).';

Schema get _projectSchema => Schema.string(description: _projectArg);

List<ToolSpec> libraryTools() => [
  ToolSpec(
    name: 'list_projects',
    title: 'List projects',
    description:
        'Lists the story projects the server can see, newest first. Use it '
        'first to find a project id.',
    kind: ToolKind.read,
    properties: {
      'query': Schema.string(
        description:
            'Only projects whose title, author or tags contain this '
            'text (case-insensitive).',
      ),
    },
    handler: (call) async {
      final query = call.args.optString('query')?.toLowerCase();
      final projects = await call.context.projects();
      final matching = [
        for (final project in projects)
          if (query == null ||
              project.title.toLowerCase().contains(query) ||
              project.author.toLowerCase().contains(query) ||
              project.tags.any((tag) => tag.toLowerCase().contains(query)))
            project,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return {'projects': matching.map(projectJson).toList()};
    },
  ),
  ToolSpec(
    name: 'get_project',
    title: 'Get a project',
    description:
        'Returns a project\'s identity and an overview: word count, chapters, '
        'elements and gallery images.',
    kind: ToolKind.read,
    properties: {'project': _projectSchema},
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      return {
        'project': projectJson(story.project),
        'overview': await story.overview(),
      };
    },
  ),
  ToolSpec(
    name: 'create_project',
    title: 'Create a project',
    description:
        'Creates a new story project (a folder) in the projects folder, with '
        'one empty chapter. The title needs 3 to 120 characters. Tags: up to '
        '8, each up to 40 characters.',
    kind: ToolKind.write,
    properties: {
      'title': Schema.string(description: 'Title, 3 to 120 characters.'),
      'subtitle': Schema.string(description: 'Up to 160 characters.'),
      'author': Schema.string(description: 'Author or pen name.'),
      'genre': Schema.string(description: 'Up to 80 characters.'),
      'description': Schema.string(
        description: 'The premise of the story, up to 2000 characters.',
      ),
      'tags': Schema.list(items: Schema.string(), description: 'Keywords.'),
      'format': Schema.string(
        description:
            'book (novel or book, with a manuscript) or manga '
            '(elements and gallery only).',
      ),
      'cover_color_index': Schema.int(
        description: 'Generated cover style, 0 to 4.',
        minimum: 0,
        maximum: 4,
      ),
      'cover_image_path': Schema.string(
        description: 'Absolute path of a png, jpg or webp (up to 10 MB).',
      ),
    },
    required: ['title'],
    handler: (call) async {
      final root = call.context.config.root;
      if (root == null) {
        throw const StoryError.validation(
          'The server was started without a projects folder.',
          hint: 'Start it with --root <folder>.',
        );
      }
      final args = call.args;
      final format = args.optString('format') ?? 'book';
      if (!ProjectFormats.isKnown(format)) {
        throw StoryError.validation(
          'Unknown format "$format".',
          hint: 'Use ${ProjectFormats.all.map((f) => f.id).join(' or ')}.',
        );
      }
      final project = await ProjectCreationService().create(
        ProjectMetadataInput(
          title: args.string('title'),
          subtitle: args.optString('subtitle') ?? '',
          author: args.optString('author') ?? '',
          description: args.optString('description') ?? '',
          genre: args.optString('genre') ?? '',
          tags: args.optStringList('tags') ?? const [],
          coverIndex: args.optInt('cover_color_index') ?? 0,
          coverSourcePath: args.optString('cover_image_path'),
          primaryFormat: format,
        ),
        root,
      );
      return {'project': projectJson(project)};
    },
  ),
  ToolSpec(
    name: 'update_project',
    title: 'Update project details',
    description:
        'Changes the identity of a project. Only the fields you send change. '
        'Send "cover_image_path" to set the cover image, or '
        '"remove_cover_image": true to go back to the generated cover.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {
      'project': _projectSchema,
      'title': Schema.string(),
      'subtitle': Schema.string(),
      'author': Schema.string(),
      'genre': Schema.string(),
      'description': Schema.string(),
      'tags': Schema.list(items: Schema.string()),
      'cover_color_index': Schema.int(minimum: 0, maximum: 4),
      'cover_image_path': Schema.string(
        description: 'Absolute path of a png, jpg or webp (up to 10 MB).',
      ),
      'remove_cover_image': Schema.bool(),
    },
    required: ['project'],
    handler: (call) async {
      final story = await call.workspace();
      final args = call.args;
      final current = story.project;
      final updated = await story.updateMetadata(
        ProjectMetadataInput(
          title: args.optString('title') ?? current.title,
          subtitle: args.optString('subtitle') ?? current.subtitle,
          author: args.optString('author') ?? current.author,
          description: args.optString('description') ?? current.description,
          genre: args.optString('genre') ?? current.genre,
          tags: args.optStringList('tags') ?? current.tags,
          coverIndex: args.optInt('cover_color_index') ?? current.coverIndex,
          coverSourcePath: args.optString('cover_image_path'),
          primaryFormat: current.primaryFormat,
        ),
        removeCover: args.boolean('remove_cover_image'),
      );
      return {'project': projectJson(updated)};
    },
  ),
  ToolSpec(
    name: 'delete_project',
    title: 'Delete a project',
    description:
        'PERMANENTLY deletes a project folder with everything in it '
        '(manuscript, elements, gallery, fonts). There is no archive. Ask the '
        'user first. Requires confirm: true and confirm_name equal to the '
        'project title.',
    kind: ToolKind.destructive,
    properties: {
      'project': _projectSchema,
      'confirm': Schema.bool(),
      'confirm_name': Schema.string(
        description: 'The exact title of the project.',
      ),
    },
    required: ['project'],
    handler: (call) async {
      final project = await call.context.resolveProject(
        call.args.string('project'),
      );
      call.context.confirm(
        call.args,
        targetName: project.title,
        what: 'the whole project "${project.title}"',
      );
      await const ProjectLibrary().delete(project);
      return {'deleted': project.id, 'title': project.title};
    },
  ),
];
