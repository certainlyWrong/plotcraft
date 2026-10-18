import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

class GalleryMosaic extends StatelessWidget {
  const GalleryMosaic({
    super.key,
    required this.images,
    required this.removingImage,
    required this.importing,
    required this.onSelect,
    required this.onRemove,
  });

  final List<String> images;
  final bool removingImage;
  final bool importing;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onRemove;

  static const _heightFactors = [1.04, .78, 1.27, .9, 1.15, .84, 1.0];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? 4
          : constraints.maxWidth >= 680
          ? 3
          : constraints.maxWidth >= 420
          ? 2
          : 1;
      final columnImages = List.generate(columns, (_) => <int>[]);
      for (var index = 0; index < images.length; index++) {
        columnImages[index % columns].add(index);
      }
      final gap = constraints.maxWidth < 680 ? 7.0 : 10.0;
      final columnWidth =
          (constraints.maxWidth - gap * (columns + 1)) / columns;

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(gap, 0, gap, gap),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    for (final index in columnImages[column]) ...[
                      if (columnImages[column].first != index)
                        SizedBox(height: gap),
                      SizedBox(
                        height:
                            (columnWidth *
                                    _heightFactors[index %
                                        _heightFactors.length])
                                .clamp(130.0, 430.0),
                        child: _MosaicTile(
                          path: images[index],
                          onTap: () => onSelect(index),
                          onRemove: () => onRemove(images[index]),
                          removing: removingImage || importing,
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
    required this.onTap,
    required this.onRemove,
    required this.removing,
  });

  final String path;
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
              child: Image.file(
                File(widget.path),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const Center(child: Icon(Feather.image, size: 25)),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1 : 0,
              duration: const Duration(milliseconds: 130),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: .16),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: IconButton.filledTonal(
                      onPressed: widget.removing ? null : widget.onRemove,
                      tooltip: 'workspace.remove_image'.tr(),
                      icon: const Icon(Feather.trash_2, size: 17),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: .56),
                        foregroundColor: Colors.white,
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
