import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import 'gallery_mosaic.dart';

/// Gallery tab: toolbar plus the image mosaic (or an empty-state action).
class GalleryPage extends StatelessWidget {
  const GalleryPage({
    super.key,
    required this.images,
    required this.importing,
    required this.removingImage,
    required this.onImport,
    required this.onRefresh,
    required this.onSelect,
    required this.onRemove,
  });

  final List<String> images;
  final bool importing;
  final bool removingImage;
  final VoidCallback onImport;
  final VoidCallback onRefresh;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (importing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  PlotcraftIconButton(
                    icon: Feather.plus,
                    tooltip: 'workspace.add_images'.tr(),
                    onPressed: onImport,
                  ),
                PlotcraftIconButton(
                  icon: Feather.refresh_cw,
                  tooltip: 'workspace.refresh_gallery'.tr(),
                  onPressed: importing ? null : onRefresh,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: images.isEmpty
              ? Center(
                  child: IconButton(
                    tooltip: 'workspace.add_images'.tr(),
                    onPressed: importing ? null : onImport,
                    iconSize: 34,
                    icon: Icon(Feather.plus, color: scheme.onSurfaceVariant),
                  ),
                )
              : GalleryMosaic(
                  images: images,
                  removingImage: removingImage,
                  importing: importing,
                  onSelect: onSelect,
                  onRemove: onRemove,
                ),
        ),
      ],
    );
  }
}
