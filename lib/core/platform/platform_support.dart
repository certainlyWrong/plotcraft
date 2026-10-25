import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// `Platform` throws in the browser, so the checks the app makes go through
/// these, which are simply false on the web.
final bool isMacOS = !kIsWeb && Platform.isMacOS;
final bool isLinux = !kIsWeb && Platform.isLinux;
final bool isWindows = !kIsWeb && Platform.isWindows;
