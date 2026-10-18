import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:plotcraft/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/presentation/elements/element_phase_dialog.dart';

void main() {
  group('modelo', () {
    test('a âncora faz ida e volta e entradas inválidas viram "nenhuma"', () {
      for (final anchor in const [
        NarrativeAnchor.none(),
        NarrativeAnchor.chapter('c3'),
        NarrativeAnchor.manual('depois da guerra'),
      ]) {
        expect(
          NarrativeAnchor.fromJson(jsonDecode(jsonEncode(anchor.toJson()))),
          anchor,
        );
      }
      for (final bad in [
        null,
        'x',
        {'kind': 'chapter'},
        {'kind': 'manual', 'label': ' '},
        {'kind': '?'},
      ]) {
        expect(NarrativeAnchor.fromJson(bad), const NarrativeAnchor.none());
      }
    });

    test(
      'fase completa faz ida e volta; fase antiga sem âncora ainda é lida',
      () {
        const phase = NarrativePhase(
          id: 'p',
          title: 'Pós-corrida',
          description: 'mais madura',
          anchor: NarrativeAnchor.chapter('c3'),
          fieldOverrides: {'age': '18'},
          image: ElementImage.gallery('g1'),
        );
        final read = NarrativePhase.fromJson(
          jsonDecode(jsonEncode(phase.toJson())) as Map<String, dynamic>,
        );
        expect(read.anchor, phase.anchor);
        expect(read.fieldOverrides, {'age': '18'});
        expect(read.image, phase.image);

        final old = NarrativePhase.fromJson({
          'id': 'x',
          'title': 'Início',
          'description': 'd',
        });
        expect(old.anchor, const NarrativeAnchor.none());
        expect(old.fieldOverrides, isEmpty);
        expect(old.image, isNull);
      },
    );

    test('imagens de fase em anexo contam como usadas pelo elemento', () {
      final element = NarrativeElement(
        id: 'e',
        typeId: 'character',
        title: 'E',
        summary: '',
        sections: const [],
        phases: const [
          NarrativePhase(
            id: 'p',
            title: 'P',
            description: '',
            image: ElementImage.attachment(
              'content/narrative/attachments/e/fase.png',
            ),
          ),
        ],
        images: const [
          ElementImage.attachment('content/narrative/attachments/e/capa.png'),
          ElementImage.gallery('g'),
        ],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(element.attachmentFiles, {
        'content/narrative/attachments/e/capa.png',
        'content/narrative/attachments/e/fase.png',
      });
    });
  });

  group('diálogo', () {
    Future<void> open(
      WidgetTester tester,
      void Function(NarrativePhase?) onResult, {
      NarrativePhase? current,
      List<BookChapter> chapters = const [],
      List<ElementImage> images = const [],
    }) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: builtInThemes.first.toThemeData(fontFamily: 'Lora'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showElementPhaseDialog(
                  context,
                  current: current,
                  newId: 'novo',
                  chapters: chapters,
                  fields: ElementTypeCatalog.builtinById('character')!.fields,
                  images: images,
                  resolvePath: (_) => null,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'cria uma fase ancorada a um capítulo com um detalhe alterado',
      (tester) async {
        NarrativePhase? result;
        await open(
          tester,
          (phase) => result = phase,
          chapters: const [
            BookChapter(id: 'c1', title: 'A largada'),
            BookChapter(id: 'c2', title: 'A chegada'),
          ],
        );
        await tester.enterText(
          find.byType(TextField).at(0),
          'Depois da corrida',
        );
        await tester.enterText(find.byType(TextField).at(1), 'Mais confiante.');
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('A chegada').last);
        await tester.pumpAndSettle();
        // The character type's first detail is "Age".
        await tester.enterText(
          find.widgetWithText(TextField, 'elements.fields.age'),
          '18',
        );
        await tester.tap(find.text('ui.save'));
        await tester.pumpAndSettle();

        expect(result!.id, 'novo');
        expect(result!.title, 'Depois da corrida');
        expect(result!.anchor, const NarrativeAnchor.chapter('c2'));
        expect(result!.fieldOverrides, {'age': '18'});
        expect(result!.image, isNull);
      },
    );

    testWidgets('âncora livre exige texto e título é obrigatório', (
      tester,
    ) async {
      NarrativePhase? result;
      await open(tester, (phase) => result = phase);
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('elements.title_required'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Fase');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('elements.anchor_manual').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), 'depois da guerra');
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();
      expect(result!.anchor, const NarrativeAnchor.manual('depois da guerra'));
    });

    testWidgets('editar mantém o ID, e capítulo apagado volta para "nenhum"', (
      tester,
    ) async {
      NarrativePhase? result;
      await open(
        tester,
        (phase) => result = phase,
        current: const NarrativePhase(
          id: 'p9',
          title: 'Antiga',
          description: '',
          anchor: NarrativeAnchor.chapter('sumiu'),
          image: ElementImage.gallery('g1'),
        ),
        images: const [ElementImage.gallery('g1')],
      );
      await tester.tap(find.text('ui.save'));
      await tester.pumpAndSettle();
      expect(result!.id, 'p9');
      expect(result!.anchor, const NarrativeAnchor.none());
      expect(result!.image, const ElementImage.gallery('g1'));
    });
  });
}
