import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';

/// Two rings and a dot, drawn in the ink of the current stage: a still echo of
/// the orbits turning behind the app. It is the mark of Plotcraft.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _BrandPainter(context.tokens.ink),
    ),
  );
}

class _BrandPainter extends CustomPainter {
  _BrandPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(centre, size.width * .46, line);
    canvas.drawCircle(centre, size.width * .27, line);
    // A dot riding the outer ring, a little above the horizon.
    canvas.drawCircle(
      centre + Offset.fromDirection(-.9, size.width * .46),
      3,
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_BrandPainter old) => old.ink != ink;
}
