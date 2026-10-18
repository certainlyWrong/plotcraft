import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';

NarrativeElement _element(
  String id, [
  List<ElementRelation> relations = const [],
]) => NarrativeElement(
  id: id,
  typeId: 'character',
  title: 'Elemento $id',
  summary: '',
  sections: const [],
  phases: const [],
  relations: relations,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test('a relação é gravada só no elemento de origem e relida do JSON', () {
    final maria = _element('maria', const [
      ElementRelation(
        id: 'r1',
        targetId: 'lia',
        label: 'irmã de',
        reciprocalLabel: 'irmã de',
        note: 'gêmeas',
      ),
    ]);
    final read = NarrativeElement.fromJson(
      jsonDecode(jsonEncode(maria.toJson())) as Map<String, dynamic>,
    );
    expect(read.relations.single.targetId, 'lia');
    expect(read.relations.single.note, 'gêmeas');
    expect(_element('lia').toJson()['relations'], isEmpty);
  });

  test('o índice mostra os dois lados com o rótulo certo', () {
    final index = RelationIndex([
      _element('mentor', const [
        ElementRelation(
          id: 'r',
          targetId: 'aluna',
          label: 'mentor de',
          reciprocalLabel: 'aluna de',
        ),
      ]),
      _element('aluna'),
    ]);
    final fromMentor = index.of('mentor').single;
    expect(fromMentor.other.id, 'aluna');
    expect(fromMentor.label, 'mentor de');
    expect(fromMentor.incoming, isFalse);

    final fromAluna = index.of('aluna').single;
    expect(fromAluna.other.id, 'mentor');
    expect(fromAluna.label, 'aluna de');
    expect(fromAluna.incoming, isTrue);
  });

  test('sem rótulo recíproco usa o rótulo original', () {
    final index = RelationIndex([
      _element('a', const [
        ElementRelation(id: 'r', targetId: 'b', label: 'amigo de'),
      ]),
      _element('b'),
    ]);
    expect(index.of('b').single.label, 'amigo de');
  });

  test('ignora alvos inexistentes e relações consigo mesmo', () {
    final index = RelationIndex([
      _element('a', const [
        ElementRelation(id: 'r1', targetId: 'sumiu', label: 'x'),
        ElementRelation(id: 'r2', targetId: 'a', label: 'eu'),
      ]),
    ]);
    expect(index.of('a'), isEmpty);
    expect(index.of('sumiu'), isEmpty);
  });

  test('prune remove alvos que não existem mais', () {
    final element = _element('a', const [
      ElementRelation(id: 'r1', targetId: 'b', label: 'x'),
      ElementRelation(id: 'r2', targetId: 'sumiu', label: 'y'),
      ElementRelation(id: 'r3', targetId: 'a', label: 'z'),
    ]);
    final kept = RelationIndex.prune(element, {'a', 'b'});
    expect(kept.map((r) => r.id), ['r1']);
  });

  test('entradas inválidas são descartadas', () {
    expect(ElementRelation.fromJson({'id': 'r'}), isNull);
    expect(ElementRelation.fromJson({'id': 'r', 'targetId': ''}), isNull);
    expect(ElementRelation.fromJson('x'), isNull);
    expect(ElementRelation.fromJson({'id': 'r', 'targetId': 't'})?.label, '');
  });
}
