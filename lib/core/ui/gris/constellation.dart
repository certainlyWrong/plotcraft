import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';
import 'line_work.dart';

/// Points joined by thin lines that draw themselves in once, then twinkle.
class Constellation extends StatefulWidget {
  const Constellation({super.key, this.width = 450});

  final double width;

  @override
  State<Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends State<Constellation>
    with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 250);
  static const _each = Duration(milliseconds: 2400);

  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: LineWork.totalFor(
      _ConstellationPainter.links.length,
      _step,
      _each,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (grisStill(context)) {
      _draw.value = 1;
    } else if (!_draw.isAnimating && _draw.value == 0) {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.tokens.ink;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: GrisClock(
            fps: 20,
            builder: (context, seconds) => CustomPaint(
              size: Size(widget.width, widget.width * 280 / 450),
              painter: _ConstellationPainter(
                draw: _draw,
                seconds: seconds,
                ink: ink,
                total: _draw.duration!,
                still: grisStill(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.draw,
    required ValueListenable<double> seconds,
    required this.ink,
    required this.total,
    required this.still,
  }) : _seconds = seconds,
       super(repaint: Listenable.merge([draw, seconds]));

  final Animation<double> draw;
  final ValueListenable<double> _seconds;
  final Color ink;
  final Duration total;
  final bool still;

  static const points = <Offset>[
    Offset(30, 150),
    Offset(120, 70),
    Offset(230, 110),
    Offset(330, 40),
    Offset(420, 120),
    Offset(350, 210),
    Offset(210, 190),
    Offset(120, 240),
  ];
  static const links = <(int, int)>[
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (4, 5),
    (5, 6),
    (6, 7),
    (2, 6),
    (1, 7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 450);
    final base = ink.withValues(alpha: .55);
    final line = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < links.length; i++) {
      final (a, b) = links[i];
      final progress = LineWork.staggered(
        draw.value,
        index: i,
        step: const Duration(milliseconds: 250),
        each: const Duration(milliseconds: 2400),
        total: total,
      );
      if (progress <= 0) continue;
      canvas.drawLine(
        points[a],
        Offset.lerp(points[a], points[b], progress)!,
        line,
      );
    }
    for (var i = 0; i < points.length; i++) {
      // 4s cycle, each star a little behind the last: dips to a quarter.
      final phase = still ? 0.0 : (_seconds.value + i * .7) / 4;
      final twinkle = .625 + .375 * math.cos(2 * math.pi * phase);
      canvas.drawCircle(
        points[i],
        i % 3 == 0 ? 6 : 4,
        Paint()..color = base.withValues(alpha: base.a * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => old.ink != ink;
}
