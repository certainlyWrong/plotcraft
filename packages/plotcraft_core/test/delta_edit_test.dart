import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/delta_edit.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';
import 'package:test/test.dart';

Delta _doc(List<Map<String, dynamic>> ops) => Delta.fromJson(ops);

void main() {
  test('substituir mantém a formatação do texto trocado', () {
    final delta = _doc([
      {'insert': 'o '},
      {
        'insert': 'sal',
        'attributes': {'bold': true, 'color': '#ff0000'},
      },
      {'insert': ' e o mar\n'},
    ]);
    final result = DeltaEdit.replaceRange(delta, 2, 3, 'vento');
    expect(DeltaEdit.text(result), 'o vento e o mar\n');
    expect(result.toJson()[1], {
      'insert': 'vento',
      'attributes': {'bold': true, 'color': '#ff0000'},
    });
  });

  test('o texto novo não herda a ligação com um elemento', () {
    final delta = _doc([
      {'insert': 'Ela viu '},
      {
        'insert': 'Lia',
        'attributes': {
          RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
          'bold': true,
        },
      },
      {'insert': '.\n'},
    ]);
    final result = DeltaEdit.replaceRange(delta, 8, 3, 'Ana');
    final ana = result.toJson()[1];
    expect(ana['insert'], 'Ana');
    expect(ana['attributes'], {'bold': true});
  });

  test('inserir e apagar', () {
    final delta = _doc([
      {'insert': 'Olá mundo\n'},
    ]);
    var result = DeltaEdit.insertText(delta, 3, ',');
    expect(DeltaEdit.text(result), 'Olá, mundo\n');
    result = DeltaEdit.deleteRange(result, 3, 1);
    expect(DeltaEdit.text(result), 'Olá mundo\n');
    expect(() => DeltaEdit.deleteRange(result, 5, 99), throwsRangeError);
  });

  test('formatar um intervalo e remover um atributo', () {
    final delta = _doc([
      {'insert': 'texto forte\n'},
    ]);
    final bold = DeltaEdit.formatRange(delta, 6, 5, {'bold': true});
    expect(bold.toJson()[1], {
      'insert': 'forte',
      'attributes': {'bold': true},
    });
    final plain = DeltaEdit.formatRange(bold, 6, 5, {'bold': null});
    expect(plain.toJson(), [
      {'insert': 'texto forte\n'},
    ]);
  });

  test('ligar um trecho a um elemento não muda o texto', () {
    final delta = _doc([
      {'insert': 'A corredora chegou\n'},
    ]);
    final result = DeltaEdit.linkMention(delta, 2, 9, 'maria', 'Maria');
    expect(DeltaEdit.text(result), 'A corredora chegou\n');
    expect(RichDocument.mentionedIds(result), ['maria']);
  });

  test('o embed ocupa uma linha própria em qualquer ponto', () {
    String shape(String text, int at) {
      final delta = _doc([
        {'insert': '$text\n'},
      ]);
      final result = DeltaEdit.insertEmbedLine(
        delta,
        at,
        RichDocument.divider(),
      );
      return result
          .toList()
          .map(
            (op) => op.data is String
                ? (op.data as String).replaceAll('\n', '¶')
                : '[div]',
          )
          .join();
    }

    expect(shape('Um', 2), 'Um¶[div]¶');
    expect(shape('Um dois', 2), 'Um¶[div]¶ dois¶');
    expect(shape('Um', 0), '[div]¶Um¶');
  });

  test(
    'buscar ignora a caixa, aceita regex e conta o embed como um caractere',
    () {
      final delta = _doc([
        {'insert': 'Sal e sal'},
        {'insert': RichDocument.divider()},
        {'insert': ' SAL.\n'},
      ]);
      final hits = DeltaEdit.find(delta, 'sal');
      expect(hits.map((h) => (h.start, h.end)), [(0, 3), (6, 9), (11, 14)]);
      expect(DeltaEdit.find(delta, 'sal', caseSensitive: true), hasLength(1));
      expect(DeltaEdit.find(delta, r's\w+l', regex: true), hasLength(3));
      expect(DeltaEdit.find(delta, ''), isEmpty);
      // The embed sits at offset 9, so the last hit starts after it.
      expect(DeltaEdit.text(delta).codeUnitAt(9), 0xFFFC);
    },
  );

  test('substituir tudo troca todas as ocorrências e mantém o resto', () {
    final delta = _doc([
      {'insert': 'a '},
      {
        'insert': 'sal',
        'attributes': {'italic': true},
      },
      {'insert': ' e sal\n'},
    ]);
    final (result, count) = DeltaEdit.replaceAll(delta, 'sal', 'mar');
    expect(count, 2);
    expect(DeltaEdit.text(result), 'a mar e mar\n');
    expect(result.toJson()[1]['attributes'], {'italic': true});
  });

  test('o trecho de resultado resume o contexto', () {
    final plain = 'x' * 100 + 'ALVO' + 'y' * 100;
    final snippet = DeltaEdit.snippet(
      plain,
      const TextHit(100, 104),
      context: 5,
    );
    expect(snippet, '…xxxxxALVOyyyyy…');
  });

  group('formatos de linha', () {
    Delta book() => _doc([
      {'insert': 'Titulo'},
      {'insert': '\n'},
      {'insert': 'Primeira linha'},
      {'insert': '\n'},
      {'insert': 'Segunda linha'},
      {'insert': '\n'},
    ]);

    /// The attributes of each line break, in order (Delta merges neighbours).
    List<Map<String, dynamic>?> lineAttributes(Delta delta) => [
      for (final op in delta.toList())
        if (op.data is String)
          for (final char in (op.data! as String).split(''))
            if (char == '\n') op.attributes,
    ];

    test('um cabeçalho vai só na linha tocada', () {
      // Offset 8 is inside "Primeira linha".
      final result = DeltaEdit.formatLines(book(), 8, 0, {'header': 2});
      expect(lineAttributes(result), [
        null,
        {'header': 2},
        null,
      ]);
      expect(DeltaEdit.text(result), DeltaEdit.text(book()));
    });

    test('um intervalo pega todas as linhas que toca', () {
      // From the end of the first line to the middle of the third.
      final result = DeltaEdit.formatLines(book(), 3, 22, {'align': 'center'});
      expect(lineAttributes(result), [
        {'align': 'center'},
        {'align': 'center'},
        {'align': 'center'},
      ]);
      // A range that ends where a line begins does not take that line.
      final edge = DeltaEdit.formatLines(book(), 0, 7, {'indent': 1});
      expect(lineAttributes(edge), [
        {'indent': 1},
        null,
        null,
      ]);
    });

    test('trocar o tipo da linha tira o anterior', () {
      final listed = DeltaEdit.formatLines(book(), 8, 0, {'list': 'bullet'});
      final quoted = DeltaEdit.formatLines(listed, 8, 0, {'blockquote': true});
      expect(lineAttributes(quoted)[1], {'blockquote': true});
      final heading = DeltaEdit.formatLines(quoted, 8, 0, {'header': 1});
      expect(lineAttributes(heading)[1], {'header': 1});
    });

    test('valor nulo remove o atributo e atributo desconhecido é recusado', () {
      final aligned = DeltaEdit.formatLines(book(), 8, 0, {'align': 'right'});
      final cleared = DeltaEdit.formatLines(aligned, 8, 0, {'align': null});
      expect(lineAttributes(cleared), [null, null, null]);
      expect(
        () => DeltaEdit.formatLines(book(), 0, 0, {'bold': true}),
        throwsArgumentError,
      );
    });

    test(
      'limpar formatação tira o inline e o de linha, mas mantém a menção',
      () {
        final delta = _doc([
          {
            'insert': 'Ana',
            'attributes': {
              'bold': true,
              'color': '#ff0000',
              'link': 'https://x.y',
              RichDocument.mentionKey: RichDocument.mention('ana', 'Ana'),
            },
          },
          {'insert': ' e o mar'},
          {
            'insert': '\n',
            'attributes': {'header': 1, 'align': 'center'},
          },
        ]);
        final result = DeltaEdit.clearFormat(delta, 0, 11);
        final json = result.toJson();
        expect(json.first['attributes'], {
          RichDocument.mentionKey: RichDocument.mention('ana', 'Ana'),
        });
        expect(lineAttributes(result), [null]);
      },
    );
  });
}
