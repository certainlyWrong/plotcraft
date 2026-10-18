import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

NarrativeElement _element(
  String id,
  String title, {
  List<String> aliases = const [],
}) => NarrativeElement(
  id: id,
  typeId: 'character',
  title: title,
  summary: '',
  aliases: aliases,
  sections: const [],
  phases: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

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

  Future<String> read([String format = 'markdown']) async =>
      (await h.call('get_chapter', {
            'project': project,
            'chapter_id': chapter,
            'format': format,
          })).ok['content']!
          as String;

  test('escrever, ler em markdown e em texto, e a revisão muda', () async {
    final first = await h.call('get_chapter', {
      'project': project,
      'chapter_id': chapter,
    });
    final revision0 = first.ok['revision']! as String;
    final written = await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': '# Capítulo um\n\nMaria correu pela **pista** de sal.',
    });
    expect(written.ok['words'], 8);
    expect(written.ok['revision'], isNot(revision0));
    expect(await read(), contains('Maria correu pela **pista** de sal.'));
    expect(await read('text'), contains('Maria correu'));
    final delta = await h.call('get_chapter', {
      'project': project,
      'chapter_id': chapter,
      'format': 'delta',
    });
    expect(delta.ok['content'], isA<List>());
  });

  test('substituir texto existente exige a revisão; anexar não', () async {
    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Primeiro parágrafo.',
    });
    final noRevision = await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Novo.',
    });
    expect(noRevision.errorCode, 'validation');

    final appended = await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Segundo parágrafo.',
      'mode': 'append',
    });
    expect(appended.isError, isFalse);
    final markdown = await read();
    expect(markdown.indexOf('Primeiro'), lessThan(markdown.indexOf('Segundo')));

    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Abertura.',
      'mode': 'prepend',
    });
    expect((await read()).trimLeft(), startsWith('Abertura.'));

    final stale = await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Velho.',
      'base_revision': 'antiga',
    });
    expect(stale.errorCode, 'conflict');
  });

  test('edit_chapter aplica operações em ordem e é tudo ou nada', () async {
    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'O sal e o mar. O sal volta.',
    });
    final edited = await h.call('edit_chapter', {
      'project': project,
      'chapter_id': chapter,
      'operations': [
        {
          'op': 'replace_text',
          'find': 'sal',
          'replace': 'vento',
          'occurrence': 'all',
        },
        {'op': 'insert_after_text', 'find': 'mar', 'text': ' azul'},
        {
          'op': 'format_text',
          'find': 'vento',
          'bold': true,
          'color': '#FF0000',
        },
      ],
    });
    final applied = edited.ok['applied']! as List;
    expect((applied.first as Map)['matches'], 2);
    expect(
      await read('text'),
      startsWith('O vento e o mar azul. O vento volta.'),
    );
    final delta =
        (await h.call('get_chapter', {
              'project': project,
              'chapter_id': chapter,
              'format': 'delta',
            })).ok['content']!
            as List;
    expect(
      delta.any((op) => (op as Map)['attributes']?['bold'] == true),
      isTrue,
    );

    final before = await read('text');
    final failed = await h.call('edit_chapter', {
      'project': project,
      'chapter_id': chapter,
      'operations': [
        {
          'op': 'replace_text',
          'find': 'vento',
          'replace': 'brisa',
          'occurrence': 1,
        },
        {'op': 'replace_text', 'find': 'inexistente', 'replace': 'x'},
      ],
    });
    expect(failed.errorCode, 'notFound');
    expect(await read('text'), before);

    final unknown = await h.call('edit_chapter', {
      'project': project,
      'chapter_id': chapter,
      'operations': [
        {'op': 'explodir'},
      ],
    });
    expect(unknown.errorCode, 'validation');
  });

  test(
    'capítulos: adicionar, renomear, reordenar e remover com confirmação',
    () async {
      final added = await h.call('add_chapter', {
        'project': project,
        'title': 'Dois',
        'markdown': 'Texto do dois.',
      });
      final second = added.ok['new_chapter_id']! as String;
      expect(((added.ok['chapters']! as List)).length, 2);

      await h.call('rename_chapter', {
        'project': project,
        'chapter_id': second,
        'title': 'Segundo',
      });
      final reordered = await h.call('reorder_chapters', {
        'project': project,
        'chapter_ids': [second, chapter],
      });
      expect(
        ((reordered.ok['chapters']! as List).first as Map)['title'],
        'Segundo',
      );
      expect(
        (await h.call('reorder_chapters', {
          'project': project,
          'chapter_ids': [chapter],
        })).errorCode,
        'validation',
      );

      expect(
        (await h.call('remove_chapter', {
          'project': project,
          'chapter_id': second,
        })).errorCode,
        'confirmationRequired',
      );
      final removed = await h.call('remove_chapter', {
        'project': project,
        'chapter_id': second,
        'confirm': true,
        'confirm_name': 'Segundo',
      });
      expect((removed.ok['chapters']! as List), hasLength(1));
      expect(
        (await h.call('remove_chapter', {
          'project': project,
          'chapter_id': chapter,
          'confirm': true,
          'confirm_name': 'Chapter 1',
        })).errorCode,
        'validation',
      );
    },
  );

  test('buscar, substituir (simulação por padrão) e estatísticas', () async {
    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Sal no vento. Mais sal.',
    });
    final found = await h.call('search_manuscript', {
      'project': project,
      'query': 'sal',
    });
    expect(found.ok['count'], 2);

    final dry = await h.call('replace_in_manuscript', {
      'project': project,
      'find': 'sal',
      'replace': 'areia',
    });
    expect(dry.ok['dry_run'], isTrue);
    expect(dry.ok['total'], 2);
    expect(await read('text'), contains('Sal no vento'));

    await h.call('replace_in_manuscript', {
      'project': project,
      'find': 'sal',
      'replace': 'areia',
      'dry_run': false,
    });
    expect(await read('text'), contains('areia no vento. Mais areia.'));

    final stats = await h.call('get_manuscript_stats', {'project': project});
    expect(stats.ok['total_words'], 5);
    expect(stats.ok['estimated_reading_minutes'], 1);
  });

  test(
    'ligar nomes detectados a elementos e inserir divisor e imagem',
    () async {
      final made = await h.story((await h.makeProjectLookup(project)));
      await made.saveElement(_element('maria', 'Maria', aliases: ['Mari']));
      await h.call('write_chapter', {
        'project': project,
        'chapter_id': chapter,
        'markdown': 'Maria correu. Mari parou.',
      });
      final dry = await h.call('link_mentions', {
        'project': project,
        'dry_run': true,
      });
      expect(dry.ok['total'], 2);
      expect(
        (await h.call('get_chapter', {
          'project': project,
          'chapter_id': chapter,
        })).ok['elements_linked'],
        isEmpty,
      );

      await h.call('link_mentions', {'project': project});
      final linked = await h.call('get_chapter', {
        'project': project,
        'chapter_id': chapter,
      });
      expect(linked.ok['elements_linked'], ['maria']);
      expect(linked.ok['content'], contains('[[element:maria|Maria]]'));

      final divider = await h.call('edit_chapter', {
        'project': project,
        'chapter_id': chapter,
        'operations': [
          {'op': 'insert_divider', 'after_text': 'correu.'},
        ],
      });
      expect(divider.isError, isFalse);
      expect(await read(), contains('---'));
    },
  );
}
