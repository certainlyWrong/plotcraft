import 'dart:io';

import 'package:flutter/material.dart';

/// Image stored in a project folder (cover or gallery). Thumbnails should pass
/// [cacheWidth] so large originals are decoded at display size only.
class ProjectImage extends StatelessWidget {
  const ProjectImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.filterQuality = FilterQuality.medium,
    this.fallback = const SizedBox.shrink(),
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final FilterQuality filterQuality;

  /// Shown when the file is missing or cannot be decoded.
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    filterQuality: filterQuality,
    errorBuilder: (_, _, _) => fallback,
  );
}
