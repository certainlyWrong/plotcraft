import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:plotcraft_core/core/file_system.dart';

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
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.fallback = const SizedBox.shrink(),
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;

  /// Which part of the image stays visible when [fit] crops it.
  final Alignment alignment;
  final FilterQuality filterQuality;

  /// Shown when the file is missing or cannot be decoded.
  final Widget fallback;

  @override
  Widget build(BuildContext context) => kIsWeb
      ? _MemoryProjectImage(this)
      : Image.file(
          fs.file(path),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          alignment: alignment,
          filterQuality: filterQuality,
          errorBuilder: (_, _, _) => fallback,
        );
}

/// `Image.file` does not exist in the browser, where the project's files are
/// in memory: the bytes are read once per path and handed to `Image.memory`.
class _MemoryProjectImage extends StatefulWidget {
  const _MemoryProjectImage(this.image);

  final ProjectImage image;

  @override
  State<_MemoryProjectImage> createState() => _MemoryProjectImageState();
}

class _MemoryProjectImageState extends State<_MemoryProjectImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(covariant _MemoryProjectImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.path != widget.image.path) _read();
  }

  Future<void> _read() async {
    final path = widget.image.path;
    try {
      final bytes = await fs.file(path).readAsBytes();
      if (mounted && widget.image.path == path) {
        setState(() {
          _bytes = bytes;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted && widget.image.path == path) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final bytes = _bytes;
    if (_failed) return image.fallback;
    if (bytes == null) return const SizedBox.shrink();
    return Image.memory(
      bytes,
      fit: image.fit,
      width: image.width,
      height: image.height,
      cacheWidth: image.cacheWidth,
      alignment: image.alignment,
      filterQuality: image.filterQuality,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => image.fallback,
    );
  }
}
