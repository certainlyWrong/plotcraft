import 'package:plotcraft_core/features/app_bridge/app_bridge_server.dart';
import 'package:plotcraft_core/features/app_bridge/bridge_protocol.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late AppBridgeServer app;
  final received = <String, Map<String, Object?>>{};

  setUp(() async {
    received.clear();
    h = await Harness.start();
    app = AppBridgeServer(
      h.root.path,
      version: '9.9',
      status: () => {'theme': 'violet', 'language': 'pt'},
      heartbeat: const Duration(milliseconds: 100),
      poll: const Duration(milliseconds: 30),
      handlers: {
        'get_preferences': (params) async => {
          'theme': 'violet',
          'themes': ['violet', 'paper'],
        },
        'list_themes': (params) async => {
          'themes': [
            {'id': 'violet', 'name': 'Violet'},
          ],
        },
        'set_theme': (params) async {
          received['set_theme'] = params;
          return {'theme': params['theme_id']};
        },
        'set_projects_root': (params) async => throw const BridgeError(
          'unsupported',
          'Use the Preferences screen.',
        ),
        'open_in_app': (params) async {
          received['open_in_app'] = params;
          return {'opened': true};
        },
        'spell_check': (params) async => {
          'misspellings': [
            {
              'start': 0,
              'end': 5,
              'word': 'errro',
              'suggestions': ['erro'],
            },
          ],
        },
        'spell_suggest': (params) async => {
          'suggestions': ['erro'],
        },
        'spell_learn': (params) async {
          received['spell_learn'] = params;
          return {'learned': params['word']};
        },
      },
    );
  });

  tearDown(() async {
    await app.stop();
    await h.close();
  });

  test(
    'sem o app: o status diz que não roda e as outras ferramentas avisam',
    () async {
      final status = await h.call('get_app_status');
      expect(status.ok['running'], isFalse);
      final denied = await h.call('set_theme', {'theme_id': 'paper'});
      expect(denied.errorCode, 'appNotRunning');
      expect(
        ((denied.data['error']! as Map)['hint']! as String),
        contains(h.root.path),
      );
      // What does not need the app keeps working.
      expect((await h.call('list_projects')).isError, isFalse);
    },
  );

  test('com o app: status, preferências, tema e erros do app', () async {
    await app.start();
    final status = await h.call('get_app_status');
    expect(status.ok['running'], isTrue);
    expect((status.ok['status']! as Map)['version'], '9.9');

    expect((await h.call('get_preferences')).ok['theme'], 'violet');
    expect(((await h.call('list_themes')).ok['themes']! as List), hasLength(1));
    final changed = await h.call('set_theme', {'theme_id': 'paper'});
    expect(changed.ok['theme'], 'paper');
    expect(received['set_theme'], {'theme_id': 'paper'});

    final unsupported = await h.call('set_projects_root', {'path': '/x'});
    expect(unsupported.errorCode, 'unsupported');
  });

  test('abrir no app resolve o projeto e repassa o id', () async {
    await app.start();
    final project = await h.makeProject('Para abrir');
    final result = await h.call('open_in_app', {
      'project': 'Para abrir',
      'chapter_id': 'c1',
      'start': 3,
      'end': 8,
    });
    expect(result.ok['opened'], isTrue);
    expect(received['open_in_app'], {
      'project_id': project.id,
      'chapter_id': 'c1',
      'element_id': null,
      'start': 3,
      'end': 8,
      'view': null,
      'fullscreen': null,
    });
    expect(
      (await h.call('open_in_app', {'project': 'nao existe'})).errorCode,
      'notFound',
    );
  });

  test('corretor: verificar, sugerir e ensinar uma palavra', () async {
    await app.start();
    final checked = await h.call('spell_check_text', {'text': 'errro aqui'});
    expect(
      ((checked.ok['misspellings']! as List).single as Map)['word'],
      'errro',
    );
    expect(
      (await h.call('suggest_spelling', {'word': 'errro'})).ok['suggestions'],
      ['erro'],
    );
    expect((await h.call('learn_word', {'word': 'Lia'})).ok['learned'], 'Lia');
    expect(received['spell_learn'], {'word': 'Lia'});
  });

  test('no modo somente leitura mudar o app é recusado', () async {
    final readOnly = await Harness.start(readOnly: true);
    addTearDown(readOnly.close);
    expect(
      (await readOnly.call('set_theme', {'theme_id': 'paper'})).errorCode,
      'readOnly',
    );
    expect(
      (await readOnly.call('learn_word', {'word': 'x'})).errorCode,
      'readOnly',
    );
  });
}
