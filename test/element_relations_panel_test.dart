import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_relations_panel.dart';

NarrativeElement _element(
  String id,
  String title, [
  List<ElementRelation> relations = const [],
]) => NarrativeElement(
  id: id,
  typeId: 'character',
  title: title,
  summary: '',
  sections: const [],
  phases: const [],
  relations: relations,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late List<ElementRelation> relations;
  late List<String> opened;

  setUp(() {
    relations = [];
    opened = [];
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    required List<NarrativeElement> candidates,
    List<ResolvedRelation> incoming = const [],
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var counter = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: ElementRelationsPanel(
                relations: relations,
                candidates: candidates,
                incoming: incoming,
                newId: () => 'r${++counter}',
                onChanged: (next) => setState(() => relations = next),
                onOpenElement: opened.add,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sem outros elementos não é possível relacionar', (tester) async {
    await pumpPanel(tester, candidates: const []);
    expect(find.text('elements.no_other_elements'), findsOneWidget);
    final add = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'elements.add_relation'),
    );
    expect(add.onPressed, isNull);
  });

  testWidgets('adiciona, edita rótulos, troca o alvo e remove', (tester) async {
    await pumpPanel(
      tester,
      candidates: [_element('lia', 'Lia'), _element('tom', 'Tom')],
    );
    await tester.tap(find.text('elements.add_relation'));
    await tester.pump();
    expect(relations.single.targetId, 'lia');

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'irmã de');
    await tester.enterText(fields.at(1), 'irmão de');
    expect(relations.single.label, 'irmã de');
    expect(relations.single.reciprocalLabel, 'irmão de');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tom').last);
    await tester.pumpAndSettle();
    expect(relations.single.targetId, 'tom');
    expect(relations.single.label, 'irmã de');

    await tester.tap(find.byTooltip('elements.remove'));
    await tester.pump();
    expect(relations, isEmpty);
  });

  testWidgets('lista as relações que vêm de outros elementos e abre o outro', (
    tester,
  ) async {
    final mentor = _element('mentor', 'Mentor');
    final incoming = [
      ResolvedRelation(
        relation: const ElementRelation(id: 'r', targetId: 'eu'),
        other: mentor,
        label: 'aluna de',
        incoming: true,
      ),
    ];
    await pumpPanel(tester, candidates: [mentor], incoming: incoming);
    expect(find.text('elements.relations_incoming'), findsOneWidget);
    expect(find.text('aluna de'), findsOneWidget);
    await tester.tap(find.text('Mentor'));
    expect(opened, ['mentor']);
  });
}
