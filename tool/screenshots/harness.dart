// Helpers to render the real screens in a widget test and save them as PNG
// files in build/screenshots/, so the interface can be reviewed without
// opening the app.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/core/theme/theme_definition.dart';
import 'package:shared_preferences/shared_preferences.dart';

const screenSize = Size(1440, 900);
final _boundaryKey = GlobalKey();
final outputDir = Directory('build/screenshots');

/// Loads the fonts the app draws with. Tests would otherwise use a block
/// font for every letter and an empty box for every icon.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
    }
    await loader.load();
  }

  await load('Lora', [
    'assets/fonts/Lora-Regular.ttf',
    'assets/fonts/Lora-Medium.ttf',
  ]);
  await load('Merriweather', [
    'assets/fonts/Merriweather-Regular.ttf',
    'assets/fonts/Merriweather-Medium.ttf',
  ]);
  await load('DM Sans', [
    'assets/fonts/DMSans-Regular.ttf',
    'assets/fonts/DMSans-Medium.ttf',
  ]);
  await load('Roboto', [
    'assets/fonts/Roboto-Regular.ttf',
    'assets/fonts/Roboto-Medium.ttf',
  ]);

  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  for (final asset in manifest.listAssets()) {
    if (!asset.startsWith('packages/icons_flutter/fonts/') ||
        !(asset.endsWith('.ttf') || asset.endsWith('.otf'))) {
      continue;
    }
    final family = asset
        .split('/')
        .last
        .replaceAll(RegExp(r'\.(ttf|otf)$'), '');
    final loader = FontLoader('packages/icons_flutter/$family')
      ..addFont(rootBundle.load(asset));
    await loader.load();
  }
}

/// Starts easy_localization with the Portuguese strings.
Future<void> initLocalization() async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Pumps [home] inside the real app theme and translations.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  ThemeDefinition? theme,
  String fontFamily = 'Lora',
  Locale locale = const Locale('pt'),
  Size size = screenSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('pt')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: (theme ?? builtInThemes.first).toThemeData(
              fontFamily: fontFamily,
            ),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: [
              ...context.localizationDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            home: home,
          ),
        ),
      ),
    ),
  );
  // Translations load from the asset bundle in real time.
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (tester.element(find.byType(MaterialApp)).mounted &&
        'workspace.overview'.tr() != 'workspace.overview') {
      break;
    }
  }
  await settle(tester);
}

/// Lets animations, real file IO and image decoding finish.
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Saves the current frame as `build/screenshots/NAME.png`.
Future<String> shot(WidgetTester tester, String name) async {
  await settle(tester, rounds: 3);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  final path = '${outputDir.path}/$name.png';
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.25);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    outputDir.createSync(recursive: true);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
  });
  return path;
}

/// A colorful gradient picture saved as PNG, for sample covers and gallery.
Future<void> writeGradientImage(
  String path,
  Color a,
  Color b, {
  int width = 640,
  int height = 420,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [a, b]),
  );
  final dots = Paint()..color = Colors.white.withValues(alpha: .18);
  for (var i = 0; i < 7; i++) {
    canvas.drawCircle(
      Offset(width * (.1 + i * .14), height * (.3 + (i % 3) * .2)),
      18.0 + i * 7,
      dots,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}
