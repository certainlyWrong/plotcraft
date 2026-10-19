import 'package:plotcraft_core/core/time_id.dart';
import 'package:test/test.dart';

void main() {
  test('IDs pedidos em sequência nunca se repetem', () {
    final ids = {for (var i = 0; i < 20000; i++) newTimeId()};
    expect(ids, hasLength(20000));
  });
}
