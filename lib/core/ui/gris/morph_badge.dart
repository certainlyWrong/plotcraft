import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';

/// A tinted tile whose corners slowly turn from soft squares to circles to
/// leaves and back, like the trees of Gris that change shape. 12 s a cycle.
class MorphBadge extends StatelessWidget {
  const MorphBadge({
    super.key,
    required this.child,
    this.size = 40,
    this.color,
    this.phase = 0,
    this.still = false,
  });

  final Widget child;
  final double size;

  /// Fill; defaults to the stage ink at 18%.
  final Color? color;

  /// Seconds into the cycle at which this badge starts, so a row of them does
  /// not move in step.
  final double phase;

  /// Holds the badge at rest, with no clock running. Use it for rows of many
  /// badges, and let the one under the pointer move.
  final bool still;

  /// Corner radii (top-left, top-right, bottom-right, bottom-left) as a
  /// fraction of [size] at cycle position [t] in 0..1.
  @visibleForTesting
  static List<double> cornersAt(double t) {
    const square = [.25, .25, .25, .25];
    const circle = [.5, .5, .5, .5];
    const leaf = [.5, .25, .5, .25];
    List<double> mix(List<double> a, List<double> b, double f) {
      final eased = Curves.easeInOut.transform(f.clamp(0.0, 1.0));
      return [for (var i = 0; i < 4; i++) a[i] + (b[i] - a[i]) * eased];
    }

    t = t % 1;
    if (t < .35) return mix(square, circle, t / .35);
    if (t < .70) return mix(circle, leaf, (t - .35) / .35);
    return mix(leaf, square, (t - .70) / .30);
  }

  @override
  Widget build(BuildContext context) {
    final fill = color ?? context.tokens.ink.withValues(alpha: .18);
    Widget tile(double seconds, Widget? inner) {
      final c = cornersAt(seconds / 12);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * c[0]),
            topRight: Radius.circular(size * c[1]),
            bottomRight: Radius.circular(size * c[2]),
            bottomLeft: Radius.circular(size * c[3]),
          ),
        ),
        child: inner,
      );
    }

    if (still) return tile(0, Center(child: child));
    return GrisClock(
      fps: 20,
      offset: phase,
      builder: (context, seconds) => ValueListenableBuilder<double>(
        valueListenable: seconds,
        child: Center(child: child),
        builder: (context, value, inner) => tile(value, inner),
      ),
    );
  }
}
