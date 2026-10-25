import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Loads and caches the fragment programs. A program that fails to load (an
/// unsupported backend, a missing asset) resolves to null, and every effect
/// then falls back to a plain painter instead of breaking the screen.
abstract final class GrisShaders {
  static const watercolor = 'shaders/watercolor.frag';
  static const grain = 'shaders/grain.frag';

  static final _cache = <String, Future<ui.FragmentProgram?>>{};

  static Future<ui.FragmentProgram?> load(String asset) =>
      _cache.putIfAbsent(asset, () async {
        try {
          return await ui.FragmentProgram.fromAsset(asset);
        } catch (_) {
          return null;
        }
      });
}

/// Whether motion should be still: the system asked for reduced motion.
bool grisStill(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A slow, low-rate clock for ambient motion (drifting washes, turning rings,
/// twinkling stars). It ticks at [fps] rather than every frame, stops while the
/// window is not in front or the widget is hidden, and stays frozen at [offset] under reduced motion.
class GrisClock extends StatefulWidget {
  const GrisClock({
    super.key,
    required this.builder,
    this.fps = 30,
    this.offset = 0,
  });

  /// Called once per build; painters should listen to `seconds` to repaint.
  final Widget Function(BuildContext context, ValueListenable<double> seconds)
  builder;
  final int fps;

  /// Seconds added to the clock, so neighbours do not move in step.
  final double offset;

  @override
  State<GrisClock> createState() => _GrisClockState();
}

class _GrisClockState extends State<GrisClock>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _seconds = ValueNotifier(widget.offset);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // createTicker (not a bare Ticker) so a clock in a hidden tab or a covered
    // route stops with its TickerMode instead of running unseen.
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final interval = Duration(milliseconds: 1000 ~/ widget.fps);
    if (elapsed - _last < interval) return;
    _last = elapsed;
    _seconds.value = widget.offset + elapsed.inMicroseconds / 1e6;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final shouldRun = _foreground && !grisStill(context);
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}
