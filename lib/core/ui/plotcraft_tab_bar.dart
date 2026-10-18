import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

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
/// Middle-click closes a tab, as in most desktop editors.
class PlotcraftTabBar extends StatelessWidget {
  const PlotcraftTabBar({
    super.key,
    required this.tabs,
    required this.activeId,
    required this.onSelect,
    required this.onClose,
    this.trailing,
    this.onTabMenu,
  });

  final List<PlotcraftTabData> tabs;
  final String? activeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final Widget? trailing;

  /// Opens a context menu for a tab at the given global position.
  final void Function(String id, Offset position)? onTabMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tab in tabs)
                  _Tab(
                    data: tab,
                    active: tab.id == activeId,
                    onSelect: () => onSelect(tab.id),
                    onClose: () => onClose(tab.id),
                    onMenu: onTabMenu == null
                        ? null
                        : (position) => onTabMenu!(tab.id, position),
                  ),
              ],
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
          child: Container(
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 220),
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: widget.active
                  ? scheme.surfaceContainerLowest
                  : _hovered
                  ? scheme.surfaceContainer
                  : null,
              border: Border(
                right: BorderSide(color: scheme.outlineVariant),
                top: BorderSide(
                  color: widget.active ? scheme.primary : Colors.transparent,
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
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: widget.active
                          ? FontWeight.w700
                          : FontWeight.w500,
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
                              color: scheme.primary,
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
