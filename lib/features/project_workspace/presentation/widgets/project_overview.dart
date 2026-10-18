import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../models/story_project.dart';
import '../../../../ui/components/plotcraft_button.dart';
import 'project_cover_art.dart';
import '../../../../ui/components/project_image.dart';

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
  });

  final StoryProject project;
  final String manuscript;
  final List<String> images;
  final int wordCount;
  final bool isImporting;
  final VoidCallback onOpenManuscript;
  final VoidCallback onOpenGallery;
  final VoidCallback onImportImages;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'workspace.overview'.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'workspace.overview_intro'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _hero(context),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, content) {
                      final manuscriptCard = _manuscriptCard(context);
                      final galleryCard = _galleryCard(context);
                      if (content.maxWidth < 800) {
                        return Column(
                          children: [
                            manuscriptCard,
                            const SizedBox(height: 16),
                            galleryCard,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: manuscriptCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 6, child: galleryCard),
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
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cover = SizedBox(
          height: constraints.maxWidth < 760 ? 210 : 282,
          child: ProjectCoverArt(project: project),
        );
        final summary = Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(context, 'workspace.about_story'.tr()),
                const SizedBox(height: 12),
                Text(
                  project.description.isEmpty
                      ? 'workspace.description_empty'.tr()
                      : project.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 19),
              ],
            ),
          ),
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cover, const SizedBox(height: 14), summary],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: cover),
            const SizedBox(width: 18),
            Expanded(flex: 6, child: summary),
          ],
        );
      },
    );
  }

  Widget _manuscriptCard(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = manuscript.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(23),
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
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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

  Widget _galleryCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeading(context, Feather.image, 'workspace.gallery'.tr()),
            const SizedBox(height: 7),
            Text(
              'workspace.image_count'.tr(
                namedArgs: {'count': '${images.length}'},
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            if (images.isEmpty)
              Container(
                height: 142,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Feather.image,
                        size: 25,
                        color: theme.colorScheme.primary,
                      ),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final previewCount = constraints.maxWidth < 360 ? 2 : 3;
                  return SizedBox(
                    height: 142,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < images.length && index < previewCount;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 9),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: ProjectImage(
                                images[index],
                                height: double.infinity,
                                cacheWidth: 600,
                                fallback: ColoredBox(
                                  color: theme.colorScheme.surfaceContainer,
                                  child: const Center(
                                    child: Icon(Feather.image),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
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
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _eyebrow(BuildContext context, String label) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}
