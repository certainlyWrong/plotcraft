import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';
import 'gris_clock.dart';

/// Fades its child in while it rises and comes into focus, slowly. Delay each
/// of several siblings with [Reveal.staggerFor] so they arrive one by one.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 22,
  });

  final Widget child;
  final Duration delay;

  /// Distance it travels upward while appearing.
  final double rise;

  /// Delay for the [index]th of a group: cycles over four, 90 ms apart.
  static Duration staggerFor(int index) =>
      Duration(milliseconds: (index % 4) * 90);

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 1100);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _run,
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
        widget.delay.inMicroseconds / (widget.delay + _run).inMicroseconds;
    final t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: PlotcraftMotion.curve),
    );
    return AnimatedBuilder(
      animation: t,
      child: widget.child,
      builder: (context, child) {
        if (t.value >= 1) return child!;
        final blur = 6 * (1 - t.value);
        return Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - t.value)),
            child: ImageFiltered(
              enabled: blur > .05,
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
