import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/brand_mark.dart';
import '../../../../core/ui/gris/ink_stroke.dart';

/// The library's navigation: the name of the app, three places, and nothing
/// else. No drawer fill and no rule — the links sit on the paper, and the one
/// you are on is underlined in ink.
class ProjectSidebar extends StatelessWidget {
  const ProjectSidebar({
    super.key,
    required this.compact,
    required this.onPreferences,
    required this.onProjects,
    required this.onNewProject,
    required this.projectsSelected,
    required this.createSelected,
    required this.preferencesSelected,
  });

  final bool compact;
  final VoidCallback onPreferences;
  final VoidCallback onProjects;
  final VoidCallback onNewProject;
  final bool projectsSelected;
  final bool createSelected;
  final bool preferencesSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: compact ? 76 : 236,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 10 : 28,
          36,
          compact ? 10 : 20,
          24,
        ),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            const BrandMark(),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                'plotcraft',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: PlotcraftFonts.serif,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.4,
                ),
              ),
            ],
            SizedBox(height: compact ? 40 : 44),
            _NavigationItem(
              icon: Feather.grid,
              label: 'home.projects'.tr(),
              selected: projectsSelected,
              onTap: onProjects,
              compact: compact,
            ),
            const SizedBox(height: 6),
            _NavigationItem(
              icon: Feather.plus,
              label: 'home.new_project'.tr(),
              selected: createSelected,
              onTap: onNewProject,
              compact: compact,
            ),
            const Spacer(),
            _NavigationItem(
              icon: Feather.sliders,
              label: 'preferences.title'.tr(),
              selected: preferencesSelected,
              onTap: onPreferences,
              compact: compact,
            ),
            if (!compact) ...[
              const SizedBox(height: 14),
              Text(
                'PLOTCRAFT  ·  0.1',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface.withValues(alpha: .4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatefulWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = context.tokens.ink;
    final lit = widget.selected || _hovered;
    final color = lit ? ink : theme.colorScheme.onSurfaceVariant;
    final icon = Icon(widget.icon, size: 19, color: color);
    return Tooltip(
      message: widget.compact ? widget.label : '',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Semantics(
          container: true,
          excludeSemantics: true,
          button: true,
          selected: widget.selected,
          label: widget.label,
          onTap: widget.onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: widget.compact
                  ? Center(
                      child: _Dot(on: widget.selected, child: icon),
                    )
                  : Row(
                      children: [
                        _Dot(on: widget.selected, child: icon),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: PlotcraftMotion.quick,
                                style: theme.textTheme.titleSmall!.copyWith(
                                  color: widget.selected
                                      ? theme.colorScheme.onSurface
                                      : color,
                                  fontWeight: FontWeight.w500,
                                ),
                                child: Text(widget.label),
                              ),
                              if (widget.selected)
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: InkStroke(width: 56),
                                ),
                            ],
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

/// The icon, with a soft patch of pigment under it while it is the current one.
class _Dot extends StatelessWidget {
  const _Dot({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: PlotcraftMotion.medium,
    curve: PlotcraftMotion.curve,
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.tokens.pigment.withValues(alpha: on ? .28 : 0),
      borderRadius: BorderRadius.circular(on ? 17 : 10),
    ),
    child: child,
  );
}
