import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/domain/graph_layout.dart';
import 'package:plotcraft/features/project_workspace/domain/story_graph.dart';
import 'package:plotcraft/features/project_workspace/presentation/graph/story_graph_view.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

NarrativeElement _element(
  String id,
  String title, {
  String typeId = 'character',
  List<ElementRelation> relations = const [],
  List<NarrativePhase> phases = const [],
}) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: title,
  summary: '',
  sections: const [],
  phases: phases,
  relations: relations,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

const _chapters = [
  BookChapter(id: 'c1', title: 'Capítulo um'),
  BookChapter(id: 'c2', title: 'Capítulo dois'),
];

/// The painted map (other widgets draw with CustomPaint too).
Finder graphCanvas() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_GraphPainter',
);

void main() {
  group('StoryGraph', () {
    test('junta as relações dos dois lados em uma única ligação', () {
      final graph = StoryGraph.build(
        elements: [
          _element(
            'ana',
            'Ana',
            relations: const [
              ElementRelation(
                id: 'r1',
                targetId: 'bia',
                label: 'irmã de',
                reciprocalLabel: 'irmã de',
              ),
            ],
          ),
          _element(
            'bia',
            'Bia',
            relations: const [ElementRelation(id: 'r2', targetId: 'ana')],
          ),
          _element('cao', 'Cão'),
        ],
        chapters: _chapters,
      );
      expect(graph.nodes.map((n) => n.id), [
        'element:ana',
        'element:bia',
        'element:cao',
      ]);
      expect(graph.edges, hasLength(1));
      expect(graph.edges.single.label, 'irmã de');
      expect(graph.degrees['element:cao'], 0);
      expect(graph.neighbors('element:ana'), {'element:bia'});
    });

    test('ignora relações para elementos que não existem ou para si mesmo', () {
      final graph = StoryGraph.build(
        elements: [
          _element(
            'ana',
            'Ana',
            relations: const [
              ElementRelation(id: 'r1', targetId: 'fantasma'),
              ElementRelation(id: 'r2', targetId: 'ana'),
            ],
          ),
        ],
        chapters: _chapters,
      );
      expect(graph.edges, isEmpty);
    });

    test('só mostra capítulos onde alguma fase começa', () {
      final graph = StoryGraph.build(
        elements: [
          _element(
            'ana',
            'Ana',
            phases: const [
              NarrativePhase(
                id: 'p1',
                title: 'Despertar',
                description: '',
                anchor: NarrativeAnchor.chapter('c2'),
              ),
              NarrativePhase(
                id: 'p2',
                title: 'Outra',
                description: '',
                anchor: NarrativeAnchor.chapter('c2'),
              ),
              NarrativePhase(
                id: 'p3',
                title: 'Sumiu',
                description: '',
                anchor: NarrativeAnchor.chapter('apagado'),
              ),
              NarrativePhase(
                id: 'p4',
                title: 'Manual',
                description: '',
                anchor: NarrativeAnchor.manual('depois da guerra'),
              ),
            ],
          ),
        ],
        chapters: _chapters,
      );
      expect(graph.nodes.map((n) => n.id), ['element:ana', 'chapter:c2']);
      expect(graph.edges.single.kind, StoryGraphEdgeKind.phase);
    });

    test(
      'menções ligam o elemento ao capítulo e trazem o capítulo ao mapa',
      () {
        final graph = StoryGraph.build(
          elements: [_element('ana', 'Ana'), _element('bia', 'Bia')],
          chapters: _chapters,
          presence: const [
            ChapterPresence(
              chapterId: 'c1',
              chapterTitle: 'Capítulo um',
              counts: {'ana': 3, 'fantasma': 1},
            ),
            ChapterPresence(chapterId: 'c2', chapterTitle: 'Dois', counts: {}),
            ChapterPresence(
              chapterId: null,
              chapterTitle: 'Livro',
              counts: {'bia': 2},
            ),
          ],
        );
        expect(graph.nodes.map((n) => n.id), [
          'element:ana',
          'element:bia',
          'chapter:c1',
        ]);
        final edge = graph.edges.single;
        expect(edge.kind, StoryGraphEdgeKind.mention);
        expect(edge.weight, 3);
        expect(graph.neighbors('chapter:c1'), {'element:ana'});
      },
    );

    test(
      'detalhes de referência ligam o evento aos lugares, sem repetir relações',
      () {
        final graph = StoryGraph.build(
          elements: [
            NarrativeElement(
              id: 'viagem',
              typeId: 'event',
              title: 'A viagem',
              summary: '',
              sections: const [],
              phases: const [],
              fields: const {'where': 'pedralta,cinzaluz'},
              relations: const [
                ElementRelation(
                  id: 'r',
                  targetId: 'pedralta',
                  label: 'acontece em',
                ),
              ],
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
            _element('pedralta', 'Pedralta', typeId: 'place'),
            _element('cinzaluz', 'Cinzaluz', typeId: 'place'),
          ],
          chapters: _chapters,
        );
        expect(graph.edges.map((e) => (e.targetId, e.kind)), [
          ('element:pedralta', StoryGraphEdgeKind.relation),
          ('element:cinzaluz', StoryGraphEdgeKind.reference),
        ]);
        expect(graph.edges.last.labelKey, 'elements.fields.where');
      },
    );

    test('where remove nós e as ligações que perdem uma ponta', () {
      final graph = StoryGraph.build(
        elements: [
          _element(
            'ana',
            'Ana',
            relations: const [ElementRelation(id: 'r', targetId: 'rio')],
          ),
          _element('rio', 'Rio', typeId: 'place'),
        ],
        chapters: _chapters,
      ).where((node) => node.typeId != 'place');
      expect(graph.nodes.map((n) => n.id), ['element:ana']);
      expect(graph.edges, isEmpty);
    });
  });

  group('GraphLayout', () {
    StoryGraph chain(int count) => StoryGraph.build(
      elements: [
        for (var i = 0; i < count; i++)
          _element(
            'e$i',
            'E$i',
            relations: i == 0
                ? const []
                : [ElementRelation(id: 'r$i', targetId: 'e${i - 1}')],
          ),
      ],
      chapters: const [],
    );

    test('assenta, afasta os nós e mantém as ligações em tamanho razoável', () {
      final graph = chain(6);
      final layout = GraphLayout(graph)..settle(maxSteps: 600);
      expect(layout.settled, isTrue);
      double dist(String a, String b) {
        final dx = layout.xOf(a) - layout.xOf(b);
        final dy = layout.yOf(a) - layout.yOf(b);
        return math.sqrt(dx * dx + dy * dy);
      }

      for (final edge in graph.edges) {
        expect(dist(edge.sourceId, edge.targetId), inInclusiveRange(50, 220));
      }
      for (final a in graph.nodes) {
        for (final b in graph.nodes) {
          if (a.id != b.id) expect(dist(a.id, b.id), greaterThan(30));
        }
      }
    });

    test('é determinístico e preserva posições anteriores', () {
      final graph = chain(5);
      final a = GraphLayout(graph)..settle();
      final b = GraphLayout(graph)..settle();
      expect(a.positions, b.positions);
      final kept = GraphLayout(graph, previous: a.positions);
      expect(kept.xOf('element:e2'), a.xOf('element:e2'));
    });

    test('um nó fixado não se mexe', () {
      final layout = GraphLayout(chain(4))
        ..pin('element:e1', 500, -300)
        ..reheat(1)
        ..settle(maxSteps: 50);
      expect(layout.xOf('element:e1'), 500);
      expect(layout.yOf('element:e1'), -300);
    });
  });

  group('StoryGraphView', () {
    late List<String> opened;

    Future<void> pump(
      WidgetTester tester,
      List<NarrativeElement> elements,
    ) async {
      opened = [];
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: StoryGraphView(
              elements: elements,
              chapters: _chapters,
              types: const [],
              onOpenElement: opened.add,
              onOpenChapter: (id) => opened.add('chapter:$id'),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('sem elementos mostra a dica', (tester) async {
      await pump(tester, const []);
      expect(find.text('workspace.graph_empty'), findsOneWidget);
    });

    testWidgets('selecionar um nó mostra o cartão e permite abrir', (
      tester,
    ) async {
      await pump(tester, [
        _element(
          'ana',
          'Ana',
          relations: const [ElementRelation(id: 'r', targetId: 'bia')],
        ),
        _element('bia', 'Bia'),
      ]);
      // Let the layout settle, then click every candidate spot until a node
      // answers: the picture is centered, so the middle is between the nodes.
      await tester.pump(const Duration(seconds: 4));
      final canvas = graphCanvas();
      final center = tester.getCenter(canvas);
      Finder card() => find.text('workspace.graph_open');
      var selected = false;
      for (final dx in [-70.0, -50.0, -30.0, 30.0, 50.0, 70.0, 90.0, -90.0]) {
        await tester.tapAt(center + Offset(dx, 0));
        await tester.pump();
        if (card().evaluate().isNotEmpty) {
          selected = true;
          break;
        }
      }
      expect(selected, isTrue);
      await tester.tap(card());
      expect(opened, hasLength(1));
    });

    testWidgets('o filtro de tipo esconde os elementos daquele tipo', (
      tester,
    ) async {
      await pump(tester, [
        _element('ana', 'Ana'),
        _element('rio', 'Rio', typeId: 'place'),
      ]);
      expect(find.textContaining('· 1'), findsNWidgets(2));
      await tester.tap(find.textContaining('· 1').last);
      await tester.pump();
      expect(find.byType(StoryGraphView), findsOneWidget);
    });

    Future<List<Map<String, Object?>>> pumpWith(
      WidgetTester tester,
      List<NarrativeElement> elements, {
      Map<String, Object?>? initialState,
      bool fullscreen = false,
      VoidCallback? onToggleFullscreen,
    }) async {
      final saved = <Map<String, Object?>>[];
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: StoryGraphView(
              elements: elements,
              chapters: _chapters,
              types: const [],
              onOpenElement: (_) {},
              onOpenChapter: (_) {},
              initialState: initialState,
              onStateChanged: saved.add,
              fullscreen: fullscreen,
              onToggleFullscreen: onToggleFullscreen,
            ),
          ),
        ),
      );
      await tester.pump();
      return saved;
    }

    /// Lets the layout run to rest (one step per frame) and saves.
    Future<void> rest(WidgetTester tester) async {
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(seconds: 1));
    }

    final linked = [
      _element(
        'ana',
        'Ana',
        relations: const [ElementRelation(id: 'r', targetId: 'bia')],
      ),
      _element('bia', 'Bia'),
      _element('solto', 'Solto'),
    ];

    testWidgets('zoom pelos botões muda e salva a escala', (tester) async {
      final saved = await pumpWith(tester, linked);
      await tester.pump(const Duration(seconds: 3));
      saved.clear();
      await tester.tap(find.byTooltip('workspace.zoom_in'));
      await tester.pump(const Duration(seconds: 1));
      final scaleIn = saved.last['scale']! as double;
      saved.clear();
      await tester.tap(find.byTooltip('workspace.zoom_out'));
      await tester.tap(find.byTooltip('workspace.zoom_out'));
      await tester.pump(const Duration(seconds: 1));
      expect(saved.last['scale'] as double, lessThan(scaleIn));
    });

    testWidgets('o painel de exibição abre, muda e salva as opções', (
      tester,
    ) async {
      final saved = await pumpWith(tester, linked);
      await tester.tap(find.byTooltip('workspace.graph_display'));
      await tester.pump();
      expect(find.text('workspace.graph_forces'), findsOneWidget);
      expect(find.text('workspace.graph_link_distance'), findsOneWidget);
      await tester.ensureVisible(find.text('workspace.graph_show_orphans'));
      await tester.tap(find.text('workspace.graph_show_orphans'));
      await tester.pump(const Duration(seconds: 1));
      final settings = saved.last['settings']! as Map;
      expect(settings['showOrphans'], isFalse);
      await tester.ensureVisible(find.text('workspace.graph_reset'));
      await tester.tap(find.text('workspace.graph_reset'));
      await tester.pump(const Duration(seconds: 1));
      expect((saved.last['settings']! as Map)['showOrphans'], isTrue);
    });

    testWidgets('o estado salvo é restaurado com as mesmas posições', (
      tester,
    ) async {
      final first = await pumpWith(tester, linked);
      await rest(tester);
      final state = first.last;
      expect(
        (state['positions']! as Map).keys,
        containsAll(['element:ana', 'element:bia', 'element:solto']),
      );

      final second = await pumpWith(tester, linked, initialState: state);
      await rest(tester);
      // Nothing had to move, and the view is where it was.
      expect(second, isEmpty);
      await tester.tap(find.byTooltip('workspace.zoom_in'));
      await tester.pump(const Duration(seconds: 1));
      expect(
        second.last['scale'] as double,
        closeTo((state['scale']! as double) * 1.25, 1e-6),
      );
      expect(second.last['positions'], state['positions']);
    });

    testWidgets('tela cheia: o botão e a tecla Esc chamam a ação', (
      tester,
    ) async {
      var toggled = 0;
      await pumpWith(
        tester,
        linked,
        fullscreen: true,
        onToggleFullscreen: () => toggled++,
      );
      await tester.tap(find.byTooltip('book.exit_fullscreen'));
      expect(toggled, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(toggled, 2);
    });

    testWidgets('arrastar o fundo e usar a roda do mouse não quebra', (
      tester,
    ) async {
      await pump(tester, [_element('ana', 'Ana')]);
      final canvas = graphCanvas();
      final center = tester.getCenter(canvas);
      await tester.dragFrom(
        center + const Offset(200, 150),
        const Offset(40, 30),
      );
      await tester.pump();
      final pointer = TestPointer(1, PointerDeviceKind.mouse)..hover(center);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
