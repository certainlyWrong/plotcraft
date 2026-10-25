import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft_core/features/export/domain/export_book.dart';
import 'package:plotcraft_core/features/export/domain/export_options.dart';
import 'package:plotcraft_core/features/export/services/book_assembler.dart';
import 'package:plotcraft_core/features/export/services/book_exporter.dart';
import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../../../core/ui/plotcraft_toast.dart';
import 'export_dialog.dart';

typedef _Job = ({ExportBook book, ExportFormat format, ExportOptions options});

Future<Uint8List> _run(_Job job) =>
    exportBook(job.book, job.format, job.options);

/// Asks what to export, where to save it and writes the file. [deltaFor]
/// supplies text that is not saved yet (the open editors).
Future<void> exportProjectFile(
  BuildContext context,
  StoryProject project, {
  Delta? Function(String? chapterId)? deltaFor,
}) async {
  // Created before the first await: the screen may be gone when we report back.
  final messenger = PlotcraftToaster.of(context);
  try {
    final book = await ProjectWorkspaceRepository().book.load(project);
    if (!context.mounted) return;
    final choice = await showExportDialog(
      context,
      chapters: [
        if (book.chaptersEnabled)
          for (final chapter in book.chapters)
            (id: chapter.id, title: chapter.title),
      ],
    );
    if (choice == null) return;

    final name = project.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
    final location = await getSaveLocation(
      suggestedName: '${name.isEmpty ? 'book' : name}.${choice.format.extension}',
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'export.format_${choice.format.name}'.tr(),
          extensions: [choice.format.extension],
        ),
      ],
      confirmButtonText: 'export.save'.tr(),
    );
    if (location == null) return;

    messenger.show(
      'export.working'.tr(),
      duration: const Duration(seconds: 30),
    );
    var options = choice.options;
    if (choice.format == ExportFormat.pdf) {
      options = ExportOptions(
        chapterIds: options.chapterIds,
        includeCover: options.includeCover,
        includeToc: options.includeToc,
        language: options.language,
        fontSize: options.fontSize,
        pdfFonts: await _bundledPdfFonts(),
      );
    }
    final assembled = await BookAssembler().assemble(
      project,
      options,
      deltaFor: deltaFor,
    );
    final bytes = await compute(_run, (
      book: assembled,
      format: choice.format,
      options: options,
    ));
    var path = location.path;
    if (p.extension(path).toLowerCase() != '.${choice.format.extension}') {
      path = '$path.${choice.format.extension}';
    }
    await XFile.fromData(bytes, mimeType: choice.format.mimeType).saveTo(path);
    messenger.show('export.done'.tr(namedArgs: {'name': p.basename(path)}));
  } catch (_) {
    messenger.show('export.error'.tr());
  }
}

Future<PdfFonts> _bundledPdfFonts() async {
  Future<Uint8List> load(String file) async =>
      (await rootBundle.load('assets/fonts/$file')).buffer.asUint8List();
  final regular = await load('Lora-Regular.ttf');
  return PdfFonts(regular: regular, bold: await load('Lora-Medium.ttf'));
}
