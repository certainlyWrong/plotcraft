import 'dart:convert';
import 'dart:io';

import 'package:plotcraft_core/features/app_bridge/app_bridge_client.dart';
import 'package:plotcraft_core/features/app_bridge/app_bridge_server.dart';
import 'package:plotcraft_core/features/app_bridge/bridge_protocol.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late AppBridgeServer server;
  late AppBridgeClient client;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plotcraft-bridge-');
    server = AppBridgeServer(
      root.path,
      version: '1.2.3',
      status: () => {'theme': 'violet'},
      heartbeat: const Duration(milliseconds: 100),
      poll: const Duration(milliseconds: 30),
      handlers: {
        'echo': (params) async => {'you_sent': params},
        'boom': (params) async => throw const BridgeError('unsupported', 'No.'),
        'crash': (params) async => throw StateError('bad'),
      },
    );
    client = AppBridgeClient(
      root.path,
      timeout: const Duration(seconds: 3),
      poll: const Duration(milliseconds: 20),
      staleAfter: const Duration(seconds: 1),
    );
  });

  tearDown(() async {
    await server.stop();
    await root.delete(recursive: true);
  });

  test('sem o app, o cliente sabe que ele não está rodando', () async {
    expect(await client.appStatus(), isNull);
    await expectLater(
      client.call('echo'),
      throwsA(
        isA<BridgeError>().having((e) => e.code, 'code', 'app_not_running'),
      ),
    );
  });

  test('o batimento mostra versão e estado e some quando o app para', () async {
    await server.start();
    final status = await client.appStatus();
    expect(status!['version'], '1.2.3');
    expect(status['theme'], 'violet');
    await server.stop();
    expect(await client.appStatus(), isNull);
  });

  test('um batimento antigo (app que travou) conta como app fechado', () async {
    await server.start();
    await server.stop();
    final folder = BridgeFolder(root.path);
    await folder.appFile.writeAsString(
      jsonEncode({
        'updated_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      }),
    );
    expect(await client.appStatus(), isNull);
  });

  test('pedido e resposta, erro do app e método desconhecido', () async {
    await server.start();
    final ok = await client.call('echo', {'a': 1});
    expect((ok['you_sent']! as Map)['a'], 1);

    await expectLater(
      client.call('boom'),
      throwsA(isA<BridgeError>().having((e) => e.code, 'code', 'unsupported')),
    );
    await expectLater(
      client.call('crash'),
      throwsA(isA<BridgeError>().having((e) => e.code, 'code', 'internal')),
    );
    await expectLater(
      client.call('nope'),
      throwsA(
        isA<BridgeError>().having((e) => e.code, 'code', 'unknown_method'),
      ),
    );
    // Nothing is left behind.
    final folder = BridgeFolder(root.path);
    expect(folder.inbox.listSync().whereType<File>(), isEmpty);
    expect(folder.outbox.listSync().whereType<File>(), isEmpty);
  });

  test(
    'várias chamadas ao mesmo tempo recebem cada uma a sua resposta',
    () async {
      await server.start();
      final results = await Future.wait([
        for (var i = 0; i < 6; i++) client.call('echo', {'n': i}),
      ]);
      expect(
        [for (final r in results) (r['you_sent']! as Map)['n']],
        [0, 1, 2, 3, 4, 5],
      );
    },
  );

  test('sem resposta o cliente desiste e limpa o pedido', () async {
    await server.start();
    final impatient = AppBridgeClient(
      root.path,
      timeout: const Duration(milliseconds: 300),
      poll: const Duration(milliseconds: 20),
      staleAfter: const Duration(seconds: 5),
    );
    // A server that never answers: stop polling but keep the heartbeat file.
    final silent = AppBridgeServer(
      root.path,
      handlers: {
        'slow': (params) => Future<Object?>.delayed(const Duration(seconds: 5)),
      },
      poll: const Duration(hours: 1),
    );
    await server.stop();
    await silent.start();
    await expectLater(
      impatient.call('slow'),
      throwsA(isA<BridgeError>().having((e) => e.code, 'code', 'timeout')),
    );
    expect(BridgeFolder(root.path).inbox.listSync().whereType<File>(), isEmpty);
    await silent.stop();
  });
}
