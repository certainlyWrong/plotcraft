import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'project_image.dart';

/// Width / height of the image file, read from its header: the pixels are not
/// decoded. Throws when the file cannot be read as an image.
Future<double> readImageAspect(String path) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    await File(path).readAsBytes(),
  );
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      return descriptor.height == 0 ? 1 : descriptor.width / descriptor.height;
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}

/// Proportions already read, so a card that appears again (a hover card, a
/// tab shown twice) has its final shape from the first frame.
abstract final class ImageAspects {
  static final _known = <String, double>{};

  static double? cached(String path) => _known[path];

  /// The proportion of [path]; null when the file cannot be read.
  static Future<double?> of(
    String path, {
    Future<double> Function(String path) read = readImageAspect,
  }) async {
    final known = _known[path];
    if (known != null) return known;
    try {
      return _known[path] = await read(path);
    } catch (_) {
      return null;
    }
  }

  static void forget(String path) => _known.remove(path);
}

/// Where to anchor an image that has to be cropped: portraits keep their top
/// (faces, heads), the others stay centered.
Alignment cropAlignment(double aspect) =>
    aspect < 1 ? Alignment.topCenter : Alignment.center;

/// An image that fills its box. The box follows the image's own shape, kept
/// between [minAspect] and [maxAspect] (width over height), so a portrait gets
/// a tall box and a landscape a wide one and nothing is cropped. Only a shape
/// beyond those limits is trimmed, along its longest side, and a portrait
/// keeps its top.
class ProportionalImage extends StatefulWidget {
  const ProportionalImage(
    this.path, {
    super.key,
    this.cacheWidth,
    this.minAspect = .5,
    this.maxAspect = 3,
    this.loadingAspect = 16 / 10,
    this.fallback = const SizedBox.shrink(),
    this.readAspect = readImageAspect,
  });

  final String path;
  final int? cacheWidth;
  final double minAspect;
  final double maxAspect;

  /// Shape used until the real one is known and when the file is unreadable.
  final double loadingAspect;

  final Widget fallback;

  /// Finds the proportion of the file (replaced in tests).
  final Future<double> Function(String path) readAspect;

  @override
  State<ProportionalImage> createState() => _ProportionalImageState();
}

class _ProportionalImageState extends State<ProportionalImage> {
  double? _aspect;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ProportionalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolve();
  }

  void _resolve() {
    final path = widget.path;
    _aspect = ImageAspects.cached(path);
    if (_aspect != null) return;
    ImageAspects.of(path, read: widget.readAspect).then((aspect) {
      if (!mounted || widget.path != path || aspect == null) return;
      setState(() => _aspect = aspect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final aspect = (_aspect ?? widget.loadingAspect).clamp(
      widget.minAspect,
      widget.maxAspect,
    );
    return AspectRatio(
      aspectRatio: aspect,
      child: ColoredBox(
        // Behind the image while it loads.
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ProjectImage(
          widget.path,
          fit: BoxFit.cover,
          alignment: cropAlignment(_aspect ?? widget.loadingAspect),
          cacheWidth: widget.cacheWidth,
          fallback: widget.fallback,
        ),
      ),
    );
  }
}
