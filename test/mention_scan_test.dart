import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/mention_scan.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';

NarrativeElement _lia({MentionPolicy policy = const MentionPolicy()}) =>
    NarrativeElement(
      id: 'lia',
      typeId: 'character',
      title: 'Lia',
      aliases: const ['A Corredora'],
      summary: '',
      sections: const [],
      phases: const [],
      mentionPolicy: policy,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

void main() {
  final linked = Delta()
    ..insert('Ontem ')
    ..insert('Lia', {
      RichDocument.mentionKey: RichDocument.mention('lia', 'Lia'),
    })
    ..insert(' correu. Depois a corredora parou.\n');

  test('capítulos: lista as ocorrências ligadas e as escritas, na ordem', () {
    final book = BookContent(
      chaptersEnabled: true,
      singleDelta: RichDocument.empty(),
      chapters: const [
        BookChapter(id: 'c1', title: 'Largada'),
        BookChapter(id: 'c2', title: 'Chegada'),
      ],
      chapterDeltas: {'c1': linked, 'c2': Delta()..insert('Nada aqui\n')},
    );
    final found = scanElementMentions(book, _lia(), 'Manuscrito');
    expect(found.map((o) => (o.chapterId, o.linked)), [
      ('c1', true),
      ('c1', false),
    ]);
    expect(found.first.chapterTitle, 'Largada');
    expect(found.first.snippet, contains('Ontem Lia correu'));
    expect(found.last.snippet, contains('corredora'));
  });

  test('manuscrito único usa o título dado e id nulo', () {
    final book = BookContent(
      chaptersEnabled: false,
      singleDelta: linked,
      chapters: const [],
      chapterDeltas: const {},
    );
    final found = scanElementMentions(book, _lia(), 'Manuscrito');
    expect(found.first.chapterId, isNull);
    expect(found.first.chapterTitle, 'Manuscrito');
  });

  test('acha o nome mesmo se a detecção automática estiver desligada', () {
    final book = BookContent(
      chaptersEnabled: false,
      singleDelta: Delta()..insert('Lia chegou.\n'),
      chapters: const [],
      chapterDeltas: const {},
    );
    final found = scanElementMentions(
      book,
      _lia(policy: const MentionPolicy(auto: false)),
      'M',
    );
    expect(found, hasLength(1));
  });

  test('o trecho indica o corte com reticências em textos longos', () {
    final long = '${'palavra ' * 20}Lia ${'palavra ' * 20}';
    final book = BookContent(
      chaptersEnabled: false,
      singleDelta: Delta()..insert('$long\n'),
      chapters: const [],
      chapterDeltas: const {},
    );
    final snippet = scanElementMentions(book, _lia(), 'M').single.snippet;
    expect(snippet, startsWith('…'));
    expect(snippet, endsWith('…'));
    expect(snippet, contains('Lia'));
  });
}
