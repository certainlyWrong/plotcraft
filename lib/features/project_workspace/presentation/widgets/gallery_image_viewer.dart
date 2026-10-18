import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../theme/plotcraft_tokens.dart';
import '../../../../ui/components/project_image.dart';

class GalleryImageViewer extends StatefulWidget {
  const GalleryImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<GalleryImageViewer> createState() => _GalleryImageViewerState();
}

class _GalleryImageViewerState extends State<GalleryImageViewer> {
  late int _index = widget.initialIndex;
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _showAt(int index) {
    if (index < 0 || index >= widget.images.length) return;
    setState(() => _index = index);
    _resetZoom();
  }

  void _zoom(double factor) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(.5, 8.0).toDouble();
    _transformationController.value = Matrix4.identity()
      ..scaleByDouble(nextScale, nextScale, 1, 1);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _showAt(_index - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _showAt(_index + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: context.tokens.viewerBackdrop,
    child: Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: context.tokens.viewerBackdrop,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: .5,
                    maxScale: 8,
                    constrained: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Center(
                      child: Hero(
                        tag: 'project-gallery:${widget.images[_index]}',
                        child: ProjectImage(
                          widget.images[_index],
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    _control(
                      tooltip: 'workspace.close_viewer'.tr(),
                      icon: Feather.x,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _control(
                      tooltip: 'workspace.zoom_out'.tr(),
                      icon: Feather.zoom_out,
                      onPressed: () => _zoom(.8),
                    ),
                    _control(
                      tooltip: 'workspace.reset_zoom'.tr(),
                      icon: Feather.maximize_2,
                      onPressed: _resetZoom,
                    ),
                    _control(
                      tooltip: 'workspace.zoom_in'.tr(),
                      icon: Feather.zoom_in,
                      onPressed: () => _zoom(1.25),
                    ),
                  ],
                ),
              ),
              if (_index > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _control(
                      tooltip: 'workspace.previous_image'.tr(),
                      icon: Feather.chevron_left,
                      onPressed: () => _showAt(_index - 1),
                      large: true,
                    ),
                  ),
                ),
              if (_index < widget.images.length - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _control(
                      tooltip: 'workspace.next_image'.tr(),
                      icon: Feather.chevron_right,
                      onPressed: () => _showAt(_index + 1),
                      large: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _control({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool large = false,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: large ? 30 : 20,
    style: IconButton.styleFrom(
      foregroundColor: context.tokens.onImage,
      backgroundColor: context.tokens.imageScrim.withValues(alpha: .5),
      hoverColor: context.tokens.onImage.withValues(alpha: .14),
      minimumSize: large ? const Size(52, 52) : const Size(42, 42),
    ),
    icon: Icon(icon),
  );
}
