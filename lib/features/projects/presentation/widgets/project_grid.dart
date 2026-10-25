import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../cover_palettes.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_popup_menu.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/gris.dart';
import '../../../../core/ui/project_image.dart';

import 'package:plotcraft_core/features/projects/domain/project_format.dart';

import '../../../../core/icons/icon_data.dart';
import '../../../project_workspace/presentation/export/export_runner.dart';

class ProjectGrid extends StatelessWidget {
  const ProjectGrid({
    super.key,
    required this.projects,
    required this.onDelete,
    required this.onOpen,
  });

  final List<StoryProject> projects;
  final ValueChanged<StoryProject> onDelete;
  final ValueChanged<StoryProject> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1400
          ? 4
          : constraints.maxWidth >= 850
          ? 3
          : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: projects.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.22,
        ),
        itemBuilder: (context, index) => _ProjectCard(
          key: ValueKey(projects[index].id),
          project: projects[index],
          index: index,
          onDelete: () => onDelete(projects[index]),
          onOpen: () => onOpen(projects[index]),
        ),
      );
    },
  );
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    super.key,
    required this.project,
    required this.index,
    required this.onDelete,
    required this.onOpen,
  });

  final StoryProject project;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _confirmingDelete = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final onDelete = widget.onDelete;
    final theme = Theme.of(context);
    final ink = context.tokens.ink;
    final palette = coverPalettes[project.coverIndex % coverPalettes.length];
    final isPortuguese = context.locale.languageCode == 'pt';
    final radius = BorderRadius.circular(PlotcraftRadii.surface);

    return Reveal(
      delay: Reveal.staggerFor(widget.index),
      child: MouseRegion(
        cursor: _confirmingDelete
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: PlotcraftMotion.medium,
          curve: PlotcraftMotion.curve,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: radius,
            // The edge only appears in ink when the card is touched.
            border: Border.all(
              color: _hovering
                  ? ink.withValues(alpha: .7)
                  : theme.colorScheme.outlineVariant.withValues(alpha: .5),
            ),
          ),
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _confirmingDelete ? null : widget.onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedScale(
                              scale: _hovering ? 1.04 : 1,
                              duration: PlotcraftMotion.slow,
                              curve: PlotcraftMotion.curve,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CoverWash(
                                    palette: palette,
                                    seed: project.id.hashCode,
                                  ),
                                  if (project.coverFile != null &&
                                      project.directoryPath != null)
                                    ProjectImage(
                                      p.join(
                                        project.directoryPath!,
                                        project.coverFile!,
                                      ),
                                      cacheWidth: 600,
                                    )
                                  else
                                    Positioned(
                                      right: -14,
                                      top: -34,
                                      child: Icon(
                                        Feather.book_open,
                                        size: 180,
                                        color: context.tokens.onImage
                                            .withValues(alpha: .14),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 21,
                              top: 20,
                              child: Tooltip(
                                message: ProjectFormats.of(
                                  project.primaryFormat,
                                ).nameKey.tr(),
                                // Only the badge under the pointer moves, so a
                                // full shelf does not run a clock per card.
                                child: MorphBadge(
                                  still: !_hovering,
                                  size: 36,
                                  color: context.tokens.onImage.withValues(
                                    alpha: .22,
                                  ),
                                  child: Icon(
                                    ProjectFormats.of(project.primaryFormat)
                                        .icon
                                        .data,
                                    size: 18,
                                    color: context.tokens.onImage,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 8,
                              child: PlotcraftPopupMenuButton<String>(
                                tooltip: 'project.options'.tr(),
                                iconColor: context.tokens.onImage,
                                onSelected: (value) {
                                  if (value == 'export') {
                                    exportProjectFile(context, project);
                                  } else if (value == 'delete') {
                                    setState(() => _confirmingDelete = true);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (ProjectFormats.of(project.primaryFormat)
                                      .hasManuscript)
                                    PopupMenuItem(
                                      value: 'export',
                                      child: Text('export.menu'.tr()),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('project.delete'.tr()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: PlotcraftFonts.serif,
                              fontWeight: FontWeight.w500,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            project.subtitle.isNotEmpty
                                ? project.subtitle
                                : project.description.isEmpty
                                ? 'project.untitled_description'.tr()
                                : project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Feather.clock,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: .75),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${'project.created'.tr()} ${_formatDate(project.createdAt, isPortuguese)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_confirmingDelete)
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainer.withValues(
                      alpha: .97,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'project.delete_confirm'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: PlotcraftFonts.serif,
                              fontWeight: FontWeight.w500,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'project.delete_message'.tr(
                              namedArgs: {'title': project.title},
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 8,
                            children: [
                              PlotcraftButton(
                                onPressed: () =>
                                    setState(() => _confirmingDelete = false),
                                label: 'preferences.cancel'.tr(),
                                variant: PlotcraftButtonVariant.text,
                              ),
                              PlotcraftButton(
                                onPressed: onDelete,
                                label: 'preferences.delete_confirm'.tr(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date, bool isPortuguese) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return isPortuguese
      ? '$day/$month/${local.year}'
      : '$month/$day/${local.year}';
}
