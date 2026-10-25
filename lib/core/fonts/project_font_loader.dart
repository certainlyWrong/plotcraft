import 'package:flutter/services.dart';

import 'package:plotcraft_core/core/fonts/font_file_info.dart';
import 'package:plotcraft_core/core/file_system.dart';

/// Registers font files with Flutter under project-specific family names.
/// A registration lasts for the whole run, so each file is loaded once.
class ProjectFontLoader {
  const ProjectFontLoader();

  static final _loaded = <String>{};

  /// Registers every font of [paths] as `project:<projectKey>:<family>` and
  /// returns the families that are ready to draw.
  Future<List<String>> load(String projectKey, Iterable<String> paths) async {
    final byFamily = <String, FontLoader>{};
    final ready = <String>{};
    for (final path in paths) {
      final file = fs.file(path);
      final stat = await file.stat();
      final bytes = await file.readAsBytes();
      final info = FontFileInfo.read(bytes);
      if (info == null) continue;
      final name = 'project:$projectKey:${info.family}';
      ready.add(info.family);
      final key = '$name|$path|${stat.modified.millisecondsSinceEpoch}';
      if (!_loaded.add(key)) continue;
      (byFamily[name] ??= FontLoader(
        name,
      )).addFont(Future.value(ByteData.sublistView(bytes)));
    }
    for (final loader in byFamily.values) {
      await loader.load();
    }
    return ready.toList();
  }
}
