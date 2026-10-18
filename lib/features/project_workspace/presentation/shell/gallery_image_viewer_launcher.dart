import 'package:flutter/material.dart';

import '../widgets/gallery_image_viewer.dart';

void showGalleryViewer(
  BuildContext context, {
  required List<String> images,
  required int initialIndex,
  required Color barrierColor,
}) {
  showDialog<void>(
    context: context,
    barrierColor: barrierColor,
    builder: (_) =>
        GalleryImageViewer(images: images, initialIndex: initialIndex),
  );
}
