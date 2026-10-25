import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../projects/domain/story_project.dart';
import '../domain/element_type.dart';
import '../domain/element_type_catalog.dart';
import 'project_files.dart';
import '../../../core/file_system.dart';

/// Custom element types, saved in `content/narrative/types.json`. Built-in
/// types are not stored: they come from [ElementTypeCatalog].
class ElementTypesRepository {
  const ElementTypesRepository(this._files);

  final ProjectFiles _files;

  File _file(String folder) =>
      fs.file(p.join(folder, 'content', 'narrative', 'types.json'));

  Future<List<ElementType>> load(String folder) async {
    final file = _file(folder);
    if (!await file.exists()) return [];
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final seen = <String>{};
      return (json['types'] as List<dynamic>? ?? const [])
          .map(ElementType.fromJson)
          .whereType<ElementType>()
          // A built-in ID cannot be redefined; later duplicates are ignored.
          .where(
            (type) =>
                ElementTypeCatalog.builtinById(type.id) == null &&
                seen.add(type.id),
          )
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  /// Saves the custom types. [touch] is false when the write is only an
  /// upgrade of the stored data, so the project's `updatedAt` is kept.
  Future<StoryProject> save(
    StoryProject project,
    List<ElementType> types, {
    bool touch = true,
  }) async {
    final custom = types.where((type) => !type.builtin).toList();
    if (custom.any((type) => type.name.trim().isEmpty) ||
        custom.map((type) => type.id).toSet().length != custom.length) {
      throw const FormatException('Invalid element types');
    }
    await _files.ensureManifest(project);
    await _files.writeJson(_file(_files.folder(project)), {
      'schemaVersion': 1,
      'types': custom.map((type) => type.toJson()).toList(),
    });
    return touch ? _files.touch(project) : project;
  }
}
