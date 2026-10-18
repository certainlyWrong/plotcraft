import 'package:flutter/painting.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/delta_to_markdown.dart';
import 'package:plotcraft/features/project_workspace/presentation/manuscript/mention_edit.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';

NarrativeElement _element(String id, String title) => NarrativeElement(
  id: id,
  typeId: 'character',
  title: title,
  summary: '',
  sections: const [],
  phases: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

QuillController _controller(String text) => QuillController(
  document: Document.fromJson([
    {'insert': '$text\n'},
  ]),
  selection: const TextSelection.collapsed(offset: 0),
);

void main() {
  late QuillController controller;

  tearDown(() => controller.dispose());

  test(
    'o @ digitado vira o nome do elemento como menção, seguido de espaço',
    () {
      controller = _controller('Ela viu @ ontem');
      MentionEdit.insert(controller, 8, 1, _element('lia', 'Lia'));
      expect(controller.document.toPlainText(), 'Ela viu Lia  ontem\n');
      final ops = controller.document.toDelta().toJson();
      expect(ops[0], {'insert': 'Ela viu '});
      expect(ops[1], {
        'insert': 'Lia',
        'attributes': {
          RichDocument.mentionKey: {'id': 'lia', 'name': 'Lia'},
        },
      });
      // The space after the mention is plain text.
      expect(ops[2]['insert'], '  ontem\n');
      expect(ops[2].containsKey('attributes'), isFalse);
      expect(controller.selection.baseOffset, 12);
      expect(RichDocument.mentionedIds(controller.document.toDelta()), ['lia']);
    },
  );

  test('a menção mantém negrito e cor do texto onde foi inserida', () {
    controller = QuillController(
      document: Document.fromJson([
        {
          'insert': 'forte @',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    MentionEdit.insert(controller, 6, 1, _element('lia', 'Lia'));
    final mention = controller.document.toDelta().toJson()[1];
    expect(mention['insert'], 'Lia');
    expect(mention['attributes']['bold'], true);
    expect(mention['attributes'][RichDocument.mentionKey]['id'], 'lia');
  });

  test('ligar o texto selecionado a um elemento não muda o texto', () {
    controller = _controller('A corredora chegou');
    controller.updateSelection(
      const TextSelection(baseOffset: 2, extentOffset: 11),
      ChangeSource.local,
    );
    expect(
      MentionEdit.linkSelection(controller, _element('maria', 'Maria')),
      isTrue,
    );
    expect(controller.document.toPlainText(), 'A corredora chegou\n');
    final ops = controller.document.toDelta().toJson();
    expect(ops[1]['insert'], 'corredora');
    expect(ops[1]['attributes'][RichDocument.mentionKey], {
      'id': 'maria',
      'name': 'Maria',
    });
  });

  test('sem seleção não liga nada', () {
    controller = _controller('Texto');
    expect(MentionEdit.linkSelection(controller, _element('a', 'A')), isFalse);
    expect(RichDocument.mentionedIds(controller.document.toDelta()), isEmpty);
  });

  test('a menção inteira pode ser desfeita em um passo', () {
    controller = _controller('Oi @');
    MentionEdit.insert(controller, 3, 1, _element('lia', 'Lia'));
    while (controller.hasUndo) {
      controller.undo();
    }
    expect(controller.document.toPlainText(), 'Oi @\n');
  });

  test('imagem da galeria entra em linha própria e sai no Markdown', () {
    controller = _controller('Antes e depois');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 6),
      ChangeSource.local,
    );
    MentionEdit.insertGalleryImage(controller, 'g1');
    final delta = controller.document.toDelta();
    expect(RichDocument.galleryImageIds(delta), {'g1'});
    final markdown = const DeltaToMarkdown(galleryFile: _fileOf).convert(delta);
    expect(markdown, contains('![](gallery/pista.png)'));
    expect(markdown, contains('Antes'));
    expect(markdown, contains('e depois'));
  });

  test('o divisor ocupa uma linha própria em qualquer ponto do texto', () {
    String shape(String text, int at) {
      final c = _controller(text);
      addTearDown(c.dispose);
      c.updateSelection(
        TextSelection.collapsed(offset: at),
        ChangeSource.local,
      );
      MentionEdit.insertDivider(c);
      return c.document
          .toDelta()
          .toList()
          .map(
            (op) => op.data is String
                ? (op.data as String).replaceAll('\n', '¶')
                : '[div]',
          )
          .join();
    }

    controller = _controller('x');
    expect(shape('Um', 2), 'Um¶[div]¶');
    expect(shape('Um dois', 2), 'Um¶[div]¶ dois¶');
    expect(shape('Um', 0), '[div]¶Um¶');
  });

  test('o divisor sai como --- no Markdown', () {
    controller = _controller('Um');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );
    MentionEdit.insertDivider(controller);
    final markdown = const DeltaToMarkdown().convert(
      controller.document.toDelta(),
    );
    expect(markdown, 'Um\n\n---\n');
  });

  test('imagem no meio de uma linha parte a linha em duas', () {
    controller = _controller('Antes e depois');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 5),
      ChangeSource.local,
    );
    MentionEdit.insertGalleryImage(controller, 'g1');
    final lines = const DeltaToMarkdown(galleryFile: _fileOf)
        .convert(controller.document.toDelta())
        .trim()
        .split(RegExp(r'\n+'));
    expect(lines, ['Antes', '![](gallery/pista.png)', ' e depois']);
  });
}

String? _fileOf(String id) => id == 'g1' ? 'pista.png' : null;
