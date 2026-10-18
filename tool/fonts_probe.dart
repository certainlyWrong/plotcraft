// Lists the system fonts through the native channel and checks that a font
// file registered by ProjectFontLoader is really used for drawing.
//   flutter run -d macos -t tool/fonts_probe.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plotcraft/core/fonts/project_font_loader.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';

double _width(String family) {
  final painter = TextPainter(
    text: TextSpan(
      text: 'Wxyzmmmiii The quick brown fox',
      style: TextStyle(fontFamily: family, fontSize: 40),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final families = await const PlatformSystemFontLister().families();
  stdout.writeln(
    'PROBE system fonts: ${families.length}, first: ${families.take(5).toList()}, has Georgia: ${families.contains('Georgia')}',
  );
  const unknown = 'project:probe:Missing';
  final before = _width(unknown);
  // The app is sandboxed: read the font from the asset bundle and write it
  // inside the app's own temporary folder, as a copied project font would be.
  final data = await rootBundle.load('assets/fonts/Merriweather-Regular.ttf');
  final file = File('${(await getTemporaryDirectory()).path}/probe-font.ttf')
    ..createSync(recursive: true)
    ..writeAsBytesSync(data.buffer.asUint8List());
  final ready = await const ProjectFontLoader().load('probe', [file.path]);
  final after = _width('project:probe:Merriweather');
  stdout.writeln(
    'PROBE registered=$ready fallbackWidth=${before.toStringAsFixed(1)} projectFontWidth=${after.toStringAsFixed(1)} differs=${(before - after).abs() > 1}',
  );
  stdout.writeln('PROBE done');
  exit(0);
}
