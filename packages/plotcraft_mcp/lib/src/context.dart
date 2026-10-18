import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/app_bridge/app_bridge_client.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/projects/data/project_library.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import 'args.dart';
import 'config.dart';

/// Shared state of the tools: where the projects are, whether writing is
/// allowed, how destructive calls are confirmed and the audit log.
class ToolContext {
  ToolContext(this.config, {ProjectLibrary library = const ProjectLibrary()})
    : _library = library;

  final ServerConfig config;
  final ProjectLibrary _library;

  /// Talks to the running app; null when no projects folder was given (the
  /// app is found through that folder).
  late final AppBridgeClient? bridge = config.root == null
      ? null
      : AppBridgeClient(config.root!);

  /// Every project the server can see.
  Future<List<StoryProject>> projects() =>
      _library.discover(knownFolders: config.projectFolders, root: config.root);

  /// The project that [reference] names: its id, its folder, or its exact
  /// title (ignoring case) when that is unambiguous.
  Future<StoryProject> resolveProject(String reference) async {
    final ref = reference.trim();
    if (ref.isEmpty) {
      throw const StoryError.validation('The "project" argument is empty.');
    }
    if (p.isAbsolute(ref) && Directory(ref).existsSync()) {
      final byPath = await _library.read(ref);
      if (byPath != null) return byPath;
    }
    final all = await projects();
    final byId = all.where((project) => project.id == ref).toList();
    if (byId.length == 1) return byId.single;
    final byTitle = all
        .where((project) => project.title.toLowerCase() == ref.toLowerCase())
        .toList();
    if (byTitle.length == 1) return byTitle.single;
    if (byTitle.length > 1) {
      throw StoryError.validation(
        'More than one project is titled "$ref".',
        hint: 'Use the project id: ${byTitle.map((x) => x.id).join(', ')}.',
      );
    }
    throw StoryError.notFound(
      'Project "$ref"',
      hint: all.isEmpty
          ? 'No projects were found. Check the server\'s --root folder.'
          : 'Call list_projects. Known ids: '
                '${all.take(10).map((x) => x.id).join(', ')}.',
    );
  }

  Future<StoryWorkspace> workspace(String reference) async =>
      StoryWorkspace.open(await resolveProject(reference));

  void requireWritable() {
    if (config.readOnly) {
      throw const StoryError(
        StoryErrorCode.readOnly,
        'The server runs in read-only mode.',
        hint: 'Restart it without --read-only to allow changes.',
      );
    }
  }

  /// Destructive tools must be called with `confirm: true` and with
  /// `confirm_name` equal to [targetName], so the AI has to state what it is
  /// about to lose.
  void confirm(Args args, {required String targetName, required String what}) {
    if (args.boolean('confirm') &&
        args.optString('confirm_name') == targetName) {
      return;
    }
    throw StoryError(
      StoryErrorCode.confirmationRequired,
      'This permanently affects $what.',
      hint:
          'Call again with confirm: true and confirm_name: "$targetName" '
          'if that is what the user wants.',
    );
  }

  /// Appends one line about a write to `<project>/.plotcraft/mcp-log.jsonl`.
  Future<void> audit(
    String projectFolder,
    String tool,
    Map<String, Object?> arguments,
    Object? result,
  ) async {
    // `result` is accepted so the log can grow richer without changing callers.
    try {
      final file = File(p.join(projectFolder, '.plotcraft', 'mcp-log.jsonl'));
      if (!await Directory(projectFolder).exists()) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '${jsonEncode({'time': DateTime.now().toUtc().toIso8601String(), 'tool': tool, 'arguments': _short(arguments), 'ok': true})}\n',
        mode: FileMode.append,
      );
    } on FileSystemException {
      // The log is a convenience; never fail a write because of it.
    }
  }

  /// Long texts are summarised by their length so the log stays small.
  Object? _short(Object? value) {
    if (value is String) {
      return value.length > 120
          ? '${value.substring(0, 120)}… (${value.length} chars)'
          : value;
    }
    if (value is Map) {
      return {for (final e in value.entries) e.key: _short(e.value)};
    }
    if (value is List) return [for (final e in value) _short(e)];
    return value;
  }
}
