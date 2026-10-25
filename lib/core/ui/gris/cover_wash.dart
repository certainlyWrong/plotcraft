import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A watercolour cover: pools of [palette] pigment bleeding into the paler
/// [palette] ink, different for each [seed]. Painted once, no animation; it
/// stands where a linear gradient would.
class CoverWash extends StatelessWidget {
  const CoverWash({super.key, required this.palette, this.seed = 0});

  /// Pigment first, then the paler tone it thins to.
  final List<Color> palette;
  final int seed;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _CoverWashPainter(palette, seed),
    ),
  );
}

class _CoverWashPainter extends CustomPainter {
  _CoverWashPainter(this.palette, this.seed);

  final List<Color> palette;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pigment = palette.first;
    final pale = palette.last;
    canvas.drawRect(Offset.zero & size, Paint()..color = pale);

    final random = math.Random(seed);
    final reach = math.max(size.width, size.height);
    // Big soft pools of pigment, then a few smaller, deeper ones on top.
    for (var i = 0; i < 6; i++) {
      final deep = i >= 3;
      final centre = Offset(
        size.width * (.1 + random.nextDouble() * .8),
        size.height * (.1 + random.nextDouble() * .8),
      );
      final radius =
          reach *
          (deep
              ? .22 + random.nextDouble() * .16
              : .45 + random.nextDouble() * .3);
      final colour = deep
          ? Color.lerp(pigment, const Color(0xFF000000), .18)!
          : pigment;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            centre,
            radius,
            [
              colour.withValues(alpha: deep ? .5 : .78),
              colour.withValues(alpha: deep ? .18 : .34),
              colour.withValues(alpha: 0),
            ],
            const [0, .55, 1],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_CoverWashPainter old) =>
      old.seed != seed || old.palette != palette;
}
