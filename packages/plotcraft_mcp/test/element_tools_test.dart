import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late String project;
  late String chapter;

  setUp(() async {
    h = await Harness.start();
    final made = await h.makeProject('Livro');
    project = made.id;
    chapter = (await (await h.story(made)).chapters()).single.id;
  });
  tearDown(() => h.close());

  Future<Map<String, Object?>> create(Map<String, Object?> args) async =>
      (await h.call('create_element', {
            'project': project,
            ...args,
          })).ok['element']!
          as Map<String, Object?>;

  test('criar um personagem completo e lê-lo de volta', () async {
    final lia = await create({
      'id': 'lia',
      'type': 'character',
      'title': 'Lia',
    });
    final maria = await create({
      'id': 'maria',
      'type': 'character',
      'title': 'Maria',
      'summary': 'Corredora da pista de sal.',
      'aliases': ['Mari'],
      'tags': ['protagonista'],
      'color': '#7B5EA7',
      'icon': {'set': 'Feather', 'name': 'user'},
      'fields': {'age': '17', 'occupation': 'Corredora'},
      'sections': [
        {'title': 'Origem', 'markdown': 'Cresceu perto do mar.'},
      ],
      'relations': [
        {'target_id': 'lia', 'label': 'amiga de'},
      ],
      'mention_policy': {
        'auto': true,
        'ignored_terms': ['mari'],
      },
    });
    expect(maria['aliases'], ['Mari']);
    expect(maria['color'], '#7B5EA7');
    expect((maria['fields'] as Map)['age'], '17');
    expect(lia['revision'], isA<String>());

    final got = await h.call('get_element', {
      'project': project,
      'element_id': 'lia',
    });
    final incoming = (got.ok['element']! as Map)['incoming_relations']! as List;
    expect((incoming.single as Map)['title'], 'Maria');
    expect((incoming.single as Map)['label'], 'amiga de');

    final list = await h.call('list_elements', {
      'project': project,
      'query': 'mari',
    });
    expect((list.ok['elements']! as List).map((e) => (e as Map)['id']), [
      'maria',
    ]);
    expect(
      (await h.call('list_elements', {
        'project': project,
        'tag': 'protagonista',
      })).ok['count'],
      1,
    );
    expect(
      (await h.call('list_elements', {
        'project': project,
        'type': 'place',
      })).ok['count'],
      0,
    );
  });

  test(
    'validações: tipo, ícone, cor, id repetido e relação sem alvo',
    () async {
      expect(
        (await h.call('create_element', {
          'project': project,
          'type': 'zzz',
          'title': 'X',
        })).errorCode,
        'validation',
      );
      expect(
        (await h.call('create_element', {
          'project': project,
          'type': 'character',
          'title': 'X',
          'icon': {'set': 'Feather', 'name': 'nao_existe'},
        })).errorCode,
        'validation',
      );
      expect(
        (await h.call('create_element', {
          'project': project,
          'type': 'character',
          'title': 'X',
          'color': 'vermelho',
        })).errorCode,
        'validation',
      );
      await create({'id': 'a', 'type': 'note', 'title': 'A'});
      expect(
        (await h.call('create_element', {
          'project': project,
          'id': 'a',
          'type': 'note',
          'title': 'B',
        })).errorCode,
        'validation',
      );
      expect(
        (await h.call('create_element', {
          'project': project,
          'type': 'note',
          'title': 'C',
          'relations': [
            {'target_id': 'fantasma'},
          ],
        })).errorCode,
        'notFound',
      );
      expect(
        (await h.call('create_element', {
          'project': project,
          'id': 'a b',
          'type': 'note',
          'title': 'D',
        })).errorCode,
        'validation',
      );
    },
  );

  test(
    'atualizar: campos fazem merge, listas substituem, revisão protege',
    () async {
      final first = await create({
        'id': 'maria',
        'type': 'character',
        'title': 'Maria',
        'fields': {'age': '17', 'occupation': 'Corredora'},
        'tags': ['a', 'b'],
      });
      final updated = await h.call('update_element', {
        'project': project,
        'element_id': 'maria',
        'summary': 'Nova.',
        'fields': {'age': '18', 'occupation': ''},
        'tags': ['c'],
        'base_revision': first['revision'],
      });
      final element = updated.ok['element']! as Map;
      expect(element['fields'], {'age': '18'});
      expect(element['tags'], ['c']);
      expect(element['summary'], 'Nova.');

      final stale = await h.call('update_element', {
        'project': project,
        'element_id': 'maria',
        'summary': 'Velha.',
        'base_revision': first['revision'],
      });
      expect(stale.errorCode, 'conflict');
    },
  );

  test('relações, fases e seções: adicionar, alterar e remover', () async {
    await create({'id': 'maria', 'type': 'character', 'title': 'Maria'});
    await create({'id': 'lia', 'type': 'character', 'title': 'Lia'});

    var el =
        (await h.call('add_relation', {
              'project': project,
              'element_id': 'maria',
              'target_id': 'lia',
              'label': 'amiga de',
            })).ok['element']!
            as Map;
    final relationId =
        ((el['relations'] as List).single as Map)['id']! as String;
    el =
        (await h.call('update_relation', {
              'project': project,
              'element_id': 'maria',
              'relation_id': relationId,
              'reciprocal_label': 'treinadora de',
            })).ok['element']!
            as Map;
    expect(
      ((el['relations'] as List).single as Map)['reciprocal_label'],
      'treinadora de',
    );
    el =
        (await h.call('remove_relation', {
              'project': project,
              'element_id': 'maria',
              'relation_id': relationId,
            })).ok['element']!
            as Map;
    expect(el['relations'], isEmpty);

    el =
        (await h.call('add_phase', {
              'project': project,
              'element_id': 'maria',
              'title': 'Antes da corrida',
              'description': 'Insegura.',
              'anchor': {'kind': 'chapter', 'chapter_id': chapter},
              'field_overrides': {'age': '16'},
            })).ok['element']!
            as Map;
    final phaseId = ((el['phases'] as List).single as Map)['id']! as String;
    expect(
      (((el['phases'] as List).single as Map)['anchor'] as Map)['chapter_id'],
      chapter,
    );
    el =
        (await h.call('update_phase', {
              'project': project,
              'element_id': 'maria',
              'phase_id': phaseId,
              'description': 'Confiante.',
            })).ok['element']!
            as Map;
    final phase = (el['phases'] as List).single as Map;
    expect(phase['description'], 'Confiante.');
    expect(phase['title'], 'Antes da corrida');
    expect(phase['field_overrides'], {'age': '16'});

    final active = await h.call('get_active_phase', {
      'project': project,
      'element_id': 'maria',
      'chapter_id': chapter,
    });
    expect((active.ok['phase']! as Map)['id'], phaseId);
    final viaGet = await h.call('get_element', {
      'project': project,
      'element_id': 'maria',
      'chapter_id': chapter,
    });
    expect((viaGet.ok['element']! as Map)['active_phase_id'], phaseId);
    expect(
      (await h.call('add_phase', {
        'project': project,
        'element_id': 'maria',
        'title': 'Ruim',
        'anchor': {'kind': 'chapter'},
      })).errorCode,
      'validation',
    );
    el =
        (await h.call('remove_phase', {
              'project': project,
              'element_id': 'maria',
              'phase_id': phaseId,
            })).ok['element']!
            as Map;
    expect(el['phases'], isEmpty);

    el =
        (await h.call('add_section', {
              'project': project,
              'element_id': 'maria',
              'title': 'Origem',
              'markdown': 'Do mar.',
            })).ok['element']!
            as Map;
    final sectionId = ((el['sections'] as List).single as Map)['id']! as String;
    el =
        (await h.call('update_section', {
              'project': project,
              'element_id': 'maria',
              'section_id': sectionId,
              'markdown': 'Do vento.',
            })).ok['element']!
            as Map;
    expect(((el['sections'] as List).single as Map)['markdown'], 'Do vento.');
    el =
        (await h.call('remove_section', {
              'project': project,
              'element_id': 'maria',
              'section_id': sectionId,
            })).ok['element']!
            as Map;
    expect(el['sections'], isEmpty);
  });

  test(
    'remover elemento exige confirmação e limpa relações dos outros',
    () async {
      await create({'id': 'maria', 'type': 'character', 'title': 'Maria'});
      await create({
        'id': 'lia',
        'type': 'character',
        'title': 'Lia',
        'relations': [
          {'target_id': 'maria', 'label': 'amiga de'},
        ],
      });
      expect(
        (await h.call('delete_element', {
          'project': project,
          'element_id': 'maria',
        })).errorCode,
        'confirmationRequired',
      );
      await h.call('delete_element', {
        'project': project,
        'element_id': 'maria',
        'confirm': true,
        'confirm_name': 'Maria',
      });
      final lia =
          (await h.call('get_element', {
                'project': project,
                'element_id': 'lia',
              })).ok['element']!
              as Map;
      expect(lia['relations'], isEmpty);
      expect(
        (await h.call('get_element', {
          'project': project,
          'element_id': 'maria',
        })).errorCode,
        'notFound',
      );
    },
  );

  test('política de menções e referências no manuscrito', () async {
    await create({'id': 'maria', 'type': 'character', 'title': 'Maria'});
    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Maria correu. [[element:maria|Maria]] parou.',
    });
    final refs = await h.call('get_element_references', {
      'project': project,
      'element_id': 'maria',
    });
    expect(refs.ok['count'], 2);
    expect(refs.ok['linked'], 1);

    final policy = await h.call('set_mention_policy', {
      'project': project,
      'element_id': 'maria',
      'auto': false,
      'ignored_terms': ['maria'],
    });
    final stored = (policy.ok['element']! as Map)['mention_policy'] as Map;
    expect(stored['auto'], isFalse);
    expect(stored['ignored_terms'], ['maria']);
  });

  test('o tempo na história: define, lê, troca e remove', () async {
    final created = await create({
      'id': 'selamento',
      'type': 'event',
      'title': 'O Selamento',
      'time': {'label': 'Ano 1 da Era das Cinzas', 'position': 1},
    });
    expect(created['time'], {
      'label': 'Ano 1 da Era das Cinzas',
      'position': 1.0,
    });

    // Only the label: no position yet.
    var updated =
        (await h.call('update_element', {
              'project': project,
              'element_id': 'selamento',
              'time': {'label': 'Há trezentos anos'},
            })).ok['element']!
            as Map;
    expect(updated['time'], {'label': 'Há trezentos anos', 'position': null});

    // Not sending `time` leaves it alone.
    updated =
        (await h.call('update_element', {
              'project': project,
              'element_id': 'selamento',
              'summary': 'Guerra do fim da era.',
            })).ok['element']!
            as Map;
    expect((updated['time'] as Map)['label'], 'Há trezentos anos');

    // Empty removes it.
    updated =
        (await h.call('update_element', {
              'project': project,
              'element_id': 'selamento',
              'time': <String, Object?>{},
            })).ok['element']!
            as Map;
    expect(updated['time'], isNull);

    final bad = await h.call('update_element', {
      'project': project,
      'element_id': 'selamento',
      'time': {'position': 'tarde'},
    });
    expect(bad.isError, isTrue);
  });

  test(
    'detalhes que apontam para elementos: ids, títulos, tipo e erros',
    () async {
      await create({'id': 'pedralta', 'type': 'place', 'title': 'Pedralta'});
      await create({'id': 'cinzaluz', 'type': 'place', 'title': 'Cinzaluz'});
      await create({'id': 'dorrin', 'type': 'character', 'title': 'Dorrin'});

      // Titles are stored as ids; several places are allowed on an event.
      final event = await create({
        'id': 'viagem',
        'type': 'event',
        'title': 'A viagem',
        'fields': {'where': 'Pedralta, cinzaluz'},
      });
      expect((event['fields'] as Map)['where'], 'pedralta,cinzaluz');

      Future<ToolResult> where(String value) => h.call('update_element', {
        'project': project,
        'element_id': 'viagem',
        'fields': {'where': value},
      });
      expect((await where('fantasma')).isError, isTrue);
      expect((await where('dorrin')).isError, isTrue);

      // One element only for "leader".
      await create({'id': 'ordem', 'type': 'organization', 'title': 'Ordem'});
      final leader = await h.call('update_element', {
        'project': project,
        'element_id': 'ordem',
        'fields': {'leader': 'dorrin,pedralta'},
      });
      expect(leader.isError, isTrue);

      // Other updates do not trip over older text in the detail.
      final types = await h.call('list_element_types', {'project': project});
      final eventType = (types.ok['types']! as List).cast<Map>().firstWhere(
        (t) => t['id'] == 'event',
      );
      final whereField = (eventType['fields']! as List).cast<Map>().firstWhere(
        (f) => f['id'] == 'where',
      );
      expect(whereField['kind'], 'elements');
      expect(whereField['target_types'], ['place']);
    },
  );
}
