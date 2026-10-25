import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

/// Desktop window configuration. The minimum size keeps every screen in a
/// layout meant for desktop; there are no phone-width fallbacks.
class WindowService {
  const WindowService._();

  static const initialSize = Size(1280, 800);
  static const minimumSize = Size(1000, 680);

  static Future<void> configure() async {
    if (kIsWeb) return;
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

  static Future<void> setFullScreen(bool value) async {
    if (!kIsWeb) await windowManager.setFullScreen(value);
  }

  /// Tells [listener] when the window leaves full screen (desktop only).
  static void addListener(WindowListener listener) {
    if (!kIsWeb) windowManager.addListener(listener);
  }

  static void removeListener(WindowListener listener) {
    if (!kIsWeb) windowManager.removeListener(listener);
  }
}
