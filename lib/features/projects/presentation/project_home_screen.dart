import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../app/app_commands.dart';
import '../../../core/storage/local_storage.dart';

import 'package:plotcraft_core/features/projects/domain/story_project.dart';

import '../../project_creation/presentation/project_creation_screen.dart';
import '../../project_creation/stores/project_creation_store.dart';

import 'package:plotcraft_core/features/project_workspace/data/project_workspace_repository.dart';

import '../../project_workspace/presentation/project_workspace_screen.dart';
import '../../project_workspace/stores/project_workspace_store.dart';
import '../stores/project_store.dart';
import '../../preferences/stores/theme_store.dart';
import '../../../core/ui/plotcraft_button.dart';
import '../../../core/ui/plotcraft_headings.dart';
import '../../../core/ui/plotcraft_popup_menu.dart';
import 'widgets/project_empty_state.dart';
import 'widgets/project_grid.dart';
import 'widgets/project_sidebar.dart';
import '../../preferences/presentation/preferences_screen.dart';
import '../../../core/theme/plotcraft_tokens.dart';
import '../../../core/ui/gris/gris.dart';
import '../../../core/ui/plotcraft_text_field.dart';

import 'package:plotcraft_core/features/projects/domain/project_format.dart';

import '../../../core/icons/icon_data.dart';
import '../../../core/ui/plotcraft_toast.dart';

enum _DesktopPage { projects, createProject, preferences }

class ProjectHomeScreen extends StatefulWidget {
  const ProjectHomeScreen({
    super.key,
    required this.projects,
    required this.creation,
    required this.themes,
    required this.storage,
    required this.commands,
  });

  final ProjectStore projects;
  final ProjectCreationStore creation;
  final ThemeStore themes;
  final LocalStorage storage;
  final AppCommands commands;

  @override
  State<ProjectHomeScreen> createState() => _ProjectHomeScreenState();
}

class _ProjectHomeScreenState extends State<ProjectHomeScreen> {
  final _searchController = TextEditingController();
  _DesktopPage _page = _DesktopPage.projects;
  ProjectWorkspaceStore? _workspace;
  StoryProject? _openedProject;

  @override
  void initState() {
    super.initState();
    widget.commands.openProjectRequest.addListener(_onOpenRequest);
  }

  @override
  void dispose() {
    widget.commands.openProjectRequest.removeListener(_onOpenRequest);
    _searchController.dispose();
    super.dispose();
  }

  /// Another part of the app (the MCP bridge) asked for a project to open.
  void _onOpenRequest() {
    final id = widget.commands.openProjectRequest.value;
    if (id == null) return;
    widget.commands.openProjectRequest.value = null;
    final project = widget.projects.projects
        .where((item) => item.id == id)
        .firstOrNull;
    if (project != null && _openedProject?.id != id) _openProject(project);
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

  bool _installingSample = false;

  /// Copies the bundled example into the library and opens it.
  Future<void> _openSample() async {
    if (_installingSample) return;
    setState(() => _installingSample = true);
    try {
      final sample = await widget.projects.installSample();
      if (mounted) _openProject(sample);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(plotcraftToast(context, 'home.sample_error'.tr()));
      }
    } finally {
      if (mounted) setState(() => _installingSample = false);
    }
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
        commands: widget.commands,
        project: _openedProject!,
        store: _workspace!,
        onBack: _closeProject,
        storage: widget.storage,
      );
    }
    return Observer(
      builder: (_) {
        final projects = widget.projects.visibleProjects;

        // Colour enters the world as you make something: the library and the
        // settings are grey, the page where a project begins turns red.
        final stage = _page == _DesktopPage.createProject
            ? StageId.red
            : StageId.grey;
        return StageScope(
          stage: stage,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GrisBackdrop(
              child: SafeArea(
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
                      child: AnimatedSwitcher(
                        duration: PlotcraftMotion.medium,
                        switchInCurve: PlotcraftMotion.curve,
                        // The default layout centres a page that is shorter
                        // than the window; pages must start at the top.
                        layoutBuilder: (current, previous) => Stack(
                          fit: StackFit.expand,
                          children: [...previous, ?current],
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_page),
                          child: switch (_page) {
                            _DesktopPage.projects => _ProjectsPage(
                              projects: projects,
                              store: widget.projects,
                              searchController: _searchController,
                              onCreate: _showCreateProject,
                              onOpen: _openProject,
                              onSample: widget.projects.canInstallSample
                                  ? _openSample
                                  : null,
                              installingSample: _installingSample,
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
                      ),
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
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({
    required this.projects,
    required this.store,
    required this.searchController,
    required this.onCreate,
    required this.onOpen,
    required this.onSample,
    required this.installingSample,
  });
  final List<StoryProject> projects;
  final ProjectStore store;
  final TextEditingController searchController;
  final VoidCallback onCreate;
  final ValueChanged<StoryProject> onOpen;

  /// Opens the bundled example; null when it is already in the library.
  final VoidCallback? onSample;
  final bool installingSample;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(28, 44, 48, 48),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeading(
              onCreate: onCreate,
              onSample: onSample,
              installingSample: installingSample,
              hasProjects: store.projects.isNotEmpty,
            ),
            const SizedBox(height: 64),
            _ProjectSectionHeader(
              count: projects.length,
              searchController: searchController,
              onSearch: store.setQuery,
              sortBy: store.sortBy,
              onSort: store.setSort,
              formats: store.usedFormats,
              formatFilter: store.formatFilter,
              onFormat: store.setFormatFilter,
            ),
            const SizedBox(height: 22),
            if (projects.isEmpty)
              ProjectEmptyState(
                hasSearch: store.query.isNotEmpty,
                onCreate: onCreate,
                onSample: onSample,
                installingSample: installingSample,
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
                        plotcraftToast(context, 'project.delete_error'.tr()),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _PageHeading extends StatefulWidget {
  const _PageHeading({
    required this.onCreate,
    required this.hasProjects,
    required this.onSample,
    required this.installingSample,
  });

  final VoidCallback onCreate;
  final VoidCallback? onSample;
  final bool installingSample;
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
    final presentation = widget.hasProjects ? 'active' : 'empty';
    final theme = Theme.of(context);
    final ink = context.tokens.ink;
    final introduction = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlotcraftPageTitle(
          eyebrow: 'home.eyebrow'.tr(),
          title: 'home.presentations.$presentation.$_presentationKey.title'
              .tr(),
          description:
              'home.presentations.$presentation.$_presentationKey.intro'.tr(),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: const Duration(milliseconds: 360),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Feather.feather, size: 15, color: ink),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  _phraseKey.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: PlotcraftFonts.serif,
                    color: ink,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Reveal(
      delay: const Duration(milliseconds: 450),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.onSample != null)
            PlotcraftButton(
              onPressed: widget.installingSample ? null : widget.onSample,
              icon: Feather.compass,
              label: 'home.open_sample'.tr(),
              variant: PlotcraftButtonVariant.secondary,
            ),
          PlotcraftButton(
            onPressed: widget.onCreate,
            icon: Feather.plus,
            label: 'home.new_project'.tr(),
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Rings turning slowly in the corner, mostly out of the page.
        const Positioned(right: -250, top: -360, child: OrbitRings(size: 520)),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 900
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [introduction, const SizedBox(height: 24), actions],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: introduction),
                    actions,
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProjectSectionHeader extends StatelessWidget {
  const _ProjectSectionHeader({
    required this.count,
    required this.searchController,
    required this.onSearch,
    required this.sortBy,
    required this.onSort,
    required this.formats,
    required this.formatFilter,
    required this.onFormat,
  });

  /// Formats present in the library; the filter is shown for two or more.
  final List<String> formats;
  final String formatFilter;
  final ValueChanged<String> onFormat;
  final int count;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String sortBy;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'home.projects'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: PlotcraftFonts.serif,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        MorphBadge(
          size: 28,
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.tokens.ink,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 240,
          child: PlotcraftTextField(
            controller: searchController,
            onChanged: onSearch,
            hint: 'home.search'.tr(),
            prefixIcon: const Icon(Feather.search, size: 16),
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        if (formats.length > 1)
          PlotcraftPopupMenuButton<String>(
            initialValue: formatFilter,
            onSelected: onFormat,
            tooltip: 'formats.filter'.tr(),
            itemBuilder: (_) => [
              PopupMenuItem(value: '', child: Text('formats.all'.tr())),
              for (final id in formats)
                PopupMenuItem(
                  value: id,
                  child: Text(ProjectFormats.of(id).nameKey.tr()),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(
                    formatFilter.isEmpty
                        ? Feather.layers
                        : ProjectFormats.of(formatFilter).icon.data,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatFilter.isEmpty
                        ? 'formats.filter'.tr()
                        : ProjectFormats.of(formatFilter).nameKey.tr(),
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
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
