import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../theme/plotcraft_tokens.dart';

class PlotcraftTabData {
  const PlotcraftTabData({
    required this.id,
    required this.title,
    required this.icon,
    this.dirty = false,
    this.closable = true,
  });

  final String id;
  final String title;
  final IconData icon;

  /// Shows a dot in place of the close button until the tab is hovered.
  final bool dirty;
  final bool closable;
}

/// Row of document tabs with an optional trailing area (status, actions).
/// Middle-click closes a tab, as in most desktop editors, and dragging one
/// moves it when [onReorder] is given.
class PlotcraftTabBar extends StatelessWidget {
  const PlotcraftTabBar({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onSelect,
    required this.onClose,
    this.trailing,
    this.onTabMenu,
    this.onReorder,
  });

  final List<PlotcraftTabData> tabs;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final Widget? trailing;

  /// Opens a context menu for a tab at the given global position.
  final void Function(String id, Offset position)? onTabMenu;

  /// Moves the tab at index [from] so that it ends up at index [to].
  final void Function(int from, int to)? onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: .6),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .6),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: tabs.length,
              onReorderItem: (from, to) => onReorder?.call(from, to),
              proxyDecorator: (child, index, animation) =>
                  Material(type: MaterialType.transparency, child: child),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final item = _Tab(
                  key: ValueKey(tab.id),
                  data: tab,
                  active: tab.id == activeId,
                  onSelect: () => onSelect(tab.id),
                  onClose: () => onClose(tab.id),
                  onMenu: onTabMenu == null
                      ? null
                      : (position) => onTabMenu!(tab.id, position),
                );
                if (onReorder == null) return item;
                return ReorderableDragStartListener(
                  key: ValueKey(tab.id),
                  index: index,
                  child: item,
                );
              },
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    super.key,
    required this.data,
    required this.active,
    required this.onSelect,
    required this.onClose,
    this.onMenu,
  });

  final PlotcraftTabData data;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onClose;
  final ValueChanged<Offset>? onMenu;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = widget.data;
    final showClose = data.closable && (_hovered || widget.active);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons == kMiddleMouseButton && data.closable) {
            widget.onClose();
          } else if (event.buttons == kSecondaryMouseButton) {
            widget.onMenu?.call(event.position);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: PlotcraftMotion.medium,
            curve: PlotcraftMotion.curve,
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 220),
            padding: const EdgeInsets.only(left: 12, right: 4),
            // The open tab is the one resting on the paper, with a line of ink
            // beneath it; the others are only a breath of tint on hover.
            decoration: BoxDecoration(
              color: widget.active
                  ? scheme.surfaceContainerLowest.withValues(alpha: .84)
                  : _hovered
                  ? context.tokens.ink.withValues(alpha: .06)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: widget.active
                      ? context.tokens.ink
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.icon,
                  size: 14,
                  color: widget.active
                      ? context.tokens.ink
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.active
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: showClose
                      ? InkResponse(
                          radius: 12,
                          onTap: widget.onClose,
                          child: Tooltip(
                            message: 'workspace.close_tab'.tr(),
                            child: Icon(
                              Feather.x,
                              size: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : data.dirty
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: context.tokens.ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
