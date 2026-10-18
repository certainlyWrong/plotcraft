import 'package:plotcraft/core/fonts/project_font_loader.dart';
import 'package:plotcraft/core/fonts/system_fonts.dart';
import 'package:plotcraft/features/project_workspace/data/project_files.dart';
import 'package:plotcraft/features/project_workspace/data/project_fonts_repository.dart';
import 'package:plotcraft/features/project_workspace/stores/editor_fonts_store.dart';

class NoSystemFonts implements SystemFontLister {
  const NoSystemFonts([this.names = const []]);

  final List<String> names;

  @override
  Future<List<String>> families() async => names;
}

/// A fonts store that never asks the operating system for anything.
EditorFontsStore testFontsStore([List<String> system = const []]) =>
    EditorFontsStore(
      const ProjectFontsRepository(ProjectFiles()),
      const ProjectFontLoader(),
      NoSystemFonts(system),
    );
