import 'dart:ui';

import '../../theme/plotcraft_tokens.dart';

/// Helpers for the thin ink lines: partial drawing and dashes.
abstract final class LineWork {
  /// The first [fraction] (0..1) of [path], as if the pen were still moving.
  static Path partial(Path path, double fraction) {
    if (fraction >= 1) return path;
    final out = Path();
    if (fraction <= 0) return out;
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return out;
  }

  /// [path] broken into dashes: alternating drawn and blank lengths.
  static Path dashed(Path path, List<double> pattern) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var index = 0;
      while (distance < metric.length) {
        final length = pattern[index % pattern.length];
        if (index.isEven) {
          out.addPath(
            metric.extractPath(
              distance,
              (distance + length).clamp(0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += length;
        index++;
      }
    }
    return out;
  }

  /// Progress of one item in a staggered drawing: item [index] starts after
  /// `index * step` of a run lasting [total], and takes [each] to finish.
  static double staggered(
    double t, {
    required int index,
    required Duration step,
    required Duration each,
    required Duration total,
  }) {
    final now = t * total.inMicroseconds;
    final start = index * step.inMicroseconds;
    final raw = ((now - start) / each.inMicroseconds).clamp(0.0, 1.0);
    return PlotcraftMotion.curve.transform(raw);
  }

  /// Total run time for [count] staggered items.
  static Duration totalFor(int count, Duration step, Duration each) => Duration(
    microseconds: (count - 1) * step.inMicroseconds + each.inMicroseconds,
  );
}
