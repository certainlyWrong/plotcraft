import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/story_chronology.dart';
import 'package:plotcraft/features/project_workspace/domain/story_matrix.dart';
import 'package:plotcraft/features/project_workspace/presentation/timeline/world_timeline_view.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';
import 'package:plotcraft_core/features/project_workspace/domain/story_time.dart';

NarrativeElement _element(
  String id,
  String title, {
  String typeId = 'character',
  StoryTime? time,
  Map<String, String> fields = const {},
  List<NarrativePhase> phases = const [],
}) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: title,
  summary: '',
  sections: const [],
  phases: phases,
  fields: fields,
  time: time,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('StoryTime', () {
    test('vai e volta no JSON e ignora o que não presta', () {
      const time = StoryTime(label: 'Ano 312', position: 312);
      expect(StoryTime.fromJson(time.toJson()), time);
      expect(StoryTime.fromJson(null), isNull);
      expect(StoryTime.fromJson('x'), isNull);
      expect(StoryTime.fromJson({'label': ' ', 'position': 'abc'}), isNull);
      expect(StoryTime.fromJson({'position': 2.5})?.position, 2.5);
    });

    test('mostra o rótulo, ou a posição quando não há rótulo', () {
      expect(const StoryTime(label: 'Antes', position: 1).display, 'Antes');
      expect(const StoryTime(position: 312).display, '312');
      expect(const StoryTime(position: 2.5).display, '2.5');
    });

    test(
      'o elemento guarda e lê o tempo, e o arquivo antigo continua legível',
      () {
        final element = _element(
          'e',
          'Selamento',
          time: const StoryTime(label: 'Ano 1', position: 1),
        );
        final json = element.toJson();
        expect(json['time'], {'label': 'Ano 1', 'position': 1.0});
        expect(NarrativeElement.fromJson(json).time, element.time);
        json.remove('time');
        expect(NarrativeElement.fromJson(json).time, isNull);
        expect(element.copyWith(clearTime: true).time, isNull);
      },
    );
  });

  group('StoryChronology', () {
    test(
      'ordena pela posição; sem posição fica no fim, na ordem de criação',
      () {
        final chronology = StoryChronology.build([
          _element(
            'c',
            'Tarde',
            time: const StoryTime(label: 'Tarde', position: 9),
          ),
          _element(
            'x',
            'Solto',
            time: const StoryTime(label: 'Há muito tempo'),
          ),
          _element('a', 'Cedo', time: const StoryTime(position: -4)),
          _element('sem', 'Sem tempo'),
          _element('y', 'Outro solto', time: const StoryTime(label: 'Um dia')),
        ]);
        expect(chronology.entries.map((e) => e.elementId), [
          'a',
          'c',
          'x',
          'y',
        ]);
        expect(chronology.placedCount, 2);
      },
    );

    test('um evento só com o detalhe "quando" entra sem posição', () {
      final chronology = StoryChronology.build([
        _element(
          'sel',
          'O Selamento',
          typeId: 'event',
          fields: const {'when': 'Há trezentos anos'},
        ),
        _element('p', 'Personagem', fields: const {'when': 'ignorado'}),
      ]);
      expect(chronology.entries, hasLength(1));
      expect(chronology.entries.single.inferred, isTrue);
      expect(chronology.entries.single.time.display, 'Há trezentos anos');
    });

    test('a posição depois de mover usa os vizinhos já posicionados', () {
      ChronologyEntry entry(String id, [double? position]) => ChronologyEntry(
        elementId: id,
        title: id,
        typeId: 'event',
        time: StoryTime(position: position),
      );
      expect(
        StoryChronology.positionAfterMove([
          entry('a', 10),
          entry('m'),
          entry('b', 20),
        ], 1),
        15,
      );
      expect(
        StoryChronology.positionAfterMove([entry('m'), entry('b', 20)], 0),
        19,
      );
      expect(
        StoryChronology.positionAfterMove([entry('a', 10), entry('m')], 1),
        11,
      );
      expect(StoryChronology.positionAfterMove([entry('m'), entry('x')], 0), 0);
      // Dropped among the ones that are not placed: after the last placed.
      expect(
        StoryChronology.positionAfterMove([
          entry('a', 10),
          entry('x'),
          entry('m'),
        ], 2),
        11,
      );
    });
  });

  group('StoryMatrix', () {
    test(
      'cruza menções e fases por capítulo e ordena pelo primeiro aparecimento',
      () {
        final matrix = StoryMatrix.build(
          elements: [
            _element('tarde', 'Tarde'),
            _element(
              'ana',
              'Ana',
              phases: const [
                NarrativePhase(
                  id: 'p',
                  title: 'Despertar',
                  description: '',
                  anchor: NarrativeAnchor.chapter('c2'),
                ),
              ],
            ),
            _element('bia', 'Bia'),
            _element('fora', 'Fora'),
          ],
          chapters: const [
            BookChapter(id: 'c1', title: 'Um'),
            BookChapter(id: 'c2', title: 'Dois'),
            BookChapter(id: 'c3', title: 'Três'),
          ],
          presence: const [
            ChapterPresence(
              chapterId: 'c1',
              chapterTitle: 'Um',
              counts: {'bia': 4},
            ),
            ChapterPresence(
              chapterId: 'c2',
              chapterTitle: 'Dois',
              counts: {'ana': 1, 'bia': 1},
            ),
            ChapterPresence(
              chapterId: 'c3',
              chapterTitle: 'Três',
              counts: {'tarde': 2},
            ),
          ],
        );
        expect(matrix.rows.map((r) => r.elementId), ['bia', 'ana', 'tarde']);
        final ana = matrix.rows[1];
        expect(ana.firstChapter, 1);
        expect(ana.cells[1].mentions, 1);
        expect(ana.cells[1].phases, ['Despertar']);
        expect(ana.cells[0].isEmpty, isTrue);
        expect(matrix.rows.first.totalMentions, 5);
      },
    );
  });

  group('ScaleLayout', () {
    test('posiciona pela escala e empilha cartões que se sobreporiam', () {
      final layout = ScaleLayout.of(
        [0, 1, 2, 100],
        viewWidth: 1000,
        zoom: 1,
        cardWidth: 200,
        padding: 40,
      );
      // The first three are too close together for one row.
      expect(layout.lanes.take(3).toSet(), hasLength(3));
      // The far one fits in the first row again.
      expect(layout.lanes.last, 0);
      expect(layout.xs.first, 40);
      expect(layout.xs.last, greaterThan(layout.xs[2]));
      expect(layout.laneCount, 3);
    });

    test('mais zoom abre a escala e alarga a área', () {
      final a = ScaleLayout.of([0, 10], viewWidth: 800, zoom: 1);
      final b = ScaleLayout.of([0, 10], viewWidth: 800, zoom: 4);
      expect(b.pxPerUnit, closeTo(a.pxPerUnit * 4, 1e-9));
      expect(b.width, greaterThan(a.width));
    });

    test('uma só posição, ou todas iguais, não quebra', () {
      final layout = ScaleLayout.of([5, 5], viewWidth: 600, zoom: 1);
      expect(layout.xs, [40, 40]);
      expect(layout.lanes, [0, 1]);
    });

    test('os marcadores usam passos redondos', () {
      expect(ScaleLayout.tickStep(1), 100);
      expect(ScaleLayout.tickStep(9), 10);
      expect(ScaleLayout.tickStep(100), 1);
      expect(ScaleLayout.tickStep(450), 0.2);
      expect(ScaleLayout.formatTick(300, 100), '300');
      expect(ScaleLayout.formatTick(1.5, 0.5), '1.5');
      expect(ScaleLayout.formatTick(2, 0.5), '2.0');
    });
  });
}
