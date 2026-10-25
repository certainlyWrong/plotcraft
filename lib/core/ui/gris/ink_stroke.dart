import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';

/// A short brushed stroke that draws itself under a title, in the ink of the
/// current stage.
class InkStroke extends StatefulWidget {
  const InkStroke({
    super.key,
    this.width = 132,
    this.delay = const Duration(milliseconds: 350),
  });

  final double width;
  final Duration delay;

  @override
  State<InkStroke> createState() => _InkStrokeState();
}

class _InkStrokeState extends State<InkStroke>
    with SingleTickerProviderStateMixin {
  static const _draw = Duration(milliseconds: 1600);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _draw,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (grisStill(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start =
        widget.delay.inMicroseconds / (widget.delay + _draw).inMicroseconds;
    final progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: PlotcraftMotion.curve),
    );
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(widget.width, widget.width * 10 / 132),
        painter: _InkStrokePainter(progress, context.tokens.ink),
      ),
    );
  }
}

class _InkStrokePainter extends CustomPainter {
  _InkStrokePainter(this.progress, this.ink) : super(repaint: progress);

  final Animation<double> progress;
  final Color ink;

  // M2 6 C 18 1, 30 9, 48 5 S 80 1, 96 5 S 120 8, 130 4 (132x10 box)
  static final Path _stroke = Path()
    ..moveTo(2, 6)
    ..cubicTo(18, 1, 30, 9, 48, 5)
    ..cubicTo(66, 1, 80, 1, 96, 5)
    ..cubicTo(112, 9, 120, 8, 130, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 132;
    canvas.scale(scale);
    final paint = Paint()
      ..color = ink.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final metric in _stroke.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_InkStrokePainter old) => old.ink != ink;
}
