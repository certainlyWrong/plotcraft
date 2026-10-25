import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/count_label.dart';

import 'package:icons_flutter/icons_flutter.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../../../core/ui/plotcraft_button.dart';

import 'package:plotcraft_core/features/projects/domain/project_format.dart';

import 'project_cover_art.dart';
import '../../../../core/ui/project_image.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_surface.dart';

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({
    super.key,
    required this.project,
    required this.manuscript,
    required this.images,
    required this.wordCount,
    required this.isImporting,
    required this.onOpenManuscript,
    required this.onOpenGallery,
    required this.onImportImages,
    this.elementCount = 0,
    this.chapterCount = 0,
  });

  final StoryProject project;
  final String manuscript;
  final List<String> images;
  final int wordCount;
  final bool isImporting;
  final VoidCallback onOpenManuscript;
  final VoidCallback onOpenGallery;

  /// Totals shown in the summary row.
  final int elementCount;
  final int chapterCount;
  final VoidCallback onImportImages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'workspace.overview'.tr(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: PlotcraftFonts.serif,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'workspace.overview_intro'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _hero(context),
              const SizedBox(height: 18),
              _summary(context),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (format.hasManuscript) ...[
                    Expanded(flex: 4, child: _manuscriptCard(context)),
                    const SizedBox(width: 16),
                  ],
                  Expanded(flex: 6, child: _galleryCard(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ProjectFormat get format => ProjectFormats.of(project.primaryFormat);

  /// One-line totals: type, words, chapters, elements and images.
  Widget _summary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget stat(IconData icon, String value, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.tokens.ink.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.tokens.ink),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: PlotcraftFonts.serif,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (format.hasManuscript) ...[
          stat(Feather.type, '$wordCount', 'workspace.words_label'.tr()),
          stat(
            Feather.file_text,
            '$chapterCount',
            'workspace.chapters_label'.tr(),
          ),
        ],
        stat(Feather.users, '$elementCount', 'elements.title'.tr()),
        stat(Feather.image, '${images.length}', 'workspace.gallery'.tr()),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: ProjectCoverArt(project: project)),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: PlotcraftCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eyebrow(context, 'workspace.about_story'.tr()),
                    const SizedBox(height: 10),
                    // Long premises scroll inside the card, without a scrollbar.
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          child: Text(
                            project.description.isEmpty
                                ? 'workspace.description_empty'.tr()
                                : project.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _manuscriptCard(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = _excerpt(manuscript);
    return PlotcraftCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading(
              context,
              Feather.file_text,
              'workspace.manuscript'.tr(),
            ),
            const SizedBox(height: 21),
            Text(
              '$wordCount',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: PlotcraftFonts.serif,
                color: context.tokens.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'workspace.words_label'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              excerpt.isEmpty ? 'workspace.manuscript_empty'.tr() : excerpt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 23),
            PlotcraftButton(
              onPressed: onOpenManuscript,
              icon: Feather.arrow_right,
              label: 'workspace.open_manuscript'.tr(),
              variant: PlotcraftButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Body text for the preview card: a leading short line without final
  /// punctuation is a chapter title, not prose, so it is skipped.
  static String _excerpt(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    if (lines.length > 1 &&
        lines.first.length <= 60 &&
        !RegExp(r'[.!?…:;,"”]$').hasMatch(lines.first)) {
      lines.removeAt(0);
    }
    return lines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _galleryCard(BuildContext context) {
    final theme = Theme.of(context);
    return PlotcraftCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading(context, Feather.image, 'workspace.gallery'.tr()),
            const SizedBox(height: 7),
            Text(
              countLabel('workspace.image_count', images.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: context.tokens.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            if (images.isEmpty)
              Container(
                height: 142,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.tokens.ink.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Feather.image, size: 25, color: context.tokens.ink),
                      const SizedBox(height: 9),
                      Text(
                        'workspace.gallery_empty'.tr(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 142,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < images.length && index < 3;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 9),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PlotcraftRadii.control,
                          ),
                          child: ProjectImage(
                            images[index],
                            height: double.infinity,
                            cacheWidth: 600,
                            fallback: ColoredBox(
                              color: theme.colorScheme.surfaceContainer,
                              child: const Center(child: Icon(Feather.image)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PlotcraftButton(
                  onPressed: isImporting ? null : onImportImages,
                  icon: Feather.plus,
                  label: isImporting
                      ? 'workspace.importing'.tr()
                      : 'workspace.add_images'.tr(),
                ),
                PlotcraftButton(
                  onPressed: onOpenGallery,
                  label: 'workspace.open_gallery'.tr(),
                  variant: PlotcraftButtonVariant.text,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardHeading(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.tokens.ink.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: PlotcraftFonts.serif,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _eyebrow(BuildContext context, String label) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: context.tokens.ink,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.1,
    ),
  );
}
