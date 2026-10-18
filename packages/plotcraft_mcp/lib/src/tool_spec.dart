import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';

import 'args.dart';
import 'context.dart';

/// What a tool does to the stories, which decides how it is presented to the
/// AI client and whether read-only mode allows it.
enum ToolKind {
  /// Only reads.
  read,

  /// Creates or changes content (reversible through the app's history or by
  /// writing again).
  write,

  /// Removes or overwrites something for good; needs explicit confirmation.
  destructive,
}

/// The input of one tool call.
class Call {
  Call(this.tool, this.args, this.context);

  final String tool;
  final Args args;
  final ToolContext context;

  String? _projectFolder;

  /// The workspace of the call's `project` argument. The folder is kept so a
  /// successful write can be logged against it.
  Future<StoryWorkspace> workspace() async {
    final story = await context.workspace(args.string('project'));
    _projectFolder = story.folder;
    return story;
  }
}

/// A result with extra content next to the JSON (for example an image).
class WithContent {
  const WithContent(this.data, this.content);

  final Map<String, Object?> data;
  final List<Content> content;
}

typedef ToolHandler = Future<Object?> Function(Call call);

/// A tool: its definition for the client and the code that runs it.
class ToolSpec {
  const ToolSpec({
    required this.name,
    required this.title,
    required this.description,
    required this.kind,
    required this.handler,
    this.properties = const {},
    this.required = const [],
    this.idempotent = false,
  });

  final String name;
  final String title;
  final String description;
  final ToolKind kind;
  final Map<String, Schema> properties;
  final List<String> required;
  final bool idempotent;
  final ToolHandler handler;

  Tool get definition => Tool(
    name: name,
    title: title,
    description: description,
    inputSchema: Schema.object(properties: properties, required: required),
    annotations: ToolAnnotations(
      title: title,
      readOnlyHint: kind == ToolKind.read,
      destructiveHint: kind == ToolKind.destructive,
      idempotentHint: idempotent,
      openWorldHint: false,
    ),
  );

  /// Runs the tool and turns its outcome, including every kind of failure,
  /// into a [CallToolResult].
  Future<CallToolResult> run(
    CallToolRequest request,
    ToolContext context,
  ) async {
    final call = Call(name, Args(request.arguments), context);
    try {
      if (kind != ToolKind.read) context.requireWritable();
      final result = await handler(call);
      if (kind != ToolKind.read && call._projectFolder != null) {
        await context.audit(call._projectFolder!, name, call.args.raw, result);
      }
      return _success(result);
    } on StoryError catch (error) {
      return _failure(error.code.name, error.message, error.hint);
    } on FormatException catch (error) {
      return _failure('validation', error.message, null);
    } on RangeError catch (error) {
      return _failure('validation', error.toString(), 'Check the offsets.');
    } on FileSystemException catch (error) {
      return _failure('io', '${error.message}: ${error.path}', null);
    } on StateError catch (error) {
      return _failure('conflict', error.message, null);
    } catch (error) {
      return _failure('internal', '$error', null);
    }
  }

  CallToolResult _success(Object? result) {
    if (result is WithContent) {
      return CallToolResult(
        content: [
          TextContent(text: _pretty(result.data)),
          ...result.content,
        ],
        structuredContent: result.data,
      );
    }
    final Map<String, Object?> data = switch (result) {
      null => {'ok': true},
      final Map<String, Object?> map => map,
      final List<Object?> list => {'items': list},
      _ => {'result': result},
    };
    return CallToolResult(
      content: [TextContent(text: _pretty(data))],
      structuredContent: data,
    );
  }

  CallToolResult _failure(String code, String message, String? hint) {
    final error = {'code': code, 'message': message, 'hint': ?hint};
    return CallToolResult(
      isError: true,
      content: [
        TextContent(text: _pretty({'error': error})),
      ],
      structuredContent: {'error': error},
    );
  }
}

String _pretty(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
