import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/markdown_edit_controller.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';

void main() {
  late TextEditingController text;
  late MarkdownEditController edit;

  void setText(String value, int start, [int? end]) {
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
    );
  }

  setUp(() {
    text = TextEditingController();
    edit = MarkdownEditController(text);
  });

  tearDown(() => text.dispose());

  test('wrapSelection envolve o trecho e mantém a seleção', () {
    setText('uma palavra aqui', 4, 11);
    edit.wrapSelection('**', '**');
    expect(text.text, 'uma **palavra** aqui');
    expect(text.selection.textInside(text.text), 'palavra');
  });

  test('wrapSelection sem seleção insere os marcadores no cursor', () {
    setText('abc', 3);
    edit.wrapSelection('`', '`');
    expect(text.text, 'abc``');
    expect(text.selection.baseOffset, 4);
  });

  test('prefixLine acrescenta o prefixo no início da linha do cursor', () {
    setText('primeira\nsegunda', 12);
    edit.prefixLine('## ');
    expect(text.text, 'primeira\n## segunda');
    expect(text.selection.baseOffset, 15);
  });

  test('findNext seleciona a próxima ocorrência e volta ao início', () {
    setText('Sal e sal e SAL', 0);
    expect(edit.findNext('sal'), isTrue);
    expect(text.selection.start, 0);
    expect(edit.findNext('sal'), isTrue);
    expect(text.selection.start, 6);
    expect(edit.findNext('sal'), isTrue);
    expect(text.selection.start, 12);
    expect(edit.findNext('sal'), isTrue);
    expect(text.selection.start, 0);
    expect(edit.findNext('mar'), isFalse);
    expect(edit.findNext(''), isFalse);
  });

  test('replaceCurrent troca só quando a seleção é uma ocorrência', () {
    setText('um dois um', 0);
    expect(edit.replaceCurrent('um', 'X'), isFalse);
    expect(text.text, 'um dois um');
    // The failed attempt above already selected the first occurrence.
    expect(edit.replaceCurrent('um', 'X'), isTrue);
    expect(text.text, 'X dois um');
    expect(text.selection.textInside(text.text), 'um');
  });

  test('insertElement usa o texto selecionado como rótulo', () {
    final now = DateTime.utc(2026);
    final element = NarrativeElement(
      id: 'lia',
      typeId: 'character',
      title: 'Lia',
      summary: '',
      sections: const [],
      phases: const [],
      createdAt: now,
      updatedAt: now,
    );
    setText('Conheci a corredora.', 10, 19);
    edit.insertElement(element);
    expect(text.text, 'Conheci a [[element:lia|corredora]].');
  });
}
