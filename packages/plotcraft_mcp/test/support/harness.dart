import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:plotcraft_core/features/project_workspace/services/story_workspace.dart';
import 'package:plotcraft_core/features/projects/data/project_creation_service.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';
import 'package:plotcraft_mcp/plotcraft_mcp.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

/// A server and a client connected in memory, over a temporary projects
/// folder.
class Harness {
  Harness._(this.root, this.server, this.client, this.connection);

  final Directory root;
  final PlotcraftMcpServer server;
  final MCPClient client;
  final ServerConnection connection;

  static Future<Harness> start({bool readOnly = false}) async {
    final root = await Directory.systemTemp.createTemp('plotcraft-mcp-');
    final channel = StreamChannelController<String>(sync: true);
    final server = PlotcraftMcpServer(
      channel.local,
      ServerConfig(root: root.path, readOnly: readOnly),
    );
    final client = MCPClient(Implementation(name: 'test', version: '0'));
    final connection = client.connectServer(channel.foreign);
    await connection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    connection.notifyInitialized();
    return Harness._(root, server, client, connection);
  }

  Future<void> close() async {
    await client.shutdown();
    await server.shutdown();
    await root.delete(recursive: true);
  }

  /// Creates a project directly (not through the server) and returns it.
  Future<StoryProject> makeProject(String title) =>
      ProjectCreationService().create(
        ProjectMetadataInput(
          title: title,
          subtitle: '',
          author: '',
          description: '',
          genre: '',
          tags: const [],
          coverIndex: 0,
        ),
        root.path,
      );

  Future<StoryWorkspace> story(StoryProject project) =>
      StoryWorkspace.open(project);

  /// Calls a tool and returns its result.
  Future<ToolResult> call(
    String name, [
    Map<String, Object?>? arguments,
  ]) async {
    final result = await connection.callTool(
      CallToolRequest(name: name, arguments: arguments),
    );
    return ToolResult(result);
  }
}

class ToolResult {
  ToolResult(this.raw);

  final CallToolResult raw;

  bool get isError => raw.isError ?? false;

  Map<String, Object?> get data =>
      raw.structuredContent ??
      (jsonDecode((raw.content.first as TextContent).text)
          as Map<String, Object?>);

  String get errorCode => (data['error']! as Map)['code']! as String;

  /// The successful payload; fails the test when the call was an error.
  Map<String, Object?> get ok {
    if (isError) fail('Tool failed: ${data['error']}');
    return data;
  }
}
