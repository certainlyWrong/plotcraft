import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../../models/story_project.dart';
import '../../../../ui/components/plotcraft_button.dart';
import '../../../../ui/components/plotcraft_text_field.dart';
import '../../../project_creation/domain/project_creation_input.dart';
import '../../../project_creation/presentation/cover_palettes.dart';
import 'project_cover_art.dart';

class ProjectMetadataEditor extends StatefulWidget {
  const ProjectMetadataEditor({
    super.key,
    required this.project,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    required this.onChanged,
  });

  final StoryProject project;
  final bool saving;
  final Future<void> Function(ProjectCreationInput input, bool removeCover)
  onSave;
  final VoidCallback onCancel;
  final VoidCallback onChanged;

  @override
  State<ProjectMetadataEditor> createState() => _ProjectMetadataEditorState();
}

class _ProjectMetadataEditorState extends State<ProjectMetadataEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.project.title);
  late final _subtitle = TextEditingController(text: widget.project.subtitle);
  late final _author = TextEditingController(text: widget.project.author);
  late final _genre = TextEditingController(text: widget.project.genre);
  late final _description = TextEditingController(
    text: widget.project.description,
  );
  late final _tags = TextEditingController(
    text: widget.project.tags.join(', '),
  );
  late int _coverIndex = widget.project.coverIndex;
  String? _coverSourcePath;
  bool _removeCover = false;
  String? _coverError;
  bool _showErrors = false;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _author,
      _genre,
      _description,
      _tags,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseCover() async {
    try {
      final image = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'workspace.image_files'.tr(),
            extensions: const ['png', 'jpg', 'jpeg', 'webp'],
          ),
        ],
      );
      if (image == null || !mounted) return;
      final file = File(image.path);
      final extension = p.extension(file.path).toLowerCase();
      final valid =
          {'.png', '.jpg', '.jpeg', '.webp'}.contains(extension) &&
          await file.exists() &&
          await file.length() <= 10 * 1024 * 1024;
      if (!mounted) return;
      setState(() {
        _coverSourcePath = valid ? file.path : null;
        _removeCover = false;
        _coverError = valid ? null : 'project.validation.cover_invalid'.tr();
      });
      if (valid) widget.onChanged();
    } catch (_) {
      if (mounted) {
        setState(() => _coverError = 'project.validation.cover_invalid'.tr());
      }
    }
  }

  Future<void> _save() async {
    if (widget.saving) return;
    setState(() => _showErrors = true);
    if (!(_formKey.currentState?.validate() ?? false) || _coverError != null) {
      return;
    }
    final input = ProjectCreationInput(
      title: _title.text,
      subtitle: _subtitle.text,
      author: _author.text,
      genre: _genre.text,
      description: _description.text,
      tags: ProjectCreationInput.parseTags(_tags.text),
      coverIndex: _coverIndex,
      coverSourcePath: _coverSourcePath,
    );
    await widget.onSave(input, _removeCover);
  }

  String? _titleError(String? value) =>
      switch (ProjectCreationInput.validateTitle(value ?? '')) {
        ProjectFieldIssue.required => 'project.validation.title_required'.tr(),
        ProjectFieldIssue.tooShort => 'project.validation.title_short'.tr(),
        ProjectFieldIssue.tooLong => 'project.validation.too_long'.tr(
          namedArgs: {'max': '120'},
        ),
        _ => null,
      };

  String? _lengthError(ProjectFieldIssue? issue, int max) => issue == null
      ? null
      : 'project.validation.too_long'.tr(namedArgs: {'max': '$max'});

  String? _tagsError(String? value) =>
      switch (ProjectCreationInput.validateTags(
        ProjectCreationInput.parseTags(value ?? ''),
      )) {
        ProjectFieldIssue.tooMany => 'project.validation.tags_many'.tr(),
        ProjectFieldIssue.tooLong => 'project.validation.tag_long'.tr(),
        ProjectFieldIssue.duplicated =>
          'project.validation.tags_duplicate'.tr(),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, viewport) {
        final padding = viewport.maxWidth < 850 ? 24.0 : 46.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 32, padding, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Form(
                key: _formKey,
                autovalidateMode: _showErrors
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'workspace.edit_project'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'workspace.edit_project_intro'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 25),
                    LayoutBuilder(
                      builder: (context, content) {
                        final fields = IgnorePointer(
                          ignoring: widget.saving,
                          child: _fields(context),
                        );
                        final cover = IgnorePointer(
                          ignoring: widget.saving,
                          child: _cover(context),
                        );
                        if (content.maxWidth < 800) {
                          return Column(
                            children: [
                              fields,
                              const SizedBox(height: 16),
                              cover,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: fields),
                            const SizedBox(width: 18),
                            Expanded(flex: 4, child: cover),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        PlotcraftButton(
                          onPressed: widget.saving ? null : _save,
                          icon: Feather.save,
                          label: widget.saving
                              ? 'workspace.saving_project'.tr()
                              : 'workspace.save_project'.tr(),
                        ),
                        PlotcraftButton(
                          onPressed: widget.saving ? null : widget.onCancel,
                          label: 'preferences.cancel'.tr(),
                          variant: PlotcraftButtonVariant.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fields(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'project.sections.identity'.tr(),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          PlotcraftTextField(
            controller: _title,
            onChanged: (_) {
              setState(() {});
              widget.onChanged();
            },
            label: 'project.title'.tr(),
            maxLength: 120,
            validator: _titleError,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          PlotcraftTextField(
            controller: _subtitle,
            onChanged: (_) => widget.onChanged(),
            label: 'project.subtitle'.tr(),
            maxLength: 160,
            validator: (value) => _lengthError(
              ProjectCreationInput.validateSubtitle(value ?? ''),
              160,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, size) {
              final author = PlotcraftTextField(
                controller: _author,
                onChanged: (_) => widget.onChanged(),
                label: 'project.author'.tr(),
                maxLength: 120,
                validator: (value) => _lengthError(
                  ProjectCreationInput.validateAuthor(value ?? ''),
                  120,
                ),
              );
              final genre = PlotcraftTextField(
                controller: _genre,
                onChanged: (_) => widget.onChanged(),
                label: 'project.genre'.tr(),
                maxLength: 80,
                validator: (value) => _lengthError(
                  ProjectCreationInput.validateGenre(value ?? ''),
                  80,
                ),
              );
              if (size.maxWidth < 520) {
                return Column(
                  children: [author, const SizedBox(height: 12), genre],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: author),
                  const SizedBox(width: 12),
                  Expanded(child: genre),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 17),
          Text(
            'project.sections.story'.tr(),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          PlotcraftTextField(
            controller: _description,
            onChanged: (_) => widget.onChanged(),
            label: 'project.description'.tr(),
            minLines: 4,
            maxLines: 7,
            maxLength: 2000,
            validator: (value) => _lengthError(
              ProjectCreationInput.validateDescription(value ?? ''),
              2000,
            ),
          ),
          const SizedBox(height: 12),
          PlotcraftTextField(
            controller: _tags,
            onChanged: (_) => widget.onChanged(),
            label: 'project.tags'.tr(),
            helperText: 'project.tags_help'.tr(),
            validator: _tagsError,
          ),
        ],
      ),
    ),
  );

  Widget _cover(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.project.coverFile != null && !_removeCover;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'project.sections.cover'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: _coverSourcePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(_coverSourcePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Feather.image,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ProjectCoverArt(
                      project: widget.project.copyWith(
                        title: _title.text.trim().isEmpty
                            ? widget.project.title
                            : _title.text.trim(),
                        coverIndex: _coverIndex,
                        removeCover: !existing,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'project.cover_palettes'.tr(),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(coverPalettes.length, (index) {
                final selected =
                    _coverSourcePath == null &&
                    !existing &&
                    _coverIndex == index;
                return Tooltip(
                  message: 'workspace.cover_color'.tr(
                    namedArgs: {'number': '${index + 1}'},
                  ),
                  child: InkWell(
                    onTap: widget.saving
                        ? null
                        : () {
                            setState(() {
                              _coverIndex = index;
                              _coverSourcePath = null;
                              _removeCover = true;
                              _coverError = null;
                            });
                            widget.onChanged();
                          },
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      width: 55,
                      height: 43,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: coverPalettes[index]),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Feather.check, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PlotcraftButton(
                  onPressed: widget.saving ? null : _chooseCover,
                  icon: Feather.image,
                  label: 'project.choose_cover'.tr(),
                  variant: PlotcraftButtonVariant.secondary,
                ),
                if (_coverSourcePath != null || existing)
                  PlotcraftButton(
                    onPressed: widget.saving
                        ? null
                        : () {
                            setState(() {
                              _coverSourcePath = null;
                              _removeCover = true;
                              _coverError = null;
                            });
                            widget.onChanged();
                          },
                    icon: Feather.x,
                    label: 'project.remove_cover'.tr(),
                    variant: PlotcraftButtonVariant.text,
                  ),
              ],
            ),
            if (_coverError != null) ...[
              const SizedBox(height: 8),
              Text(
                _coverError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'workspace.cover_help'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
