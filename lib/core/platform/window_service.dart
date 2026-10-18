import 'dart:ui';

import 'package:window_manager/window_manager.dart';

/// Desktop window configuration. The minimum size keeps every screen in a
/// layout meant for desktop; there are no phone-width fallbacks.
class WindowService {
  const WindowService._();

  static const initialSize = Size(1280, 800);
  static const minimumSize = Size(1000, 680);

  static Future<void> configure() async {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: initialSize,
        minimumSize: minimumSize,
        center: true,
        title: 'Plotcraft',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  static Future<void> setFullScreen(bool value) =>
      windowManager.setFullScreen(value);
}
