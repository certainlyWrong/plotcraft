import 'dart:io';

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/delta_to_markdown.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/markdown_to_delta.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';

String? _fileOf(String id) => id == 'g1' ? 'foto da pista.png' : null;
String? _idOf(String file) => file == 'foto da pista.png' ? 'g1' : null;

const _toDelta = MarkdownToDelta(galleryId: _idOf);
const _toMarkdown = DeltaToMarkdown(galleryFile: _fileOf);

String _roundTrip(String markdown) =>
    _toMarkdown.convert(_toDelta.convert(markdown));

void main() {
  group('markdown -> delta -> markdown mantém o texto', () {
    final corpus = <String, String>{
      'títulos e parágrafos': '# A história\n\nTexto original.\n\n## Capítulo\n\nOutro parágrafo.\n',
      'ênfase':
          'Um **negrito**, um *itálico*, um ~~riscado~~ e <u>sublinhado</u>.\n',
      'ênfase combinada': 'Texto ***forte e inclinado*** aqui.\n',
      'código em linha': 'Use `print()` para ver.\n',
      'link': 'Veja [o site](https://exemplo.com/a%20b) agora.\n',
      'lista simples': '- um\n- dois\n- três\n',
      'lista numerada': '1. primeiro\n2. segundo\n3. terceiro\n',
      'lista de tarefas': '- [ ] fazer\n- [x] feito\n',
      'listas aninhadas': '- a\n    - b\n        - c\n- d\n',
      'citação': '> Uma frase\n>\n> Outra frase\n',
      'bloco de código': '```\nlinha 1\nlinha 2\n```\n',
      'divisor': 'Antes\n\n---\n\nDepois\n',
      'menção': 'Maria falou com [[element:lia|Lia]] ontem.\n',
      'menção com ênfase ao lado': 'Veja **[[element:lia|Lia]]** de novo.\n',
      'imagem da galeria': 'Olhe:\n\n![](gallery/foto%20da%20pista.png)\n',
      'imagem externa': '![](https://exemplo.com/a.png)\n',
      'acentos e símbolos': 'Ação, coração e "aspas" — travessão… tudo bem.\n',
      'caracteres especiais escapados':
          r'Um \* asterisco, um \_ sublinhado, \[colchetes\] e \`crase\`.'
          '\n',
    };
    corpus.forEach((name, markdown) {
      test(name, () => expect(_roundTrip(markdown), markdown));
    });
  });

  group('delta -> markdown -> delta mantém o documento', () {
    void check(String name, Delta delta) {
      test(name, () {
        final back = _toDelta.convert(_toMarkdown.convert(delta));
        expect(back.toJson(), delta.toJson());
      });
    }

    check('parágrafo simples', Delta()..insert('Olá mundo\n'));
    check(
      'negrito no meio',
      Delta()
        ..insert('Um ')
        ..insert('forte', {'bold': true})
        ..insert(' texto\n'),
    );
    check(
      'cabeçalho e lista',
      Delta()
        ..insert('Título')
        ..insert('\n', {'header': 2})
        ..insert('item 1')
        ..insert('\n', {'list': 'bullet'})
        ..insert('item 2')
        ..insert('\n', {'list': 'bullet'}),
    );
    check(
      'lista numerada e aninhada',
      Delta()
        ..insert('um')
        ..insert('\n', {'list': 'ordered'})
        ..insert('um.a')
        ..insert('\n', {'list': 'ordered', 'indent': 1})
        ..insert('dois')
        ..insert('\n', {'list': 'ordered'}),
    );
    check(
      'menção a um elemento',
      Delta()
        ..insert('Ela viu ')
        ..insert('Lia', {
          RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
        })
        ..insert('.\n'),
    );
    check(
      'imagem da galeria em linha própria',
      Delta()
        ..insert(RichDocument.galleryImage('g1'))
        ..insert('\n'),
    );
    check(
      'código em bloco e em linha',
      Delta()
        ..insert('x = 1')
        ..insert('\n', {'code-block': true})
        ..insert('y = 2')
        ..insert('\n', {'code-block': true})
        ..insert('e ')
        ..insert('inline', {'code': true})
        ..insert('\n'),
    );
  });

  group('particularidades', () {
    test('o texto real de "A Corredora" não muda', () {
      const real = '# A Corredora\n\n';
      expect(_toDelta.convert(real).toJson(), [
        {'insert': 'A Corredora'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
      ]);
      expect(_roundTrip(real), '# A Corredora\n');
    });

    test('espaços na borda da ênfase ficam fora dos marcadores', () {
      final delta = Delta()
        ..insert('a')
        ..insert(' dentro ', {'italic': true})
        ..insert('b\n');
      final markdown = _toMarkdown.convert(delta);
      expect(markdown, 'a *dentro* b\n');
      // Same text and same italic word, with the spaces moved outside.
      final back = _toDelta.convert(markdown);
      expect(RichDocument.plainText(back), 'a dentro b\n');
      expect(back.toList()[1].attributes, {'italic': true});
      expect(back.toList()[1].data, 'dentro');
    });

    test('o capítulo real de "A Corredora" mantém texto e menção', () {
      final source = File('test/fixtures/chapter_a_corredora.md')
          .readAsStringSync();
      final delta = _toDelta.convert(source);
      final mentions = [
        for (final op in delta.toList())
          if (op.attributes?[RichDocument.mentionKey] != null)
            (op.attributes![RichDocument.mentionKey] as Map)['id'],
      ];
      expect(mentions, ['hnbble1fpk']);
      final words = RegExp(r'\S+');
      String normalize(String text) =>
          words.allMatches(text).map((m) => m.group(0)).join(' ');
      final markdown = _toMarkdown.convert(delta);
      // Blank lines may differ; every word and the mention marker survive.
      expect(normalize(markdown), normalize(source));
      expect(markdown, contains('[[element:hnbble1fpk|AAAAA]]'));
    });

    test('markdown vazio vira um documento vazio', () {
      expect(_toDelta.convert('').toJson(), [
        {'insert': '\n'},
      ]);
      expect(_toDelta.convert('   \n\n').toJson(), [
        {'insert': '\n'},
      ]);
      expect(_toMarkdown.convert(RichDocument.empty()), '');
    });

    test('cor, fonte e alinhamento ficam só no Delta', () {
      final delta = Delta()
        ..insert('colorido', {'color': '#ff0000', 'font': 'Lora', 'size': '18'})
        ..insert('\n', {'align': 'center'});
      expect(_toMarkdown.convert(delta), 'colorido\n');
    });

    test('parágrafos vazios não geram linhas em branco extras', () {
      final delta = Delta()..insert('a\n\n\nb\n');
      expect(_toMarkdown.convert(delta), 'a\n\nb\n');
    });

    test('imagem de galeria desconhecida usa o esquema gallery://', () {
      final delta = Delta()
        ..insert(RichDocument.galleryImage('sumiu'))
        ..insert('\n');
      expect(_toMarkdown.convert(delta), '![](gallery://sumiu)\n');
      expect(
        _toDelta.convert('![](gallery://sumiu)\n').toJson().first['insert'],
        RichDocument.galleryImage('sumiu'),
      );
    });

    test('parágrafo que parece título, lista ou citação é escapado', () {
      for (final text in [
        '# não é título',
        '- não é lista',
        '> não é citação',
        '1. não é lista',
      ]) {
        final delta = Delta()..insert('$text\n');
        final markdown = _toMarkdown.convert(delta);
        expect(
          _toDelta.convert(markdown).toJson(),
          delta.toJson(),
          reason: text,
        );
      }
    });

    test('nome de menção com colchetes não quebra o marcador', () {
      final delta = Delta()
        ..insert('A [B]', {
          RichDocument.mentionKey: RichDocument.mention('b', 'A [B]'),
        })
        ..insert('\n');
      final markdown = _toMarkdown.convert(delta);
      expect(markdown, startsWith('[[element:b|A [B'));
      expect(
        _toDelta
            .convert(markdown)
            .toJson()
            .first['attributes'][RichDocument.mentionKey]['id'],
        'b',
      );
    });
  });
}
