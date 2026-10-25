import 'package:flutter/material.dart';

/// Corner radii: soft surfaces, quiet controls. Nothing is a stadium pill.
abstract final class PlotcraftRadii {
  static const control = 8.0;
  static const panel = 12.0;
  static const surface = 14.0;
}

/// One slow, soft easing for the whole app, the same curve as the website.
abstract final class PlotcraftMotion {
  static const curve = Cubic(0.22, 0.61, 0.36, 1);
  static const quick = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 600);
  static const slow = Duration(milliseconds: 1100);

  /// How long colour takes to bleed from one stage to the next.
  static const bleed = Duration(milliseconds: 1600);
}

/// Serif for voice (titles, quotes), sans for function (controls, labels).
abstract final class PlotcraftFonts {
  static const serif = 'Lora';
}

/// A stage of the journey: [pigment] fills areas (washes, drops, swatches) and
/// [ink] draws lines and accent text. Colour is progress, not decoration.
@immutable
class GrisStage {
  const GrisStage({required this.pigment, required this.ink});

  final Color pigment;
  final Color ink;

  static GrisStage lerp(GrisStage a, GrisStage b, double t) => GrisStage(
    pigment: Color.lerp(a.pigment, b.pigment, t)!,
    ink: Color.lerp(a.ink, b.ink, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is GrisStage && other.pigment == pigment && other.ink == ink;

  @override
  int get hashCode => Object.hash(pigment, ink);
}

/// The five stages, by name. Colour enters the world in this order.
enum StageId { grey, red, green, blue, yellow }

/// Pigment and ink per stage for dark and light themes. Same values as
/// `website/src/style.css`; ink is lighter than pigment on dark and darker on
/// light so it always keeps contrast.
abstract final class GrisStages {
  static const dark = <StageId, GrisStage>{
    StageId.grey: GrisStage(pigment: Color(0xFF8A9091), ink: Color(0xFFB9C0BF)),
    StageId.red: GrisStage(pigment: Color(0xFFC9706A), ink: Color(0xFFE8A39C)),
    StageId.green: GrisStage(
      pigment: Color(0xFF6FA58A),
      ink: Color(0xFFA5D3BB),
    ),
    StageId.blue: GrisStage(pigment: Color(0xFF5F86B8), ink: Color(0xFF9DBDE6)),
    StageId.yellow: GrisStage(
      pigment: Color(0xFFD6B55A),
      ink: Color(0xFFECD48E),
    ),
  };

  static const light = <StageId, GrisStage>{
    StageId.grey: GrisStage(pigment: Color(0xFF9AA2A3), ink: Color(0xFF4F5A5B)),
    StageId.red: GrisStage(pigment: Color(0xFFD98C86), ink: Color(0xFFA2423C)),
    StageId.green: GrisStage(
      pigment: Color(0xFF86B8A0),
      ink: Color(0xFF2F6B50),
    ),
    StageId.blue: GrisStage(pigment: Color(0xFF7F9FCB), ink: Color(0xFF2F5A91)),
    StageId.yellow: GrisStage(
      pigment: Color(0xFFE3C670),
      ink: Color(0xFF7D5F0C),
    ),
  };
}

/// Colours for content drawn over images (covers, gallery, viewer) plus the
/// Gris palette in use. Image colours do not follow the app palette because the
/// image underneath is what sets the contrast.
@immutable
class PlotcraftTokens extends ThemeExtension<PlotcraftTokens> {
  const PlotcraftTokens({
    this.onImage = Colors.white,
    this.imageScrim = Colors.black,
    this.viewerBackdrop = const Color(0xFF080808),
    this.stage = const GrisStage(
      pigment: Color(0xFF8A9091),
      ink: Color(0xFFB9C0BF),
    ),
    this.washOpacity = .3,
    this.grainOpacity = .05,
    this.paper = const Color(0xFF2A3031),
    this.isDark = true,
  });

  /// Text and icons over images and cover art.
  final Color onImage;

  /// Base color for darkening overlays above images.
  final Color imageScrim;

  /// Background of the full-screen image viewer.
  final Color viewerBackdrop;

  /// Pigment and ink of the current stage.
  final GrisStage stage;

  /// Strength of the watercolour wash behind the app.
  final double washOpacity;

  /// Strength of the paper grain laid over everything.
  final double grainOpacity;

  /// Surface colour of paper-like panels (dialogs, cards).
  final Color paper;

  final bool isDark;

  Color get pigment => stage.pigment;
  Color get ink => stage.ink;

  /// Readable foreground for a flat or gradient swatch, by its luminance.
  Color onSwatch(Iterable<Color> swatch) {
    final luminance =
        swatch
            .map((color) => color.computeLuminance())
            .reduce((a, b) => a + b) /
        swatch.length;
    return luminance > .5 ? imageScrim : onImage;
  }

  @override
  PlotcraftTokens copyWith({
    Color? onImage,
    Color? imageScrim,
    Color? viewerBackdrop,
    GrisStage? stage,
    double? washOpacity,
    double? grainOpacity,
    Color? paper,
    bool? isDark,
  }) => PlotcraftTokens(
    onImage: onImage ?? this.onImage,
    imageScrim: imageScrim ?? this.imageScrim,
    viewerBackdrop: viewerBackdrop ?? this.viewerBackdrop,
    stage: stage ?? this.stage,
    washOpacity: washOpacity ?? this.washOpacity,
    grainOpacity: grainOpacity ?? this.grainOpacity,
    paper: paper ?? this.paper,
    isDark: isDark ?? this.isDark,
  );

  @override
  PlotcraftTokens lerp(ThemeExtension<PlotcraftTokens>? other, double t) {
    if (other is! PlotcraftTokens) return this;
    return PlotcraftTokens(
      onImage: Color.lerp(onImage, other.onImage, t)!,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
      viewerBackdrop: Color.lerp(viewerBackdrop, other.viewerBackdrop, t)!,
      stage: GrisStage.lerp(stage, other.stage, t),
      washOpacity: washOpacity + (other.washOpacity - washOpacity) * t,
      grainOpacity: grainOpacity + (other.grainOpacity - grainOpacity) * t,
      paper: Color.lerp(paper, other.paper, t)!,
      isDark: t < .5 ? isDark : other.isDark,
    );
  }
}

extension PlotcraftTokensContext on BuildContext {
  /// Tokens with the stage from the nearest [StageScope], if any.
  PlotcraftTokens get tokens {
    final base =
        Theme.of(this).extension<PlotcraftTokens>() ?? const PlotcraftTokens();
    final scoped = _StageInherited.maybeOf(this);
    return scoped == null ? base : base.copyWith(stage: scoped);
  }
}

/// Says which stage of the journey the subtree is in. [PlotcraftTokens.stage]
/// follows it, so a screen only declares where it is. When the stage (or the
/// theme) changes, pigment and ink bleed into the new colours over
/// [PlotcraftMotion.bleed] instead of cutting.
class StageScope extends StatefulWidget {
  const StageScope({super.key, required this.stage, required this.child});

  final StageId stage;
  final Widget child;

  @override
  State<StageScope> createState() => _StageScopeState();
}

class _StageScopeState extends State<StageScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PlotcraftMotion.bleed,
  );
  GrisStage? _from;
  GrisStage? _to;

  GrisStage _target(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (dark ? GrisStages.dark : GrisStages.light)[widget.stage]!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final target = _target(context);
    if (_to == null) {
      _from = _to = target;
    } else if (_to != target) {
      _retarget(target);
    }
  }

  @override
  void didUpdateWidget(StageScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _target(context);
    if (_to != target) _retarget(target);
  }

  void _retarget(GrisStage target) {
    _from = _current;
    _to = target;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _from = target;
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  GrisStage get _current => GrisStage.lerp(
    _from!,
    _to!,
    PlotcraftMotion.curve.transform(_controller.value),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) =>
        _StageInherited(stage: _current, child: child!),
  );
}

class _StageInherited extends InheritedWidget {
  const _StageInherited({required this.stage, required super.child});

  final GrisStage stage;

  static GrisStage? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StageInherited>()?.stage;

  @override
  bool updateShouldNotify(_StageInherited oldWidget) =>
      oldWidget.stage != stage;
}
