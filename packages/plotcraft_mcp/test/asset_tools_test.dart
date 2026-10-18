import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late String project;

  setUp(() async {
    h = await Harness.start();
    project = (await h.makeProject('Livro')).id;
  });
  tearDown(() => h.close());

  test('tipos personalizados: criar, usar, atualizar e excluir', () async {
    final listed = await h.call('list_element_types', {'project': project});
    final types = (listed.ok['types']! as List).cast<Map>();
    expect(types.where((t) => t['built_in'] == true), hasLength(8));
    expect(
      types.firstWhere((t) => t['id'] == 'character')['name'],
      'Character',
    );
    final fieldLabels =
        ((types.firstWhere((t) => t['id'] == 'character')['fields']) as List)
            .map((f) => (f as Map)['label']);
    expect(fieldLabels, contains('Occupation'));

    final created = await h.call('create_element_type', {
      'project': project,
      'name': 'Spell',
      'icon': {'set': 'RpgAwesome', 'name': 'fire'},
      'color': '#C0443F',
      'fields': [
        {'label': 'Level', 'kind': 'number'},
        {
          'label': 'School',
          'kind': 'choice',
          'options': ['Fire', 'Water'],
        },
        {'label': 'Level'},
      ],
    });
    final type = created.ok['type']! as Map;
    final id = type['id']! as String;
    final fields = (type['fields']! as List).cast<Map>();
    expect(fields.map((f) => f['id']), ['level', 'school', 'level_2']);
    expect(fields[1]['options'], ['Fire', 'Water']);

    final element = await h.call('create_element', {
      'project': project,
      'type': id,
      'title': 'Fireball',
      'fields': {'level': '3'},
    });
    expect(element.isError, isFalse);

    expect(
      (await h.call('delete_element_type', {
        'project': project,
        'type_id': id,
      })).errorCode,
      'confirmationRequired',
    );
    final inUse = await h.call('delete_element_type', {
      'project': project,
      'type_id': id,
      'confirm': true,
      'confirm_name': 'Spell',
    });
    expect(inUse.errorCode, 'validation');

    final renamed = await h.call('update_element_type', {
      'project': project,
      'type_id': id,
      'name': 'Magic',
    });
    expect((renamed.ok['type']! as Map)['name'], 'Magic');
    expect(((renamed.ok['type']! as Map)['fields'] as List), hasLength(3));

    await h.call('delete_element', {
      'project': project,
      'element_id': (element.ok['element']! as Map)['id'],
      'confirm': true,
      'confirm_name': 'Fireball',
    });
    final gone = await h.call('delete_element_type', {
      'project': project,
      'type_id': id,
      'confirm': true,
      'confirm_name': 'Magic',
    });
    expect(gone.isError, isFalse);
    expect(
      (await h.call('update_element_type', {
        'project': project,
        'type_id': 'character',
        'name': 'x',
      })).errorCode,
      'validation',
    );
    expect(
      (await h.call('create_element_type', {
        'project': project,
        'name': 'Bad',
        'fields': [
          {'label': 'X', 'kind': 'nope'},
        ],
      })).errorCode,
      'validation',
    );
  });

  test('ícones: conjuntos, busca e sugeridos', () async {
    final sets = (await h.call('list_icon_sets')).ok['sets']! as List;
    expect(sets.map((s) => (s as Map)['set']), contains('Feather'));
    final found = await h.call('search_icons', {
      'query': 'map pin',
      'set': 'Feather',
    });
    expect((found.ok['icons']! as List).first, {
      'set': 'Feather',
      'name': 'map_pin',
    });
    expect(
      (await h.call('search_icons', {'query': 'zzzzz'})).ok['icons'],
      isEmpty,
    );
    expect(
      (await h.call('search_icons', {'query': 'a', 'set': 'Nope'})).errorCode,
      'validation',
    );
    final limited = await h.call('search_icons', {'query': 'a', 'limit': 3});
    expect((limited.ok['icons']! as List), hasLength(3));
    expect(limited.ok['truncated'], isTrue);
    final suggested = await h.call('list_suggested_icons');
    expect((suggested.ok['groups']! as List), isNotEmpty);
  });

  test('galeria: importar por dados e por caminho, ver e remover', () async {
    final bytes = base64Encode([137, 80, 78, 71, 1, 2, 3]);
    final imported = await h.call('import_gallery_image_data', {
      'project': project,
      'file_name': 'retrato.png',
      'data_base64': bytes,
    });
    final image = imported.ok['image']! as Map;
    expect(image['file'], 'retrato.png');
    expect(File(image['path']! as String).existsSync(), isTrue);

    final source = File('${h.root.path}/fora.jpg')..writeAsBytesSync([1, 2, 3]);
    final byPath = await h.call('import_gallery_images', {
      'project': project,
      'paths': [source.path],
    });
    expect((byPath.ok['imported']! as List), hasLength(1));
    expect(
      (await h.call('list_gallery', {'project': project})).ok['images'],
      hasLength(2),
    );

    final viewed = await h.call('get_gallery_image', {
      'project': project,
      'image_id': image['id'],
    });
    final content = viewed.raw.content;
    expect(content, hasLength(2));
    expect((content[1] as Map)['mimeType'], 'image/png');
    expect((content[1] as Map)['type'], 'image');

    expect(
      (await h.call('import_gallery_image_data', {
        'project': project,
        'file_name': 'x.png',
        'data_base64': '***',
      })).errorCode,
      'validation',
    );
    expect(
      (await h.call('import_gallery_images', {
        'project': project,
        'paths': ['/nao/existe.png'],
      })).errorCode,
      'validation',
    );

    expect(
      (await h.call('remove_gallery_image', {
        'project': project,
        'image_id': image['id'],
      })).errorCode,
      'confirmationRequired',
    );
    await h.call('remove_gallery_image', {
      'project': project,
      'image_id': image['id'],
      'confirm': true,
      'confirm_name': 'retrato.png',
    });
    expect(File(image['path']! as String).existsSync(), isFalse);
  });

  test('imagens de elementos: por id da galeria e por caminho', () async {
    final source = File('${h.root.path}/capa.png')..writeAsBytesSync([1, 2, 3]);
    await h.call('create_element', {
      'project': project,
      'id': 'maria',
      'type': 'character',
      'title': 'Maria',
    });
    final set = await h.call('set_element_images', {
      'project': project,
      'element_id': 'maria',
      'images': [
        {'path': source.path},
      ],
    });
    final images = (set.ok['element']! as Map)['images']! as List;
    expect(images, hasLength(1));
    final galleryId = (images.single as Map)['gallery_id'];
    expect(
      ((await h.call('list_gallery', {'project': project})).ok['images']!
              as List)
          .map((i) => (i as Map)['id']),
      contains(galleryId),
    );
    expect(
      (await h.call('set_element_images', {
        'project': project,
        'element_id': 'maria',
        'images': [
          {'bad': 1},
        ],
      })).errorCode,
      'validation',
    );
  });

  test(
    'fontes do projeto: listar, adicionar arquivos inválidos e remover',
    () async {
      expect(
        (await h.call('list_project_fonts', {'project': project})).ok['fonts'],
        isEmpty,
      );
      final notFont = File('${h.root.path}/falsa.ttf')
        ..writeAsStringSync('nada');
      final added = await h.call('add_project_fonts', {
        'project': project,
        'paths': [notFont.path],
      });
      expect(added.ok['added'], isEmpty);
      expect(added.ok['skipped'], 1);
      expect(
        (await h.call('remove_project_font', {
          'project': project,
          'file': 'falsa.ttf',
          'confirm': true,
          'confirm_name': 'falsa.ttf',
        })).errorCode,
        'notFound',
      );
    },
  );
}
