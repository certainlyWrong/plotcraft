import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/count_label.dart';

import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import 'gallery_mosaic.dart';
import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/orbit_rings.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'workspace.gallery'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: PlotcraftFonts.serif,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countLabel('workspace.image_count', images.length),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PlotcraftIconButton(
                icon: Feather.refresh_cw,
                tooltip: 'workspace.refresh_gallery'.tr(),
                onPressed: importing ? null : onRefresh,
              ),
              const SizedBox(width: 8),
              if (importing)
                const OrbitRings(size: 40)
              else
                PlotcraftButton(
                  icon: Feather.plus,
                  label: 'workspace.add_images'.tr(),
                  onPressed: onImport,
                ),
            ],
          ),
        ),
        Expanded(
          child: images.isEmpty
              ? Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const OrbitRings(size: 340),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Feather.image,
                            size: 26,
                            color: context.tokens.ink,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'workspace.gallery_empty'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: PlotcraftFonts.serif,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
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
