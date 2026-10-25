import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_reference_picker.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_reference.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';

NarrativeElement _element(
  String id,
  String title, {
  String typeId = 'place',
  List<String> aliases = const [],
  Map<String, String> fields = const {},
}) => NarrativeElement(
  id: id,
  typeId: typeId,
  title: title,
  aliases: aliases,
  summary: '',
  sections: const [],
  phases: const [],
  fields: fields,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final pedralta = _element('pedralta', 'Pedralta');
  final cinzaluz = _element(
    'cinzaluz',
    'Montanha de Cinzaluz',
    aliases: ['Cinzaluz'],
  );

  group('ElementReferences', () {
    test('resolve ids, títulos e apelidos, e o que sobra vira texto', () {
      final tokens = ElementReferences.resolve(
        'pedralta, cinzaluz, Lugar Nenhum, PEDRALTA',
        [pedralta, cinzaluz],
      );
      expect(tokens.map((t) => t.isElement ? t.elementId : t.text), [
        'pedralta',
        'cinzaluz',
        'Lugar Nenhum',
      ]);
    });

    test('ignora acentos e caixa ao casar pelo nome', () {
      expect(ElementReferences.ids('pédralta', [pedralta]), ['pedralta']);
    });

    test('join e split são inversos e ignoram vazios', () {
      expect(ElementReferences.join(['a', ' ', 'b']), 'a,b');
      expect(ElementReferences.split(' a, ,b ,'), ['a', 'b']);
    });

    test('all lista as referências dos detalhes, menos para si mesmo', () {
      final evento = _element(
        'viagem',
        'A viagem',
        typeId: 'event',
        fields: const {'where': 'pedralta,cinzaluz,viagem'},
      );
      final refs = ElementReferences.all([
        evento,
        pedralta,
        cinzaluz,
      ], const []);
      expect(refs.map((r) => (r.sourceId, r.targetId, r.field.id)), [
        ('viagem', 'pedralta', 'where'),
        ('viagem', 'cinzaluz', 'where'),
      ]);
    });

    test(
      'o catálogo: onde é de lugares, quando saiu dos detalhes do evento',
      () {
        final event = ElementTypeCatalog.builtinById('event')!;
        expect(event.fields.map((f) => f.id), ['where']);
        final where = event.fields.single;
        expect(where.kind, ElementFieldKind.elements);
        expect(where.targetTypes, ['place']);
        final leader = ElementTypeCatalog.builtinById('organization')!.fields
            .firstWhere((f) => f.id == 'leader');
        expect(leader.kind, ElementFieldKind.element);
        expect(leader.targetTypes, ['character']);
      },
    );

    test('o campo guarda os tipos aceitos no JSON', () {
      const field = ElementField(
        id: 'sede',
        label: 'Sede',
        kind: ElementFieldKind.element,
        targetTypes: ['place'],
      );
      final back = ElementField.fromJson(field.toJson())!;
      expect(back.targetTypes, ['place']);
      expect(back.isReference, isTrue);
    });
  });

  group('ElementReferencePicker', () {
    Future<void> pump(
      WidgetTester tester, {
      required String value,
      required bool multiple,
      required List<String> changes,
      List<NarrativeElement>? elements,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Scaffold(
            body: ElementReferencePicker(
              label: 'Onde',
              value: value,
              elements:
                  elements ??
                  [
                    pedralta,
                    cinzaluz,
                    _element('dorrin', 'Dorrin', typeId: 'character'),
                  ],
              types: const [],
              targetTypes: const ['place'],
              multiple: multiple,
              onChanged: changes.add,
            ),
          ),
        ),
      );
    }

    testWidgets('abre a busca só com lugares e adiciona o escolhido', (
      tester,
    ) async {
      final changes = <String>[];
      await pump(tester, value: 'pedralta', multiple: true, changes: changes);
      expect(find.text('Pedralta'), findsOneWidget);
      await tester.tap(find.text('elements.reference_add'));
      await tester.pumpAndSettle();
      // Both places are listed (the chosen one ticked), the character is not.
      expect(find.text('Montanha de Cinzaluz'), findsOneWidget);
      expect(find.text('Dorrin'), findsNothing);
      await tester.tap(find.text('Montanha de Cinzaluz'));
      await tester.pump();
      await tester.tap(find.text('ui.apply'));
      await tester.pumpAndSettle();
      expect(changes, ['pedralta,cinzaluz']);
    });

    testWidgets('a busca ignora acentos, caixa e acha por apelido', (
      tester,
    ) async {
      await pump(tester, value: '', multiple: true, changes: []);
      await tester.tap(find.text('elements.reference_add'));
      await tester.pumpAndSettle();
      expect(find.text('Pedralta'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'CINZALUZ');
      await tester.pump();
      expect(find.text('Pedralta'), findsNothing);
      expect(find.text('Montanha de Cinzaluz'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'pédr');
      await tester.pump();
      expect(find.text('Pedralta'), findsOneWidget);
      expect(find.text('Montanha de Cinzaluz'), findsNothing);
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump();
      expect(find.text('elements.reference_no_results'), findsOneWidget);
    });

    testWidgets('um só: tocar escolhe e fecha; Enter escolhe o primeiro', (
      tester,
    ) async {
      final changes = <String>[];
      await pump(tester, value: '', multiple: false, changes: changes);
      await tester.tap(find.text('elements.reference_add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'cinza');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(changes, ['cinzaluz']);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('desmarcar na busca remove o elemento', (tester) async {
      final changes = <String>[];
      await pump(tester, value: 'pedralta', multiple: true, changes: changes);
      await tester.tap(find.text('elements.reference_add'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Pedralta'));
      await tester.pump();
      await tester.tap(find.text('ui.apply'));
      await tester.pumpAndSettle();
      expect(changes, ['']);
    });

    testWidgets('remover um chip tira só aquele', (tester) async {
      final changes = <String>[];
      await pump(
        tester,
        value: 'pedralta,cinzaluz',
        multiple: true,
        changes: changes,
      );
      await tester.tap(find.byIcon(Feather.x).first);
      await tester.pump();
      expect(changes, ['cinzaluz']);
    });

    testWidgets('um só: depois de escolher não oferece adicionar', (
      tester,
    ) async {
      await pump(tester, value: 'pedralta', multiple: false, changes: []);
      expect(find.text('elements.reference_add'), findsNothing);
    });

    testWidgets('texto antigo aparece como chip sem elemento', (tester) async {
      await pump(
        tester,
        value: 'Pedralta e arredores',
        multiple: true,
        changes: [],
      );
      expect(find.text('Pedralta e arredores'), findsOneWidget);
    });

    testWidgets('sem lugares avisa para criar um', (tester) async {
      await pump(
        tester,
        value: '',
        multiple: true,
        changes: [],
        elements: [_element('dorrin', 'Dorrin', typeId: 'character')],
      );
      expect(find.text('elements.reference_none'), findsOneWidget);
    });
  });
}
