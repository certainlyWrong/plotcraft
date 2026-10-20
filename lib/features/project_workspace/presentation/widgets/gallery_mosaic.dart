import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/project_image.dart';
import '../../../../core/ui/proportional_image.dart';

/// Masonry of the project's images. Each tile has the true proportion of its
/// image and the image fills it, so nothing is cropped; only extreme shapes
/// (very tall or very wide) are limited and trimmed along their longest side.
class GalleryMosaic extends StatefulWidget {
  const GalleryMosaic({
    super.key,
    required this.images,
    required this.removingImage,
    required this.importing,
    required this.onSelect,
    required this.onRemove,
    this.aspectOf = readImageAspect,
  });

  final List<String> images;
  final bool removingImage;
  final bool importing;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onRemove;

  /// Finds the proportion of an image file (replaced in tests).
  final Future<double> Function(String path) aspectOf;

  /// Width / height limits of a tile.
  static const minAspect = .4;
  static const maxAspect = 3.0;

  /// Proportion used until the real one is known, and for unreadable files.
  static const placeholderAspect = 1.0;

  @override
  State<GalleryMosaic> createState() => _GalleryMosaicState();
}

class _GalleryMosaicState extends State<GalleryMosaic> {
  /// Width / height of each image, by path.
  final _aspects = <String, double>{};
  final _requested = <String>{};

  @override
  void initState() {
    super.initState();
    _probeAll();
  }

  @override
  void didUpdateWidget(covariant GalleryMosaic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      final current = widget.images.toSet();
      _aspects.removeWhere((path, _) => !current.contains(path));
      _requested.removeWhere((path) => !current.contains(path));
      _probeAll();
    }
  }

  void _probeAll() {
    for (final path in widget.images) {
      if (!_requested.add(path)) continue;
      unawaited(_probe(path));
    }
  }

  Future<void> _probe(String path) async {
    double aspect;
    try {
      aspect = await widget.aspectOf(path);
    } catch (_) {
      aspect = GalleryMosaic.placeholderAspect;
    }
    // The list may have changed (or the tile gone) while the file was read.
    if (!mounted || !_requested.contains(path)) return;
    setState(() => _aspects[path] = aspect);
  }

  double _aspectOf(String path) =>
      (_aspects[path] ?? GalleryMosaic.placeholderAspect).clamp(
        GalleryMosaic.minAspect,
        GalleryMosaic.maxAspect,
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900 ? 4 : 3;
      const gap = 12.0;
      const margin = 24.0;
      final columnWidth =
          (constraints.maxWidth - margin * 2 - gap * (columns - 1)) / columns;
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final cacheWidth = (columnWidth * pixelRatio).ceil();

      // Each image goes to the shortest column, so the bottom stays even.
      final columnImages = List.generate(columns, (_) => <int>[]);
      final heights = List.filled(columns, 0.0);
      for (var index = 0; index < widget.images.length; index++) {
        var target = 0;
        for (var column = 1; column < columns; column++) {
          if (heights[column] < heights[target] - .5) target = column;
        }
        columnImages[target].add(index);
        heights[target] += columnWidth / _aspectOf(widget.images[index]) + gap;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(margin, 0, margin, margin),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) const SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    for (final index in columnImages[column]) ...[
                      if (columnImages[column].first != index)
                        const SizedBox(height: gap),
                      AspectRatio(
                        key: ValueKey(widget.images[index]),
                        aspectRatio: _aspectOf(widget.images[index]),
                        child: _MosaicTile(
                          path: widget.images[index],
                          alignment: cropAlignment(
                            _aspects[widget.images[index]] ??
                                GalleryMosaic.placeholderAspect,
                          ),
                          cacheWidth: cacheWidth,
                          onTap: () => widget.onSelect(index),
                          onRemove: () => widget.onRemove(widget.images[index]),
                          removing: widget.removingImage || widget.importing,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _MosaicTile extends StatefulWidget {
  const _MosaicTile({
    required this.path,
    required this.cacheWidth,
    required this.alignment,
    required this.onTap,
    required this.onRemove,
    required this.removing,
  });

  final String path;
  final int cacheWidth;
  final Alignment alignment;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool removing;

  @override
  State<_MosaicTile> createState() => _MosaicTileState();
}

class _MosaicTileState extends State<_MosaicTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'project-gallery:${widget.path}',
              child: ProjectImage(
                widget.path,
                fit: BoxFit.cover,
                alignment: widget.alignment,
                cacheWidth: widget.cacheWidth,
                fallback: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const Center(child: Icon(Feather.image, size: 25)),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1 : 0,
              duration: const Duration(milliseconds: 130),
              child: ColoredBox(
                color: context.tokens.imageScrim.withValues(alpha: .16),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: IconButton.filledTonal(
                      onPressed: widget.removing ? null : widget.onRemove,
                      tooltip: 'workspace.remove_image'.tr(),
                      icon: const Icon(Feather.trash_2, size: 17),
                      style: IconButton.styleFrom(
                        backgroundColor: context.tokens.imageScrim.withValues(
                          alpha: .56,
                        ),
                        foregroundColor: context.tokens.onImage,
                      ),
                    ),
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
