import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../../../core/ui/project_image.dart';
import '../../domain/book_content.dart';
import '../../domain/element_image.dart';
import '../../domain/element_type.dart';
import '../../domain/narrative_anchor.dart';
import '../../domain/narrative_element.dart';
import 'element_type_label.dart';

const _none = '';
const _manual = '\u0000manual';
String _chapterChoice(String id) => 'chapter:$id';

/// Creates or edits a phase: a title and description, where in the story it
/// starts, the details that change and which of the element's images shows it.
/// Resolves to the phase, or null if cancelled.
Future<NarrativePhase?> showElementPhaseDialog(
  BuildContext context, {
  NarrativePhase? current,
  required String newId,
  required List<BookChapter> chapters,
  required List<ElementField> fields,
  required List<ElementImage> images,
  required String? Function(ElementImage image) resolvePath,
}) => showDialog<NarrativePhase>(
  context: context,
  builder: (_) => _PhaseDialog(
    current: current,
    newId: newId,
    chapters: chapters,
    fields: fields,
    images: images,
    resolvePath: resolvePath,
  ),
);

class _PhaseDialog extends StatefulWidget {
  const _PhaseDialog({
    required this.current,
    required this.newId,
    required this.chapters,
    required this.fields,
    required this.images,
    required this.resolvePath,
  });

  final NarrativePhase? current;
  final String newId;
  final List<BookChapter> chapters;
  final List<ElementField> fields;
  final List<ElementImage> images;
  final String? Function(ElementImage image) resolvePath;

  @override
  State<_PhaseDialog> createState() => _PhaseDialogState();
}

class _PhaseDialogState extends State<_PhaseDialog> {
  late final _title = TextEditingController(text: widget.current?.title ?? '');
  late final _description = TextEditingController(
    text: widget.current?.description ?? '',
  );
  late final _manualLabel = TextEditingController(
    text: widget.current?.anchor.kind == NarrativeAnchorKind.manual
        ? widget.current!.anchor.value
        : '',
  );
  late final Map<String, TextEditingController> _overrides = {
    for (final field in widget.fields)
      field.id: TextEditingController(
        text: widget.current?.fieldOverrides[field.id] ?? '',
      ),
  };
  late String _anchor = _initialAnchor();
  late ElementImage? _image = widget.current?.image;
  bool _showErrors = false;

  String _initialAnchor() {
    final anchor = widget.current?.anchor ?? const NarrativeAnchor.none();
    return switch (anchor.kind) {
      NarrativeAnchorKind.none => _none,
      NarrativeAnchorKind.manual => _manual,
      // A chapter that no longer exists falls back to "no anchor".
      NarrativeAnchorKind.chapter =>
        widget.chapters.any((chapter) => chapter.id == anchor.value)
            ? _chapterChoice(anchor.value)
            : _none,
    };
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _manualLabel.dispose();
    for (final controller in _overrides.values) {
      controller.dispose();
    }
    super.dispose();
  }

  NarrativeAnchor _buildAnchor() {
    if (_anchor == _none) return const NarrativeAnchor.none();
    if (_anchor == _manual) {
      final label = _manualLabel.text.trim();
      return label.isEmpty
          ? const NarrativeAnchor.none()
          : NarrativeAnchor.manual(label);
    }
    return NarrativeAnchor.chapter(_anchor.substring('chapter:'.length));
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.pop(
      context,
      NarrativePhase(
        id: widget.current?.id ?? widget.newId,
        title: _title.text.trim(),
        description: _description.text,
        anchor: _buildAnchor(),
        fieldOverrides: {
          for (final entry in _overrides.entries)
            if (entry.value.text.trim().isNotEmpty)
              entry.key: entry.value.text.trim(),
        },
        image: _image,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlotcraftDialog(
      title: 'elements.phase'.tr(),
      maxWidth: 680,
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlotcraftTextField(
                controller: _title,
                autofocus: true,
                label: 'elements.phase_title'.tr(),
                helperText: _showErrors && _title.text.trim().isEmpty
                    ? 'elements.title_required'.tr()
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              PlotcraftTextField(
                controller: _description,
                label: 'elements.phase_description'.tr(),
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              Text(
                'elements.phase_starts'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              PlotcraftDropdown<String>(
                initialValue: _anchor,
                items: [
                  DropdownMenuItem(
                    value: _none,
                    child: Text('elements.anchor_none'.tr()),
                  ),
                  for (final chapter in widget.chapters)
                    DropdownMenuItem(
                      value: _chapterChoice(chapter.id),
                      child: Text(
                        chapter.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DropdownMenuItem(
                    value: _manual,
                    child: Text('elements.anchor_manual'.tr()),
                  ),
                ],
                onChanged: (value) => setState(() => _anchor = value ?? _none),
              ),
              if (_anchor == _manual) ...[
                const SizedBox(height: 8),
                PlotcraftTextField(
                  controller: _manualLabel,
                  compact: true,
                  hint: 'elements.anchor_manual_hint'.tr(),
                ),
              ],
              if (widget.fields.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'elements.phase_changes'.tr(),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final field in widget.fields)
                      SizedBox(
                        width: 334,
                        child: PlotcraftTextField(
                          controller: _overrides[field.id]!,
                          compact: true,
                          label: field.displayLabel,
                          hint: 'elements.phase_unchanged'.tr(),
                        ),
                      ),
                  ],
                ),
              ],
              if (widget.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'elements.phase_image'.tr(),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _imageChoice(
                      context,
                      selected: _image == null,
                      onTap: () => setState(() => _image = null),
                      child: Icon(
                        Feather.slash,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    for (final image in widget.images)
                      _imageChoice(
                        context,
                        selected: _image == image,
                        onTap: () => setState(() => _image = image),
                        child: widget.resolvePath(image) == null
                            ? Icon(
                                Feather.alert_triangle,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : ProjectImage(
                                widget.resolvePath(image)!,
                                cacheWidth: 200,
                              ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(label: 'ui.save'.tr(), onPressed: _save),
      ],
    );
  }

  Widget _imageChoice(
    BuildContext context, {
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(PlotcraftRadii.control),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
