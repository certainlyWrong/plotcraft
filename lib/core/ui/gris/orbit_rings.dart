import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';
import 'line_work.dart';

/// Concentric rings, arcs and dots that turn slowly, after Gris's circular
/// motifs. Each ring has its own speed and direction. Decoration only.
class OrbitRings extends StatelessWidget {
  const OrbitRings({super.key, this.size = 640});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: GrisClock(
            fps: 24,
            builder: (context, seconds) => CustomPaint(
              size: Size.square(size),
              painter: _OrbitPainter(
                seconds: seconds,
                ink: tokens.ink,
                pigment: tokens.pigment,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required ValueListenable<double> seconds,
    required this.ink,
    required this.pigment,
  }) : _seconds = seconds,
       super(repaint: seconds);

  final ValueListenable<double> _seconds;
  final Color ink;
  final Color pigment;

  // Seconds per turn and direction for rings 1..4, as in the website.
  static const _periods = [24.0, 46.0, 80.0, 120.0];
  static const _directions = [1.0, -1.0, 1.0, -1.0];

  @override
  void paint(Canvas canvas, Size size) {
    // The SVG viewBox is -200..200, so one unit is size / 400.
    canvas.translate(size.width / 2, size.height / 2);
    final unit = size.width / 400;
    canvas.scale(unit);
    final line = ink.withValues(alpha: .5);
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final arc = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = line;

    canvas.drawCircle(
      Offset.zero,
      22,
      Paint()..color = pigment.withValues(alpha: .35 * .5),
    );

    void ring(int i, void Function() draw) {
      canvas.save();
      canvas.rotate(
        _directions[i] * 2 * math.pi * _seconds.value / _periods[i],
      );
      draw();
      canvas.restore();
    }

    ring(0, () {
      canvas.drawCircle(Offset.zero, 62, stroke);
      canvas.drawCircle(const Offset(62, 0), 5, dot);
    });
    ring(1, () {
      canvas.drawPath(
        LineWork.dashed(
          Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 98)),
          const [2, 9],
        ),
        stroke,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 98),
        math.pi,
        math.pi,
        false,
        arc,
      );
      canvas.drawCircle(const Offset(0, -98), 4, dot);
    });
    ring(2, () {
      canvas.drawPath(
        LineWork.dashed(
          Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 136)),
          const [40, 14, 4, 14],
        ),
        stroke,
      );
      canvas.drawCircle(const Offset(-96, 96), 6, dot);
      canvas.drawCircle(
        const Offset(136, 0),
        7,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    });
    ring(3, () {
      final rect = Rect.fromCircle(center: Offset.zero, radius: 184);
      canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, arc);
      canvas.drawArc(rect, math.pi / 2, math.pi / 2, false, arc);
      canvas.drawCircle(const Offset(130, -130), 4, dot);
    });
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.ink != ink || old.pigment != pigment;
}
