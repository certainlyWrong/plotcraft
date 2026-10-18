import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../domain/story_project.dart';
import '../../project_creation/presentation/project_creation_screen.dart';
import '../../project_creation/stores/project_creation_store.dart';
import '../../project_workspace/data/project_workspace_repository.dart';
import '../../project_workspace/presentation/project_workspace_screen.dart';
import '../../project_workspace/stores/project_workspace_store.dart';
import '../stores/project_store.dart';
import '../../preferences/stores/theme_store.dart';
import '../../../core/ui/plotcraft_button.dart';
import '../../../core/ui/plotcraft_popup_menu.dart';
import 'widgets/project_empty_state.dart';
import 'widgets/project_grid.dart';
import 'widgets/project_sidebar.dart';
import 'widgets/project_top_bar.dart';
import '../../preferences/presentation/preferences_screen.dart';
import '../../../core/theme/plotcraft_tokens.dart';

enum _DesktopPage { projects, createProject, preferences }

class ProjectHomeScreen extends StatefulWidget {
  const ProjectHomeScreen({
    super.key,
    required this.projects,
    required this.creation,
    required this.themes,
  });

  final ProjectStore projects;
  final ProjectCreationStore creation;
  final ThemeStore themes;

  @override
  State<ProjectHomeScreen> createState() => _ProjectHomeScreenState();
}

class _ProjectHomeScreenState extends State<ProjectHomeScreen> {
  final _searchController = TextEditingController();
  _DesktopPage _page = _DesktopPage.projects;
  ProjectWorkspaceStore? _workspace;
  StoryProject? _openedProject;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProjects() => setState(() => _page = _DesktopPage.projects);

  void _showCreateProject() =>
      setState(() => _page = _DesktopPage.createProject);

  void _showPreferences() => setState(() => _page = _DesktopPage.preferences);

  void _openProject(StoryProject project) {
    setState(() {
      _openedProject = project;
      _workspace = ProjectWorkspaceStore(
        ProjectWorkspaceRepository(),
        widget.projects.updateProject,
      );
    });
  }

  void _closeProject() {
    setState(() {
      _workspace = null;
      _openedProject = null;
      _page = _DesktopPage.projects;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_workspace != null && _openedProject != null) {
      return ProjectWorkspaceScreen(
        key: ValueKey(_openedProject!.id),
        project: _openedProject!,
        store: _workspace!,
        onBack: _closeProject,
      );
    }
    return Observer(
      builder: (_) {
        final projects = widget.projects.visibleProjects;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                ProjectSidebar(
                  compact: MediaQuery.sizeOf(context).width < 1100,
                  onProjects: _showProjects,
                  onNewProject: _showCreateProject,
                  onPreferences: _showPreferences,
                  projectsSelected: _page == _DesktopPage.projects,
                  createSelected: _page == _DesktopPage.createProject,
                  preferencesSelected: _page == _DesktopPage.preferences,
                ),
                Expanded(
                  child: Column(
                    children: [
                      ProjectTopBar(
                        title: switch (_page) {
                          _DesktopPage.projects => 'home.library'.tr(),
                          _DesktopPage.createProject =>
                            'project.create_title'.tr(),
                          _DesktopPage.preferences => 'preferences.title'.tr(),
                        },
                        controller: _page == _DesktopPage.projects
                            ? _searchController
                            : null,
                        onSearch: widget.projects.setQuery,
                        onPreferences: _showPreferences,
                      ),
                      Expanded(
                        child: switch (_page) {
                          _DesktopPage.projects => _ProjectsPage(
                            projects: projects,
                            store: widget.projects,
                            onCreate: _showCreateProject,
                            onOpen: _openProject,
                          ),
                          _DesktopPage.createProject => ProjectCreationScreen(
                            onCancel: _showProjects,
                            onCreated: _openProject,
                            store: widget.creation,
                            destinationPath: widget.projects.projectsRoot,
                          ),
                          _DesktopPage.preferences => PreferencesScreen(
                            themes: widget.themes,
                            projects: widget.projects,
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({
    required this.projects,
    required this.store,
    required this.onCreate,
    required this.onOpen,
  });
  final List<StoryProject> projects;
  final ProjectStore store;
  final VoidCallback onCreate;
  final ValueChanged<StoryProject> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeading(
                onCreate: onCreate,
                hasProjects: store.projects.isNotEmpty,
              ),
              const SizedBox(height: 38),
              _ProjectSectionHeader(
                count: projects.length,
                sortBy: store.sortBy,
                onSort: store.setSort,
              ),
              const SizedBox(height: 17),
              if (projects.isEmpty)
                ProjectEmptyState(
                  hasSearch: store.query.isNotEmpty,
                  onCreate: onCreate,
                )
              else
                ProjectGrid(
                  projects: projects,
                  onOpen: onOpen,
                  onDelete: (project) async {
                    try {
                      await store.delete(project.id);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('project.delete_error'.tr())),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PageHeading extends StatefulWidget {
  const _PageHeading({required this.onCreate, required this.hasProjects});

  final VoidCallback onCreate;
  final bool hasProjects;

  @override
  State<_PageHeading> createState() => _PageHeadingState();
}

class _PageHeadingState extends State<_PageHeading> {
  static const _presentationKeys = ['one', 'two', 'three', 'four'];
  static const _phraseKeys = [
    'home.phrases.one',
    'home.phrases.two',
    'home.phrases.three',
    'home.phrases.four',
    'home.phrases.five',
    'home.phrases.six',
    'home.phrases.seven',
    'home.phrases.eight',
    'home.phrases.nine',
    'home.phrases.ten',
    'home.phrases.eleven',
    'home.phrases.twelve',
  ];

  final _random = Random();
  late final String _presentationKey =
      _presentationKeys[_random.nextInt(_presentationKeys.length)];
  late final String _phraseKey =
      _phraseKeys[_random.nextInt(_phraseKeys.length)];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final presentation = widget.hasProjects ? 'active' : 'empty';
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.eyebrow'.tr(),
          style: textTheme.labelSmall?.copyWith(
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'home.presentations.$presentation.$_presentationKey.title'.tr(),
          style: textTheme.headlineLarge?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w500,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'home.presentations.$presentation.$_presentationKey.intro'.tr(),
          style: textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Feather.feather, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                _phraseKey.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final createButton = PlotcraftButton(
      onPressed: widget.onCreate,
      icon: Feather.plus,
      label: 'home.new_project'.tr(),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 12),
          child: child,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 900
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  introduction,
                  const SizedBox(height: 20),
                  createButton,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: introduction),
                  createButton,
                ],
              ),
      ),
    );
  }
}

class _ProjectSectionHeader extends StatelessWidget {
  const _ProjectSectionHeader({
    required this.count,
    required this.sortBy,
    required this.onSort,
  });

  final int count;
  final String sortBy;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'home.projects'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        _CountBadge(count: count),
        const Spacer(),
        PlotcraftPopupMenuButton<String>(
          initialValue: sortBy,
          onSelected: onSort,
          itemBuilder: (_) => [
            PopupMenuItem(value: 'recent', child: Text('home.recent'.tr())),
            PopupMenuItem(value: 'title', child: Text('home.title_sort'.tr())),
          ],
          tooltip: 'home.sort'.tr(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Icon(
                  Feather.filter,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('home.sort'.tr(), style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
