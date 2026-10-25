import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';
import 'line_work.dart';

/// A row of stone arches under a deck line, like the bridges and ruins of
/// Gris. Spans the available width and draws itself in once.
class ArchBridge extends StatefulWidget {
  const ArchBridge({super.key, this.height = 90});

  final double height;

  @override
  State<ArchBridge> createState() => _ArchBridgeState();
}

class _ArchBridgeState extends State<ArchBridge>
    with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 180);
  static const _each = Duration(milliseconds: 2600);

  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: LineWork.totalFor(_ArchPainter.arches + 1, _step, _each),
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
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: _ArchPainter(
              draw: _draw,
              ink: context.tokens.ink,
              total: _draw.duration!,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({required this.draw, required this.ink, required this.total})
    : super(repaint: draw);

  final Animation<double> draw;
  final Color ink;
  final Duration total;

  static const arches = 8;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in the 1200x90 box of the SVG, stretched to fit; paths are
    // transformed (not the canvas) so the pen keeps a constant width.
    final fit = Matrix4.diagonal3Values(size.width / 1200, size.height / 90, 1);
    final paint = Paint()
      ..color = ink.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    void stroke(Path path, int index) {
      final progress = LineWork.staggered(
        draw.value,
        index: index,
        step: const Duration(milliseconds: 180),
        each: const Duration(milliseconds: 2600),
        total: total,
      );
      canvas.drawPath(
        LineWork.partial(path, progress).transform(fit.storage),
        paint,
      );
    }

    stroke(
      Path()
        ..moveTo(0, 24)
        ..lineTo(1200, 24),
      0,
    );
    for (var i = 0; i < arches; i++) {
      final left = i * 150 + 10.0;
      stroke(
        Path()
          ..moveTo(left, 24)
          ..lineTo(left, 44)
          ..arcTo(
            Rect.fromLTWH(left, 44 - 46, 130, 92),
            math.pi,
            math.pi,
            false,
          )
          ..lineTo(left + 130, 24),
        i + 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.ink != ink;
}
