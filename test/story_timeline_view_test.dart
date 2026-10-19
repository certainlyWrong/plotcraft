import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/presentation/timeline/story_timeline_view.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';
import 'package:plotcraft_core/features/project_workspace/domain/story_time.dart';

NarrativeElement _element(String id, String title, {StoryTime? time}) =>
    NarrativeElement(
      id: id,
      typeId: 'character',
      title: title,
      summary: '',
      sections: const [],
      phases: const [],
      time: time,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  late List<String> events;

  late List<Map<String, Object?>> saved;

  Future<void> pump(
    WidgetTester tester, {
    required List<NarrativeElement> elements,
    List<ChapterPresence> presence = const [],
    bool hasChapters = true,
    Map<String, Object?>? initialState,
    bool fullscreen = false,
  }) async {
    saved = [];
    events = [];
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: Scaffold(
          body: StoryTimelineView(
            elements: elements,
            chapters: const [
              BookChapter(id: 'c1', title: 'Largada'),
              BookChapter(id: 'c2', title: 'Chegada'),
            ],
            types: const [],
            presence: presence,
            hasChapters: hasChapters,
            onOpenElement: (id) => events.add('element:$id'),
            onOpenChapter: (id) => events.add('chapter:$id'),
            onPlace: (id, position) => events.add('place:$id:$position'),
            initialState: initialState,
            onStateChanged: saved.add,
            fullscreen: fullscreen,
            onToggleFullscreen: () => events.add('fullscreen'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('por capítulo: mostra os elementos citados e abre o capítulo', (
    tester,
  ) async {
    await pump(
      tester,
      elements: [_element('ana', 'Ana'), _element('bia', 'Bia')],
      presence: const [
        ChapterPresence(
          chapterId: 'c1',
          chapterTitle: 'Largada',
          counts: {'ana': 3},
        ),
        ChapterPresence(
          chapterId: 'c2',
          chapterTitle: 'Chegada',
          counts: {'ana': 1, 'bia': 2},
        ),
      ],
    );
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('Largada'), findsOneWidget);
    await tester.tap(find.text('Ana'));
    await tester.tap(find.text('Chegada'));
    expect(events, ['element:ana', 'chapter:c2']);
  });

  testWidgets('por capítulo sem menções mostra a dica', (tester) async {
    await pump(tester, elements: [_element('ana', 'Ana')]);
    expect(find.text('workspace.timeline_chapters_empty'), findsOneWidget);
  });

  testWidgets('cronologia: cartões na ordem da posição e abre o elemento', (
    tester,
  ) async {
    await pump(
      tester,
      elements: [
        _element(
          'b',
          'Depois',
          time: const StoryTime(label: 'Ano 9', position: 9),
        ),
        _element(
          'a',
          'Antes',
          time: const StoryTime(label: 'Ano 1', position: 1),
        ),
        _element('x', 'Solto', time: const StoryTime(label: 'Um dia')),
      ],
      hasChapters: false,
    );
    expect(find.text('workspace.timeline_chapters'), findsNothing);
    final antes = tester.getTopLeft(find.text('Antes')).dx;
    final depois = tester.getTopLeft(find.text('Depois')).dx;
    final solto = tester.getTopLeft(find.text('Solto')).dx;
    expect(antes, lessThan(depois));
    expect(depois, lessThan(solto));
    expect(find.text('workspace.timeline_unplaced'), findsOneWidget);
    await tester.tap(find.text('Depois'));
    expect(events, ['element:b']);
  });

  testWidgets('cronologia: arrastar um cartão pede a nova posição', (
    tester,
  ) async {
    await pump(
      tester,
      elements: [
        _element('a', 'Antes', time: const StoryTime(position: 10)),
        _element('b', 'Meio', time: const StoryTime(position: 20)),
        _element('c', 'Depois', time: const StoryTime(position: 30)),
      ],
      hasChapters: false,
    );
    final from = tester.getCenter(find.text('Depois'));
    final to = tester.getCenter(find.text('Antes')) + const Offset(-60, 0);
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 12; step++) {
      await gesture.moveTo(Offset.lerp(from, to, step / 12)!);
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(events, ['place:c:9.0']);
  });

  testWidgets('alternar para a cronologia sem datas mostra a dica', (
    tester,
  ) async {
    await pump(tester, elements: [_element('ana', 'Ana')]);
    await tester.tap(find.text('workspace.timeline_world'));
    await tester.pumpAndSettle();
    expect(find.text('workspace.timeline_world_empty'), findsOneWidget);
  });

  final placed = [
    _element('a', 'Antes', time: const StoryTime(label: 'Ano 1', position: 1)),
    _element('b', 'Meio', time: const StoryTime(label: 'Ano 2', position: 2)),
    _element(
      'c',
      'Depois',
      time: const StoryTime(label: 'Ano 100', position: 100),
    ),
    _element('x', 'Solto', time: const StoryTime(label: 'Um dia')),
  ];

  testWidgets('zoom: botões mudam a porcentagem e o estado é salvo', (
    tester,
  ) async {
    await pump(tester, elements: placed);
    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.byTooltip('workspace.zoom_in'));
    await tester.pump();
    expect(find.text('125%'), findsOneWidget);
    await tester.tap(find.byTooltip('workspace.zoom_out'));
    await tester.tap(find.byTooltip('workspace.zoom_out'));
    await tester.pump();
    expect(find.text('80%'), findsOneWidget);
    await tester.tap(find.text('80%'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(saved.last['matrixZoom'], 1.0);
  });

  testWidgets('zoom: Cmd/Ctrl + / - muda e respeita os limites', (
    tester,
  ) async {
    await pump(tester, elements: placed);
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }
    await tester.pump();
    expect(find.text('60%'), findsOneWidget);
  });

  testWidgets('tela cheia: botão e Esc chamam a ação', (tester) async {
    await pump(tester, elements: placed, fullscreen: true);
    await tester.tap(find.byTooltip('book.exit_fullscreen'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(events, ['fullscreen', 'fullscreen']);
  });

  testWidgets('escala: cada evento na sua posição, com marcadores', (
    tester,
  ) async {
    await pump(tester, elements: placed, hasChapters: false);
    await tester.tap(find.text('workspace.timeline_scale'));
    await tester.pumpAndSettle();
    expect(find.text('workspace.timeline_scale_hint'), findsOneWidget);
    final antes = tester.getTopLeft(find.text('Antes')).dx;
    final meio = tester.getTopLeft(find.text('Meio')).dx;
    final depois = tester.getTopLeft(find.text('Depois')).dx;
    // 1 → 2 is close, 2 → 100 is far: the picture shows it.
    expect(meio - antes, lessThan(depois - meio));
    // The one without a position waits below.
    expect(find.text('workspace.timeline_unplaced_title'), findsOneWidget);
    await tester.tap(find.text('Depois'));
    expect(events, ['element:c']);
    // Zoom in spreads the cards further apart.
    await tester.tap(find.byTooltip('workspace.zoom_in'));
    await tester.pump();
    expect(find.text('125%'), findsOneWidget);
  });

  testWidgets('o modo, o zoom e a escala salvos voltam ao abrir', (
    tester,
  ) async {
    await pump(
      tester,
      elements: placed,
      initialState: {'mode': 'world', 'worldZoom': 2.0, 'proportional': true},
    );
    expect(find.text('200%'), findsOneWidget);
    expect(find.text('workspace.timeline_scale_hint'), findsOneWidget);
    await tester.tap(find.byTooltip('workspace.zoom_in'));
    await tester.pump(const Duration(seconds: 1));
    expect(saved.last['mode'], 'world');
    expect(saved.last['worldZoom'], 2.5);
    expect(saved.last['proportional'], true);
  });

  testWidgets('escala: as linhas ficam atrás de todos os cartões', (
    tester,
  ) async {
    // Close events pile up in rows; the lines to the lower rows pass the
    // cards above them and must go behind.
    final crowded = [
      for (var i = 0; i < 6; i++)
        _element(
          'e$i',
          'Evento $i',
          time: StoryTime(label: 'Ano $i', position: i + 1.0),
        ),
      _element(
        'fim',
        'Fim',
        time: const StoryTime(label: 'Ano 500', position: 500),
      ),
    ];
    await pump(tester, elements: crowded, hasChapters: false);
    await tester.tap(find.text('workspace.timeline_scale'));
    await tester.pumpAndSettle();
    final stack = tester
        .widgetList<Stack>(find.byType(Stack))
        .firstWhere(
          (s) => s.children.whereType<Positioned>().any((p) => p.width == 2),
        );
    final positioned = stack.children.whereType<Positioned>().toList();
    final lines = [
      for (var i = 0; i < positioned.length; i++)
        if (positioned[i].width == 2 && positioned[i].height != 2) i,
    ];
    final cards = [
      for (var i = 0; i < positioned.length; i++)
        if (positioned[i].width == 200) i,
    ];
    expect(lines, isNotEmpty);
    expect(cards.length, 7);
    expect(lines.last, lessThan(cards.first));
  });
}
