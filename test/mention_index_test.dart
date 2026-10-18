import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_index.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';

NarrativeElement _el(
  String id,
  String title, {
  List<String> aliases = const [],
  MentionPolicy policy = const MentionPolicy(),
}) => NarrativeElement(
  id: id,
  typeId: 'character',
  title: title,
  aliases: aliases,
  summary: '',
  sections: const [],
  phases: const [],
  mentionPolicy: policy,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

Delta _doc(String text) => Delta()..insert('$text\n');

List<String> _found(MentionIndex index, String text) {
  final plain = '$text\n';
  return [
    for (final hit in index.scan(_doc(text)))
      '${hit.elementId}:${plain.substring(hit.start, hit.end)}',
  ];
}

void main() {
  group('detecção automática', () {
    test('acha o nome e os apelidos, sem diferenciar caixa nem acentos', () {
      final index = MentionIndex([
        _el('maria', 'Maria', aliases: ['A Corredora', 'Mari']),
        _el('eowyn', 'Éowyn'),
      ]);
      expect(_found(index, 'maria viu a corredora e MARI sorriu; eowyn não.'), [
        'maria:maria',
        'maria:a corredora',
        'maria:MARI',
        'eowyn:eowyn',
      ]);
    });

    test('só palavras inteiras: Lia não está em Julia nem em Liana', () {
      final index = MentionIndex([_el('lia', 'Lia')]);
      expect(_found(index, 'Julia e Liana viram Lia.'), ['lia:Lia']);
      expect(_found(index, "Lia's casa, (Lia), Lia-Maria"), [
        'lia:Lia',
        'lia:Lia',
        'lia:Lia',
      ]);
    });

    test('o nome mais longo vence o mais curto', () {
      final index = MentionIndex([
        _el('maria', 'Maria'),
        _el('clara', 'Maria Clara'),
      ]);
      expect(_found(index, 'Maria Clara chegou, Maria também.'), [
        'clara:Maria Clara',
        'maria:Maria',
      ]);
    });

    test('nomes com várias palavras aceitam espaços repetidos mas não quebra de parágrafo', () {
      final index = MentionIndex([_el('c', 'Maria Clara')]);
      expect(_found(index, 'Maria   Clara'), ['c:Maria   Clara']);
      expect(_found(index, 'Maria\nClara'), isEmpty);
    });

    test('desligado no elemento, ou termo ignorado, não é detectado', () {
      final index = MentionIndex([
        _el(
          'lia',
          'Lia',
          aliases: ['Lili'],
          policy: const MentionPolicy(ignoredTerms: ['lia']),
        ),
        _el('tom', 'Tom', policy: const MentionPolicy(auto: false)),
      ]);
      expect(_found(index, 'Lia, Lili e Tom'), ['lia:Lili']);
    });

    test('ignora nomes curtos demais ou que não começam com letra', () {
      final index = MentionIndex([
        _el('a', 'Al'),
        _el('b', '***'),
        _el('c', 'Bia'),
      ]);
      expect(_found(index, 'Al, *** e Bia'), ['c:Bia']);
      expect(
        MentionIndex([_el('a', 'Al')], minTermLength: 2).scan(_doc('Al')),
        hasLength(1),
      );
    });

    test('dois elementos com o mesmo nome: vale o primeiro', () {
      final index = MentionIndex([_el('um', 'Sol'), _el('dois', 'Sol')]);
      expect(_found(index, 'Sol'), ['um:Sol']);
    });

    test('sem elementos nada é procurado', () {
      final index = MentionIndex(const []);
      expect(index.isEmpty, isTrue);
      expect(index.scan(_doc('Qualquer texto')), isEmpty);
    });

    test('os deslocamentos continuam certos com acentos e embeds antes', () {
      final index = MentionIndex([_el('lia', 'Lia')]);
      final delta = Delta()
        ..insert('Ação ')
        ..insert(RichDocument.divider())
        ..insert(' e Lia\n');
      final hit = index.scan(delta).single;
      final plain = RichDocument.plainText(delta);
      expect(plain.substring(hit.start, hit.end), 'Lia');
      expect(hit.start, 9);
    });
  });

  group('menções ligadas', () {
    test('entram sempre e não são duplicadas pela detecção', () {
      final index = MentionIndex([_el('lia', 'Lia')]);
      final delta = Delta()
        ..insert('Oi ')
        ..insert('Lia', {
          RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
        })
        ..insert(' e Lia\n');
      final hits = index.scan(delta);
      expect(hits.map((h) => h.linked), [true, false]);
      expect(hits.map((h) => h.start), [3, 9]);
    });

    test('uma menção ligada a outro elemento não é reinterpretada', () {
      final index = MentionIndex([_el('lia', 'Lia'), _el('maria', 'Maria')]);
      final delta = Delta()
        ..insert('Lia', {
          RichDocument.mentionKey: RichDocument.mention('maria', 'Maria'),
        })
        ..insert('\n');
      final hits = index.scan(delta);
      expect(hits.single.elementId, 'maria');
      expect(hits.single.linked, isTrue);
    });

    test('includeLinked: false devolve só as automáticas', () {
      final index = MentionIndex([_el('lia', 'Lia')]);
      final delta = Delta()
        ..insert('Lia', {
          RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
        })
        ..insert(' e Lia\n');
      expect(index.scan(delta, includeLinked: false).map((h) => h.linked), [
        false,
      ]);
    });

    test('menção ligada funciona mesmo com a detecção desligada', () {
      final index = MentionIndex([
        _el('lia', 'Lia', policy: const MentionPolicy(auto: false)),
      ]);
      final delta = Delta()
        ..insert('Lia', {
          RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
        })
        ..insert(' Lia\n');
      expect(index.scan(delta).map((h) => h.linked), [true]);
    });
  });

  test('desempenho: 200 mil palavras e 60 elementos', () {
    final elements = [
      for (var i = 0; i < 60; i++)
        _el(
          'e$i',
          'Personagem${String.fromCharCode(65 + i % 26)}$i',
          aliases: ['Apelido$i'],
        ),
    ];
    final words = [
      'a',
      'corredora',
      'chegou',
      'na',
      'pista',
      'Personagem${'A'}0',
      'de',
      'sal',
      'Apelido7',
      'vento',
    ];
    final buffer = StringBuffer();
    for (var p = 0; p < 2000; p++) {
      for (var w = 0; w < 100; w++) {
        buffer.write('${words[(p + w) % words.length]} ');
      }
      buffer.write('\n');
    }
    final delta = Delta()..insert(buffer.toString());
    final clock = Stopwatch()..start();
    final index = MentionIndex(elements);
    final built = clock.elapsedMilliseconds;
    final hits = index.scan(delta);
    // ignore: avoid_print
    print(
      'BENCH mentions words=200000 build=${built}ms scan=${clock.elapsedMilliseconds - built}ms hits=${hits.length}',
    );
    expect(hits.length, greaterThan(1000));
    expect(clock.elapsedMilliseconds, lessThan(5000));
  });
}
