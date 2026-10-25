import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';

/// Fine speckle laid over the whole window, so colour reads as soaked into
/// paper. Static: it paints once and again only when the window resizes.
class PaperGrain extends StatefulWidget {
  const PaperGrain({super.key});

  @override
  State<PaperGrain> createState() => _PaperGrainState();
}

class _PaperGrainState extends State<PaperGrain> {
  late final Future<ui.FragmentProgram?> _program = GrisShaders.load(
    GrisShaders.grain,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Light speckle on dark paper, dark speckle on light paper.
    final tone = tokens.isDark ? Colors.white : Colors.black;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: FutureBuilder<ui.FragmentProgram?>(
            future: _program,
            builder: (context, snapshot) {
              final program = snapshot.data;
              if (program == null) return const SizedBox.expand();
              return CustomPaint(
                size: Size.infinite,
                painter: _GrainPainter(
                  program,
                  opacity: tokens.grainOpacity,
                  tone: tone,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.program, {required this.opacity, required this.tone});

  final ui.FragmentProgram program;
  final double opacity;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, opacity * 1.6)
      ..setFloat(3, tone.r)
      ..setFloat(4, tone.g)
      ..setFloat(5, tone.b);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    shader.dispose();
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.opacity != opacity || old.tone != tone || old.program != program;
}
