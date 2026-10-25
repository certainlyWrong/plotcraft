import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/plotcraft_tokens.dart';

/// A drop of pigment that blooms behind [child] while it is hovered or focused,
/// as if watercolour were touched to wet paper.
class PigmentDrop extends StatefulWidget {
  const PigmentDrop({super.key, required this.child, this.active});

  final Widget child;

  /// Forces the bloom on or off. Left null, it follows pointer hover.
  final bool? active;

  @override
  State<PigmentDrop> createState() => _PigmentDropState();
}

class _PigmentDropState extends State<PigmentDrop> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.active ?? _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -10,
            right: -10,
            top: -6,
            bottom: -6,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedOpacity(
                  opacity: on ? .55 : 0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.ease,
                  child: AnimatedScale(
                    scale: on ? 1.05 : .7,
                    duration: const Duration(milliseconds: 900),
                    curve: PlotcraftMotion.curve,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.tokens.pigment,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
