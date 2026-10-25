import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/core/file_system.dart';

/// The story bundled with the app so a new person has something to explore:
/// "Herdeiros do Silêncio", complete, with elements, relations, phases and
/// images. It is copied into the projects folder, where it behaves like any
/// other project (and can be edited or deleted).
class SampleProjectInstaller {
  SampleProjectInstaller({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const assetRoot = 'assets/sample/herdeiros-do-silencio/';
  static const _folderName = 'herdeiros-do-silencio';

  final AssetBundle _bundle;

  /// The sample's project ID (the one in its manifest).
  Future<String> sampleId() async {
    final manifest = jsonDecode(
      await _bundle.loadString('${assetRoot}project.json'),
    ) as Map<String, dynamic>;
    return manifest['id'] as String;
  }

  /// Copies the sample into [root] and returns the project folder. If it is
  /// already there, nothing is copied. The copy is made beside the final folder
  /// and renamed at the end, so an interrupted install leaves no half project.
  Future<String> install(String root) async {
    final target = fs.directory(
      p.join(root, '$_folderName-${await sampleId()}'),
    );
    if (await fs.file(p.join(target.path, 'project.json')).exists()) {
      return target.path;
    }
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    final files = manifest
        .listAssets()
        .where((key) => key.startsWith(assetRoot))
        .toList();
    final partial = fs.directory('${target.path}.partial');
    if (await partial.exists()) await partial.delete(recursive: true);
    try {
      for (final key in files) {
        final file = fs.file(
          p.join(partial.path, key.substring(assetRoot.length)),
        );
        await file.parent.create(recursive: true);
        final data = await _bundle.load(key);
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      if (await target.exists()) await target.delete(recursive: true);
      await partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete(recursive: true);
      rethrow;
    }
    return target.path;
  }
}
