import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:test/test.dart';

/// Starts the real executable and talks to it over stdio, like a client such
/// as Claude Code does.
void main() {
  late Directory root;
  late Process process;
  late MCPClient client;
  late ServerConnection server;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plotcraft-e2e-');
    process = await Process.start('dart', [
      'run',
      'bin/plotcraft_mcp.dart',
      '--root',
      root.path,
    ]);
    unawaited(process.stderr.drain<void>());
    client = MCPClient(Implementation(name: 'e2e', version: '0'));
    server = client.connectServer(
      stdioChannel(input: process.stdout, output: process.stdin),
    );
    await server.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    server.notifyInitialized();
  });

  tearDown(() async {
    await client.shutdown();
    process.kill();
    await root.delete(recursive: true);
  });

  test('um fluxo completo pelo executável: criar, escrever e ler', () async {
    final tools = (await server.listTools()).tools;
    expect(tools.length, greaterThan(40));
    expect(
      tools.map((t) => t.name),
      containsAll(['create_project', 'write_chapter', 'create_element']),
    );

    Future<Map<String, Object?>> call(
      String name,
      Map<String, Object?> args,
    ) async {
      final result = await server.callTool(
        CallToolRequest(name: name, arguments: args),
      );
      expect(
        result.isError ?? false,
        isFalse,
        reason: jsonEncode(result.structuredContent),
      );
      return result.structuredContent!;
    }

    final created = await call('create_project', {
      'title': 'Livro E2E',
      'tags': ['teste'],
    });
    final id = (created['project']! as Map)['id']! as String;
    final chapters = await call('list_chapters', {'project': id});
    final chapter =
        ((chapters['chapters']! as List).single as Map)['id']! as String;
    await call('create_element', {
      'project': id,
      'id': 'ana',
      'type': 'character',
      'title': 'Ana',
    });
    await call('write_chapter', {
      'project': id,
      'chapter_id': chapter,
      'markdown': 'Ana chegou. [[element:ana|Ana]] sorriu.',
    });
    final read = await call('get_chapter', {
      'project': id,
      'chapter_id': chapter,
    });
    expect(read['content'], contains('[[element:ana|Ana]]'));
    expect(read['elements_linked'], ['ana']);

    // The files are the ones the app reads.
    final folder = (created['project']! as Map)['folder']! as String;
    final delta = File('$folder/content/book/chapters/$chapter.delta.json');
    expect(delta.existsSync(), isTrue);
    expect(
      File('$folder/content/narrative/elements/ana.json').existsSync(),
      isTrue,
    );
  });

  test('sem pasta de projetos o executável avisa e sai com erro', () async {
    final result = await Process.run('dart', ['run', 'bin/plotcraft_mcp.dart']);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('--root'));
  });
}
