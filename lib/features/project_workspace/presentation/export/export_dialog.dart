import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plotcraft_core/features/export/domain/export_options.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';

/// What the author chose in the export dialog.
class ExportChoice {
  const ExportChoice({required this.format, required this.options});

  final ExportFormat format;
  final ExportOptions options;
}

/// Asks for the format and options of an export. [chapters] are `(id,
/// title)` pairs; with one chapter or none the chapter list is not shown.
Future<ExportChoice?> showExportDialog(
  BuildContext context, {
  required List<({String id, String title})> chapters,
}) => showDialog<ExportChoice>(
  context: context,
  builder: (_) => _ExportDialog(chapters: chapters),
);

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.chapters});

  final List<({String id, String title})> chapters;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  var _format = ExportFormat.epub;
  var _cover = true;
  var _toc = true;
  String? _language;
  late final Set<String> _chosen = {for (final c in widget.chapters) c.id};

  String get _languageCode {
    final current = _language ?? context.locale.languageCode;
    return const ['en', 'pt', 'es'].contains(current) ? current : 'en';
  }

  void _confirm() {
    final all = _chosen.length == widget.chapters.length;
    Navigator.pop(
      context,
      ExportChoice(
        format: _format,
        options: ExportOptions(
          chapterIds: all || widget.chapters.length < 2 ? null : {..._chosen},
          includeCover: _cover,
          includeToc: _toc,
          language: _languageCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final multiple = widget.chapters.length > 1;
    return PlotcraftDialog(
      title: 'export.title'.tr(),
      maxWidth: 480,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<ExportFormat>(
              showSelectedIcon: false,
              segments: [
                for (final format in ExportFormat.values)
                  ButtonSegment(
                    value: format,
                    label: Text('export.format_${format.name}'.tr()),
                  ),
              ],
              selected: {_format},
              onSelectionChanged: (values) =>
                  setState(() => _format = values.first),
            ),
            const SizedBox(height: 8),
            Text(
              'export.hint_${_format.name}'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            PlotcraftDropdown<String>(
              label: 'export.language'.tr(),
              initialValue: _languageCode,
              items: [
                for (final code in const ['en', 'pt', 'es'])
                  DropdownMenuItem(
                    value: code,
                    child: Text('export.language_$code'.tr()),
                  ),
              ],
              onChanged: (value) => setState(() => _language = value),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _cover,
              onChanged: (value) => setState(() => _cover = value ?? true),
              title: Text('export.include_cover'.tr()),
            ),
            if (multiple)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _toc,
                onChanged: (value) => setState(() => _toc = value ?? true),
                title: Text('export.include_toc'.tr()),
              ),
            if (multiple)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'export.chapters'.tr(
                    namedArgs: {
                      'count': '${_chosen.length}',
                      'total': '${widget.chapters.length}',
                    },
                  ),
                ),
                children: [
                  for (final chapter in widget.chapters)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _chosen.contains(chapter.id),
                      title: Text(chapter.title),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _chosen.add(chapter.id);
                        } else {
                          _chosen.remove(chapter.id);
                        }
                      }),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(
          label: 'export.confirm'.tr(),
          onPressed: multiple && _chosen.isEmpty ? null : _confirm,
        ),
      ],
    );
  }
}
