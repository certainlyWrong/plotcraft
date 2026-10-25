import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';

/// Pools of pigment drifting behind the whole app, tinted by the current stage.
/// Uses the watercolour fragment shader; if that cannot load it paints soft
/// radial gradients in the same places.
class WatercolorWash extends StatefulWidget {
  const WatercolorWash({super.key, this.fps = 20});

  /// How often the drift is redrawn. The wash moves very slowly, so a calm
  /// screen (an editor) can run it at a few frames a second.
  final int fps;

  @override
  State<WatercolorWash> createState() => _WatercolorWashState();
}

class _WatercolorWashState extends State<WatercolorWash> {
  late final Future<ui.FragmentProgram?> _program = GrisShaders.load(
    GrisShaders.watercolor,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = tokens.pigment.withValues(alpha: tokens.washOpacity);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: GrisClock(
            fps: widget.fps,
            builder: (context, seconds) => FutureBuilder<ui.FragmentProgram?>(
              future: _program,
              builder: (context, snapshot) => CustomPaint(
                size: Size.infinite,
                painter: WashPainter(
                  program: snapshot.data,
                  seconds: seconds,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WashPainter extends CustomPainter {
  WashPainter({
    required this.program,
    required ValueListenable<double> seconds,
    required this.color,
  }) : _seconds = seconds,
       super(repaint: seconds);

  final ui.FragmentProgram? program;
  final ValueListenable<double> _seconds;
  final Color color;

  /// The blobs of the SVG original, in its 1000x800 box centred on the origin.
  static const _blobs = <(Offset, double)>[
    (Offset(-270, -210), 300),
    (Offset(300, -70), 255),
    (Offset(20, 260), 310),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final program = this.program;
    if (program != null) {
      final shader = program.fragmentShader()
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, _seconds.value)
        ..setFloat(3, color.r)
        ..setFloat(4, color.g)
        ..setFloat(5, color.b)
        ..setFloat(6, color.a);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
      shader.dispose();
      return;
    }
    _paintFallback(canvas, size);
  }

  void _paintFallback(Canvas canvas, Size size) {
    final scale = size.width / 1000 > size.height / 800
        ? size.width / 1000
        : size.height / 800;
    final t = _seconds.value;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    for (var i = 0; i < _blobs.length; i++) {
      final (centre, radius) = _blobs[i];
      final drift = Offset(
        26 * (i.isEven ? 1 : -1) * math.sin(t / (3.5 + i)),
        24 * math.cos(t / (4.2 + i)),
      );
      final rect = Rect.fromCircle(center: centre + drift, radius: radius);
      canvas.drawCircle(
        rect.center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            rect.center,
            radius,
            [
              color,
              color.withValues(alpha: color.a * .55),
              color.withValues(alpha: 0),
            ],
            const [0, .55, 1],
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WashPainter old) =>
      old.color != color || old.program != program;
}
