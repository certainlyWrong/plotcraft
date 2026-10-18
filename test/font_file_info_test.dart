import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft_core/core/fonts/font_file_info.dart';

void main() {
  FontFileInfo? read(String asset) =>
      FontFileInfo.read(File('assets/fonts/$asset').readAsBytesSync());

  test('lê a família das fontes empacotadas', () {
    expect(read('Lora-Regular.ttf')?.family, 'Lora');
    expect(read('Merriweather-Regular.ttf')?.family, 'Merriweather');
    expect(read('Roboto-Regular.ttf')?.family, 'Roboto');
    expect(read('DMSans-Regular.ttf')?.family, startsWith('DM Sans'));
  });

  test('lê também o estilo quando existe', () {
    expect(read('Lora-Medium.ttf')?.style, isNotEmpty);
  });

  test('arquivos que não são fontes devolvem null', () {
    expect(FontFileInfo.read(Uint8List(0)), isNull);
    expect(FontFileInfo.read(Uint8List.fromList(List.filled(64, 7))), isNull);
    expect(
      FontFileInfo.read(File('assets/fonts/Lora-OFL.txt').readAsBytesSync()),
      isNull,
    );
  });

  test('arquivo de fonte truncado não lança exceção', () {
    final bytes = File('assets/fonts/Lora-Regular.ttf').readAsBytesSync();
    expect(FontFileInfo.read(Uint8List.sublistView(bytes, 0, 200)), isNull);
  });
}
