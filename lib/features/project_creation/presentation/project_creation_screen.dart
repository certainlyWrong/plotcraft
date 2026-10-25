import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../core/ui/gris/gris.dart';
import '../../../core/ui/plotcraft_button.dart';
import '../../../core/ui/plotcraft_headings.dart';
import '../../../core/ui/plotcraft_surface.dart';
import '../../../core/ui/plotcraft_text_field.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';
import 'package:plotcraft_core/features/projects/domain/project_metadata_input.dart';

import '../stores/project_creation_store.dart';
import '../../projects/presentation/cover_palettes.dart';
import '../../../core/theme/plotcraft_tokens.dart';
import '../../../core/ui/project_image.dart';

import 'package:plotcraft_core/features/projects/domain/cover_image_rules.dart';
import 'package:plotcraft_core/features/projects/domain/project_format.dart';

import '../../../core/icons/icon_data.dart';
import '../../../core/ui/plotcraft_toast.dart';

class ProjectCreationScreen extends StatefulWidget {
  const ProjectCreationScreen({
    super.key,
    required this.onCancel,
    required this.onCreated,
    required this.store,
    required this.destinationPath,
  });

  final VoidCallback onCancel;
  final ValueChanged<StoryProject> onCreated;
  final ProjectCreationStore store;
  final String destinationPath;

  @override
  State<ProjectCreationScreen> createState() => _ProjectCreationScreenState();
}

class _ProjectCreationScreenState extends State<ProjectCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _author = TextEditingController();
  final _genre = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  int _coverIndex = 0;
  String _format = ProjectFormats.book.id;
  String? _coverPath;
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
            extensions: CoverImageRules.extensions,
          ),
        ],
      );
      if (image == null || !mounted) return;
      final isValid = await CoverImageRules.isValid(image.path);
      if (!mounted) return;
      setState(() {
        _coverPath = isValid ? image.path : null;
        _coverError = isValid ? null : 'project.validation.cover_invalid'.tr();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _coverError = 'project.validation.cover_invalid'.tr());
      }
    }
  }

  Future<void> _submit() async {
    if (widget.store.isCreating) return;
    setState(() => _showErrors = true);
    if (!(_formKey.currentState?.validate() ?? false) || _coverError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        plotcraftToast(context, 'project.validation.fix_fields'.tr()),
      );
      return;
    }
    final input = ProjectMetadataInput(
      title: _title.text,
      subtitle: _subtitle.text,
      author: _author.text,
      genre: _genre.text,
      description: _description.text,
      tags: ProjectMetadataInput.parseTags(_tags.text),
      coverIndex: _coverIndex,
      coverSourcePath: _coverPath,
      primaryFormat: _format,
    );
    try {
      final project = await widget.store.create(input);
      if (mounted) widget.onCreated(project);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(plotcraftToast(context, 'project.create_error'.tr()));
      }
    }
  }

  String? _titleError(String? value) =>
      switch (ProjectMetadataInput.validateTitle(value ?? '')) {
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
      switch (ProjectMetadataInput.validateTags(
        ProjectMetadataInput.parseTags(value ?? ''),
      )) {
        ProjectFieldIssue.tooMany => 'project.validation.tags_many'.tr(),
        ProjectFieldIssue.tooLong => 'project.validation.tag_long'.tr(),
        ProjectFieldIssue.duplicated =>
          'project.validation.tags_duplicate'.tr(),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isCreating = widget.store.isCreating;
        return LayoutBuilder(
          builder: (context, page) {
            const padding = 28.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(padding, 44, 48, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlotcraftPageTitle(
                        title: 'project.create_title'.tr(),
                        description: 'project.create_description'.tr(),
                      ),
                      const SizedBox(height: 36),
                      _formatPicker(context),
                      const SizedBox(height: 44),
                      LayoutBuilder(
                        builder: (context, content) {
                          final form = Form(
                            key: _formKey,
                            autovalidateMode: _showErrors
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: _detailsCard(context),
                          );
                          final side = _coverCard(context, isCreating);
                          if (content.maxWidth < 820) {
                            return Column(
                              children: [
                                form,
                                const SizedBox(height: 20),
                                side,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: form),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: side),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Which kind of story this project is. It cannot be changed afterwards.
  Widget _formatPicker(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ink = context.tokens.ink;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final format in ProjectFormats.all)
          SizedBox(
            width: 300,
            child: PlotcraftSurface(
              selected: format.id == _format,
              onTap: () => setState(() => _format = format.id),
              child: Row(
                children: [
                  Icon(
                    format.icon.data,
                    size: 24,
                    color: format.id == _format ? ink : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          format.nameKey.tr(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontFamily: PlotcraftFonts.serif,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          format.descriptionKey.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            number: '01',
            title: 'project.sections.identity'.tr(),
            subtitle: 'project.sections.identity_hint'.tr(),
          ),
          const SizedBox(height: 25),
          PlotcraftTextField(
            controller: _title,
            autofocus: true,
            label: 'project.title'.tr(),
            hint: 'project.title_hint'.tr(),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 120,
            validator: _titleError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          PlotcraftTextField(
            controller: _subtitle,
            label: 'project.subtitle'.tr(),
            hint: 'project.subtitle_hint'.tr(),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 160,
            validator: (value) => _lengthError(
              ProjectMetadataInput.validateSubtitle(value ?? ''),
              160,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final author = PlotcraftTextField(
                controller: _author,
                label: 'project.author'.tr(),
                hint: 'project.author_hint'.tr(),
                maxLength: 120,
                validator: (value) => _lengthError(
                  ProjectMetadataInput.validateAuthor(value ?? ''),
                  120,
                ),
                textInputAction: TextInputAction.next,
              );
              final genre = PlotcraftTextField(
                controller: _genre,
                label: 'project.genre'.tr(),
                hint: 'project.genre_hint'.tr(),
                maxLength: 80,
                validator: (value) => _lengthError(
                  ProjectMetadataInput.validateGenre(value ?? ''),
                  80,
                ),
                textInputAction: TextInputAction.next,
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [author, const SizedBox(height: 14), genre],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: author),
                  const SizedBox(width: 16),
                  Expanded(child: genre),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          _SectionHeading(
            number: '02',
            title: 'project.sections.story'.tr(),
            subtitle: 'project.sections.story_hint'.tr(),
          ),
          const SizedBox(height: 25),
          PlotcraftTextField(
            controller: _description,
            label: 'project.description'.tr(),
            hint: 'project.description_hint'.tr(),
            minLines: 4,
            maxLines: 7,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => _lengthError(
              ProjectMetadataInput.validateDescription(value ?? ''),
              2000,
            ),
          ),
          const SizedBox(height: 14),
          PlotcraftTextField(
            controller: _tags,
            label: 'project.tags'.tr(),
            hint: 'project.tags_hint'.tr(),
            helperText: 'project.tags_help'.tr(),
            validator: _tagsError,
          ),
        ],
      ),
    );
  }

  Widget _coverCard(BuildContext context, bool isCreating) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          number: '03',
          title: 'project.sections.cover'.tr(),
          subtitle: 'project.sections.cover_hint'.tr(),
        ),
        const SizedBox(height: 22),
        AspectRatio(
          aspectRatio: 1.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverWash(
                  palette: coverPalettes[_coverIndex],
                  seed: _coverIndex,
                ),
                if (_coverPath != null) ProjectImage(_coverPath!),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.tokens.imageScrim.withValues(alpha: .55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: AnimatedBuilder(
                    animation: _title,
                    builder: (context, _) => Text(
                      _title.text.trim().isEmpty
                          ? 'project.preview_title'.tr()
                          : _title.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: PlotcraftFonts.serif,
                        color: context.tokens.onImage,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'project.cover_palettes'.tr(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: List.generate(
            coverPalettes.length,
            (index) => _CoverChoice(
              colors: coverPalettes[index],
              seed: index,
              selected: _coverPath == null && index == _coverIndex,
              onTap: () => setState(() {
                _coverIndex = index;
                _coverPath = null;
                _coverError = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PlotcraftButton(
              onPressed: isCreating ? null : _chooseCover,
              icon: Feather.image,
              label: 'project.choose_cover'.tr(),
              variant: PlotcraftButtonVariant.secondary,
            ),
            if (_coverPath != null)
              PlotcraftButton(
                onPressed: isCreating
                    ? null
                    : () => setState(() => _coverPath = null),
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
        const SizedBox(height: 30),
        Text(
          'project.destination'.tr(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.destinationPath,
          softWrap: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: PlotcraftButton(
            onPressed: isCreating ? null : _submit,
            icon: Feather.plus,
            label: isCreating ? 'project.creating'.tr() : 'project.create'.tr(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PlotcraftButton(
            onPressed: isCreating ? null : widget.onCancel,
            label: 'preferences.cancel'.tr(),
            variant: PlotcraftButtonVariant.text,
          ),
        ),
      ],
    );
  }
}

/// A numbered section of the form. The number sits in a badge whose corners
/// slowly turn, and the title is set in serif on open paper.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => PlotcraftSection(
    title: title,
    description: subtitle,
    leading: MorphBadge(
      size: 38,
      phase: int.tryParse(number)?.toDouble() ?? 0,
      child: Text(
        number,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: context.tokens.ink),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _CoverChoice extends StatelessWidget {
  const _CoverChoice({
    required this.colors,
    required this.selected,
    required this.seed,
    required this.onTap,
  });

  final List<Color> colors;
  final bool selected;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PlotcraftMotion.medium,
        curve: PlotcraftMotion.curve,
        width: 62,
        height: 46,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          border: Border.all(
            color: selected ? context.tokens.ink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CoverWash(palette: colors, seed: seed),
            if (selected)
              Icon(Feather.check, color: context.tokens.onSwatch(colors)),
          ],
        ),
      ),
    ),
  );
}
