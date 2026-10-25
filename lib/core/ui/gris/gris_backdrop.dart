import 'package:flutter/material.dart';

import 'watercolor_wash.dart';

/// Paper with a watercolour wash drifting behind [child], tinted by the current
/// stage. The screen on top must have a transparent background to let it show.
class GrisBackdrop extends StatelessWidget {
  const GrisBackdrop({super.key, required this.child, this.fps = 20});

  final Widget child;

  /// Frame rate of the drift; see [WatercolorWash.fps].
  final int fps;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Stack(
      fit: StackFit.expand,
      children: [
        WatercolorWash(fps: fps),
        child,
      ],
    ),
  );
}
