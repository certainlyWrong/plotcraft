import 'package:flutter/material.dart';

/// Opens [items] as a menu at a global [position] (for example where the
/// right mouse button was pressed).
Future<T?> showPlotcraftContextMenu<T>(
  BuildContext context,
  Offset position,
  List<PopupMenuEntry<T>> items,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}

/// Shows a context menu on right click over [child].
class PlotcraftContextRegion<T> extends StatelessWidget {
  const PlotcraftContextRegion({
    super.key,
    required this.itemsBuilder,
    required this.onSelected,
    required this.child,
  });

  final List<PopupMenuEntry<T>> Function(BuildContext context) itemsBuilder;
  final ValueChanged<T> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onSecondaryTapDown: (details) async {
      final items = itemsBuilder(context);
      if (items.isEmpty) return;
      final selected = await showPlotcraftContextMenu<T>(
        context,
        details.globalPosition,
        items,
      );
      if (selected != null) onSelected(selected);
    },
    child: child,
  );
}
