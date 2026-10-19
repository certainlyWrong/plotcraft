import 'package:dart_mcp/server.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

import '../tool_spec.dart';

/// Asks the running app to do [method]; throws `appNotRunning` otherwise.
Future<Map<String, Object?>> _ask(
  Call call,
  String method, [
  Map<String, Object?> params = const {},
]) {
  final bridge = call.context.bridge;
  if (bridge == null) {
    throw const StoryError.validation(
      'The server was started without a projects folder, so it cannot find '
      'the app.',
      hint: 'Start it with --root <folder>.',
    );
  }
  return bridge.call(method, params);
}

List<ToolSpec> appTools() => [
  ToolSpec(
    name: 'get_app_status',
    title: 'Is the Plotcraft app running?',
    description:
        'Says whether the Plotcraft app is open (with the same projects '
        'folder) and, if so, its version, theme, language and open project. '
        'The tools below that change the app\'s look or open screens need it '
        'running; everything else works without it.',
    kind: ToolKind.read,
    handler: (call) async {
      final bridge = call.context.bridge;
      final status = await bridge?.appStatus();
      return {'running': status != null, 'status': ?status};
    },
  ),
  ToolSpec(
    name: 'get_preferences',
    title: 'App preferences',
    description:
        'Reads the app\'s preferences: theme, interface font, language and '
        'projects folder, with the options for each. Needs the app running.',
    kind: ToolKind.read,
    handler: (call) => _ask(call, 'get_preferences'),
  ),
  ToolSpec(
    name: 'list_themes',
    title: 'List themes',
    description: 'Lists the color themes of the app. Needs the app running.',
    kind: ToolKind.read,
    handler: (call) => _ask(call, 'list_themes'),
  ),
  ToolSpec(
    name: 'set_theme',
    title: 'Change the theme',
    description:
        'Changes the app\'s color theme (see list_themes for the ids). '
        'Needs the app running.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {'theme_id': Schema.string()},
    required: ['theme_id'],
    handler: (call) =>
        _ask(call, 'set_theme', {'theme_id': call.args.string('theme_id')}),
  ),
  ToolSpec(
    name: 'set_interface_font',
    title: 'Change the interface font',
    description:
        'Changes the font of the app\'s interface (see get_preferences for '
        'the options). Needs the app running.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {'family': Schema.string()},
    required: ['family'],
    handler: (call) => _ask(call, 'set_interface_font', {
      'family': call.args.string('family'),
    }),
  ),
  ToolSpec(
    name: 'set_language',
    title: 'Change the language',
    description:
        'Changes the app\'s language ("en" or "pt"). Needs the app running.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {'language': Schema.string(description: 'en or pt.')},
    required: ['language'],
    handler: (call) =>
        _ask(call, 'set_language', {'language': call.args.string('language')}),
  ),
  ToolSpec(
    name: 'set_projects_root',
    title: 'Change the projects folder',
    description:
        'Changes where new projects are created. On macOS the app only '
        'accepts a folder chosen in its own picker, so this may answer '
        '"unsupported". Needs the app running.',
    kind: ToolKind.write,
    idempotent: true,
    properties: {'path': Schema.string(description: 'Absolute folder path.')},
    required: ['path'],
    handler: (call) =>
        _ask(call, 'set_projects_root', {'path': call.args.string('path')}),
  ),
  ToolSpec(
    name: 'open_in_app',
    title: 'Show something in the app',
    description:
        'Opens a project in the running app and, optionally, a chapter '
        '(selecting the text range start..end in it) or an element, or one '
        'of its screens ("view": overview, settings, gallery, graph for the '
        'story map, timeline), so the author sees what you are talking '
        'about. "fullscreen" puts the app window in (true) or out of (false) '
        'full screen for the text editor, the map and the timeline. Needs '
        'the app running.',
    kind: ToolKind.read,
    properties: {
      'project': Schema.string(
        description: 'The project id, folder or exact title.',
      ),
      'chapter_id': Schema.string(),
      'element_id': Schema.string(),
      'start': Schema.int(
        description: 'With chapter_id: first offset to select.',
      ),
      'end': Schema.int(description: 'With chapter_id: end offset.'),
      'view': Schema.string(
        description:
            'A screen of the project: overview, settings, gallery, graph or '
            'timeline. Ignored when chapter_id or element_id is given.',
      ),
      'fullscreen': Schema.bool(
        description:
            'Full screen for the tab that is open (the editor, the map or '
            'the timeline).',
      ),
    },
    required: ['project'],
    handler: (call) async {
      final project = await call.context.resolveProject(
        call.args.string('project'),
      );
      return _ask(call, 'open_in_app', {
        'project_id': project.id,
        'chapter_id': call.args.optString('chapter_id'),
        'element_id': call.args.optString('element_id'),
        'start': call.args.optInt('start'),
        'end': call.args.optInt('end'),
        'view': call.args.optString('view'),
        'fullscreen': call.args.optBool('fullscreen'),
      });
    },
  ),
  ToolSpec(
    name: 'spell_check_text',
    title: 'Spell-check text',
    description:
        'Checks spelling with the operating system\'s checker (the one the '
        'editor uses) and returns the misspelled ranges with suggestions. '
        'Needs the app running (macOS).',
    kind: ToolKind.read,
    properties: {
      'text': Schema.string(),
      'language': Schema.string(
        description:
            'Language tag such as "pt-BR" or "en". Default: the '
            'app language.',
      ),
    },
    required: ['text'],
    handler: (call) => _ask(call, 'spell_check', {
      'text': call.args.string('text'),
      'language': call.args.optString('language'),
    }),
  ),
  ToolSpec(
    name: 'suggest_spelling',
    title: 'Spelling suggestions',
    description:
        'Suggests corrections for one word. Needs the app running (macOS).',
    kind: ToolKind.read,
    properties: {
      'word': Schema.string(),
      'language': Schema.string(description: 'Language tag, e.g. "pt-BR".'),
    },
    required: ['word'],
    handler: (call) => _ask(call, 'spell_suggest', {
      'word': call.args.string('word'),
      'language': call.args.optString('language'),
    }),
  ),
  ToolSpec(
    name: 'learn_word',
    title: 'Add a word to the dictionary',
    description:
        'Adds a word to the user\'s dictionary so it is no longer flagged '
        '(for example a character name). Needs the app running (macOS).',
    kind: ToolKind.write,
    idempotent: true,
    properties: {'word': Schema.string()},
    required: ['word'],
    handler: (call) =>
        _ask(call, 'spell_learn', {'word': call.args.string('word')}),
  ),
];
