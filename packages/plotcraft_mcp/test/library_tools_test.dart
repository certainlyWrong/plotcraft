import 'dart:io';

import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  setUp(() async => h = await Harness.start());
  tearDown(() => h.close());

  test('lista as ferramentas com anotações de segurança', () async {
    final tools = (await h.connection.listTools()).tools;
    final byName = {for (final tool in tools) tool.name: tool};
    expect(byName['list_projects']!.toolAnnotations!.readOnlyHint, isTrue);
    expect(byName['create_project']!.toolAnnotations!.readOnlyHint, isFalse);
    expect(byName['delete_project']!.toolAnnotations!.destructiveHint, isTrue);
    for (final tool in tools) {
      expect(tool.description, isNotEmpty, reason: tool.name);
    }
  });

  test('criar, listar, ler e atualizar um projeto', () async {
    final created = await h.call('create_project', {
      'title': 'A Corredora',
      'author': 'Ana',
      'tags': ['corrida'],
      'format': 'book',
    });
    final project = created.ok['project']! as Map;
    final id = project['id']! as String;
    expect(project['title'], 'A Corredora');
    expect(Directory(project['folder']! as String).existsSync(), isTrue);

    final list = await h.call('list_projects', {'query': 'corred'});
    expect((list.ok['projects']! as List), hasLength(1));
    expect(
      ((await h.call('list_projects', {'query': 'zzz'})).ok['projects']!
          as List),
      isEmpty,
    );

    final got = await h.call('get_project', {'project': id});
    expect((got.ok['overview']! as Map)['chapters'], 1);
    // By title, case-insensitively, too.
    expect(
      (await h.call('get_project', {'project': 'a corredora'})).isError,
      isFalse,
    );

    final updated = await h.call('update_project', {
      'project': id,
      'subtitle': 'Sal e vento',
      'tags': ['corrida', 'sal'],
    });
    final after = updated.ok['project']! as Map;
    expect(after['subtitle'], 'Sal e vento');
    expect(after['title'], 'A Corredora');
    expect(after['tags'], ['corrida', 'sal']);
  });

  test(
    'erros claros: projeto inexistente, título curto, formato ruim',
    () async {
      final missing = await h.call('get_project', {'project': 'nao-existe'});
      expect(missing.isError, isTrue);
      expect(missing.errorCode, 'notFound');

      final short = await h.call('create_project', {'title': 'ab'});
      expect(short.errorCode, 'validation');
      final format = await h.call('create_project', {
        'title': 'Titulo',
        'format': 'zzz',
      });
      expect(format.errorCode, 'validation');
      final noTitle = await h.call('create_project', {});
      expect(noTitle.isError, isTrue);
    },
  );

  test('excluir exige confirmação com o título e apaga a pasta', () async {
    final project = await h.makeProject('Para apagar');
    final folder = project.directoryPath!;

    final refused = await h.call('delete_project', {'project': project.id});
    expect(refused.errorCode, 'confirmationRequired');
    final wrong = await h.call('delete_project', {
      'project': project.id,
      'confirm': true,
      'confirm_name': 'outro',
    });
    expect(wrong.errorCode, 'confirmationRequired');
    expect(Directory(folder).existsSync(), isTrue);

    final done = await h.call('delete_project', {
      'project': project.id,
      'confirm': true,
      'confirm_name': 'Para apagar',
    });
    expect(done.ok['deleted'], project.id);
    expect(Directory(folder).existsSync(), isFalse);
  });

  test('toda escrita fica registrada no log do projeto', () async {
    final project = await h.makeProject('Com log');
    await h.call('update_project', {'project': project.id, 'genre': 'Drama'});
    final log = File('${project.directoryPath}/.plotcraft/mcp-log.jsonl');
    expect(log.existsSync(), isTrue);
    expect(log.readAsStringSync(), contains('update_project'));
  });

  test('o modo somente leitura recusa escrever mas deixa ler', () async {
    final readOnly = await Harness.start(readOnly: true);
    addTearDown(readOnly.close);
    final project = await readOnly.makeProject('Só leitura');
    final denied = await readOnly.call('update_project', {
      'project': project.id,
      'genre': 'x',
    });
    expect(denied.errorCode, 'readOnly');
    expect(
      (await readOnly.call('get_project', {'project': project.id})).isError,
      isFalse,
    );
    expect((await readOnly.call('get_server_info')).ok['read_only'], isTrue);
  });
}
