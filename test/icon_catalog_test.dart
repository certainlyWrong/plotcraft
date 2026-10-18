import 'package:flutter_test/flutter_test.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft/core/icons/icon_ref.dart';

void main() {
  test('o catálogo traz os conjuntos esperados e muitos ícones', () {
    expect(
      IconCatalog.sets,
      containsAll(['Feather', 'MaterialCommunityIcons', 'RpgAwesome']),
    );
    final total = IconCatalog.sets
        .map((set) => IconCatalog.namesIn(set).length)
        .reduce((a, b) => a + b);
    expect(total, greaterThan(7000));
    expect(IconCatalog.labelOf('RpgAwesome'), 'RPG');
  });

  test('IconRef resolve para o IconData do pacote, sem usar code points', () {
    expect(const IconRef('Feather', 'activity').data, Feather.activity);
    expect(const IconRef('Feather', 'activity').exists, isTrue);
  });

  test('ícone ausente cai no ícone padrão', () {
    const missing = IconRef('Feather', 'nao_existe');
    expect(missing.exists, isFalse);
    expect(missing.data, IconRef.fallback.data);
    expect(const IconRef('Outro', 'x').data, IconRef.fallback.data);
  });

  test('JSON de ida e volta e entradas inválidas', () {
    const ref = IconRef('Entypo', 'home');
    expect(IconRef.fromJson(ref.toJson()), ref);
    expect(IconRef.fromJson(null), isNull);
    expect(IconRef.fromJson({'set': 1, 'name': 'x'}), isNull);
    expect(IconRef.fromJson('Feather.x'), isNull);
  });

  test('busca por todas as palavras, ignorando caixa e sublinhados', () {
    final results = IconCatalog.search('Feather', 'ARROW up');
    expect(results, isNotEmpty);
    expect(results, everyElement(allOf(contains('arrow'), contains('up'))));
    expect(
      IconCatalog.search('Feather', '').length,
      IconCatalog.namesIn('Feather').length,
    );
    expect(IconCatalog.search('Feather', 'zzzzzz'), isEmpty);
  });
}
