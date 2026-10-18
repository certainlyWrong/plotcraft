import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../../models/story_project.dart';
import '../../../project_creation/presentation/cover_palettes.dart';
import '../../../../ui/components/plotcraft_button.dart';
import '../../../../ui/components/plotcraft_popup_menu.dart';

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
  bool _visible = false;
  bool _hovering = false;
  Timer? _entryTimer;

  @override
  void initState() {
    super.initState();
    _entryTimer = Timer(
      Duration(milliseconds: (widget.index * 55).clamp(0, 330).toInt()),
      () {
        if (mounted) setState(() => _visible = true);
      },
    );
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final onDelete = widget.onDelete;
    final theme = Theme.of(context);
    final palette = coverPalettes[project.coverIndex % coverPalettes.length];
    final isPortuguese = context.locale.languageCode == 'pt';

    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, .035),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedScale(
            scale: _hovering ? 1.012 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: Card(
              color: theme.colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Stack(
                children: [
                  InkWell(
                    onTap: _confirmingDelete ? null : widget.onOpen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: palette,
                                  ),
                                ),
                              ),
                              if (project.coverFile != null &&
                                  project.directoryPath != null)
                                Image.file(
                                  File(
                                    p.join(
                                      project.directoryPath!,
                                      project.coverFile!,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                )
                              else
                                Positioned(
                                  right: -14,
                                  top: -34,
                                  child: Icon(
                                    Feather.book_open,
                                    size: 180,
                                    color: Colors.white.withValues(alpha: .16),
                                  ),
                                ),
                              Positioned(
                                left: 21,
                                top: 20,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Feather.book,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 8,
                                child: PlotcraftPopupMenuButton<String>(
                                  tooltip: 'project.options'.tr(),
                                  iconColor: Colors.white,
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      setState(() => _confirmingDelete = true);
                                    }
                                  },
                                  itemBuilder: (_) => [
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
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
                        color: theme.colorScheme.surface.withValues(alpha: .97),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'project.delete_confirm'.tr(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
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
                                    onPressed: () => setState(
                                      () => _confirmingDelete = false,
                                    ),
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
