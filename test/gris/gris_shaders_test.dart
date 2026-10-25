import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/ui/gris/gris.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A shader that fails to compile resolves to null and the app silently falls
  // back to gradients, so this is the only place a GLSL mistake shows up.
  for (final asset in [GrisShaders.watercolor, GrisShaders.grain]) {
    test('$asset compila e carrega', () async {
      expect(await GrisShaders.load(asset), isNotNull);
    });
  }
}
