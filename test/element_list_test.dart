import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_filter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_list.dart';

NarrativeElement _el(
  String id,
  String title,
  String typeId, {
  List<String> aliases = const [],
  List<String> tags = const [],
}) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: title,
  aliases: aliases,
  tags: tags,
  summary: '',
  sections: const [],
  phases: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final elements = [
    _el(
      'maria',
      'Maria',
      'character',
      aliases: ['A Corredora'],
      tags: ['protagonista'],
    ),
    _el('lia', 'Lia', 'character', tags: ['apoio']),
    _el('pista', 'Pista de Sal', 'place', tags: ['apoio', 'cenário']),
    _el('tenis', 'Tênis Dourado', 'object'),
  ];

  group('filterElements', () {
    test('sem filtros devolve tudo', () {
      expect(filterElements(elements), elements);
    });

    test('busca por título, apelido e etiqueta sem diferenciar caixa', () {
      expect(filterElements(elements, query: 'MARIA').map((e) => e.id), [
        'maria',
      ]);
      expect(filterElements(elements, query: 'corredora').map((e) => e.id), [
        'maria',
      ]);
      expect(filterElements(elements, query: 'cenár').map((e) => e.id), [
        'pista',
      ]);
      expect(filterElements(elements, query: '  ').length, 4);
      expect(filterElements(elements, query: 'zzz'), isEmpty);
    });

    test('combina tipo, etiqueta e texto', () {
      expect(filterElements(elements, typeId: 'character').length, 2);
      expect(filterElements(elements, tag: 'apoio').map((e) => e.id), [
        'lia',
        'pista',
      ]);
      expect(
        filterElements(
          elements,
          typeId: 'character',
          tag: 'apoio',
        ).map((e) => e.id),
        ['lia'],
      );
      expect(
        filterElements(elements, typeId: 'place', query: 'maria'),
        isEmpty,
      );
    });

    test('tagsOf junta, remove repetidas e ordena', () {
      expect(tagsOf(elements), ['apoio', 'cenário', 'protagonista']);
    });
  });

  group('ElementList', () {
    Future<List<String>> pumpList(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: ElementList(
                elements: elements,
                types: ElementTypeCatalog.builtin,
                activeElementId: 'lia',
                onOpen: (e) => opened.add(e.id),
                onAction: (_, _) {},
              ),
            ),
          ),
        ),
      );
      return opened;
    }

    testWidgets('mostra todos e filtra pela busca', (tester) async {
      final opened = await pumpList(tester);
      for (final title in ['Maria', 'Lia', 'Pista de Sal', 'Tênis Dourado']) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), 'sal');
      await tester.pump();
      expect(find.text('Pista de Sal'), findsOneWidget);
      expect(find.text('Maria'), findsNothing);
      await tester.tap(find.text('Pista de Sal'));
      expect(opened, ['pista']);

      await tester.enterText(find.byType(TextField), 'nada');
      await tester.pump();
      expect(find.text('elements.no_matches'), findsOneWidget);
    });

    testWidgets('filtra por tipo usando o seletor', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byTooltip('elements.filter_type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('elements.types.place').last);
      await tester.pumpAndSettle();
      expect(find.text('Pista de Sal'), findsOneWidget);
      expect(find.text('Maria'), findsNothing);
      expect(find.text('Lia'), findsNothing);
    });

    testWidgets('filtra por etiqueta usando o seletor', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byTooltip('elements.filter_tag'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('apoio').last);
      await tester.pumpAndSettle();
      expect(find.text('Lia'), findsOneWidget);
      expect(find.text('Pista de Sal'), findsOneWidget);
      expect(find.text('Maria'), findsNothing);
    });
  });
}
