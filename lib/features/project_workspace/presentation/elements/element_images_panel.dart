import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/project_image.dart';

import 'package:plotcraft_core/features/project_workspace/domain/element_image.dart';

/// The images of an element: the first one is its cover. Images come from the
/// project gallery or from the computer.
class ElementImagesPanel extends StatelessWidget {
  const ElementImagesPanel({
    super.key,
    required this.images,
    required this.resolvePath,
    required this.onAddFromGallery,
    required this.onAddFromComputer,
    required this.onRemove,
    required this.onMakeCover,
  });

  final List<ElementImage> images;

  /// Absolute path of an image, or null when its file cannot be found.
  final String? Function(ElementImage image) resolvePath;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromComputer;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onMakeCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'elements.images'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  PlotcraftButton(
                    icon: Feather.image,
                    label: 'elements.add_from_gallery'.tr(),
                    variant: PlotcraftButtonVariant.text,
                    onPressed: onAddFromGallery,
                  ),
                  PlotcraftButton(
                    icon: Feather.upload,
                    label: 'elements.add_from_computer'.tr(),
                    variant: PlotcraftButtonVariant.text,
                    onPressed: onAddFromComputer,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Text(
            'elements.no_images'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < images.length; index++)
                _Thumbnail(
                  path: resolvePath(images[index]),
                  cover: index == 0,
                  onRemove: () => onRemove(index),
                  onMakeCover: index == 0 ? null : () => onMakeCover(index),
                ),
            ],
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.path,
    required this.cover,
    required this.onRemove,
    required this.onMakeCover,
  });

  final String? path;
  final bool cover;
  final VoidCallback onRemove;
  final VoidCallback? onMakeCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
            child: path == null
                ? Tooltip(
                    message: 'elements.image_missing'.tr(),
                    child: ColoredBox(
                      color: scheme.surfaceContainerHigh,
                      child: Icon(
                        Feather.alert_triangle,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ProjectImage(
                    path!,
                    cacheWidth: 320,
                    fallback: ColoredBox(
                      color: scheme.surfaceContainerHigh,
                      child: Icon(
                        Feather.image,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          if (cover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.imageScrim.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(PlotcraftRadii.control),
                ),
                child: Text(
                  'elements.cover'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.onImage,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onMakeCover != null)
                  _overlayButton(
                    context,
                    Feather.star,
                    'elements.set_cover'.tr(),
                    onMakeCover!,
                  ),
                _overlayButton(
                  context,
                  Feather.x,
                  'elements.remove'.tr(),
                  onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.imageScrim.withValues(alpha: .55),
          shape: BoxShape.circle,
        ),
        child: PlotcraftIconButton(
          icon: icon,
          tooltip: tooltip,
          size: 13,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
