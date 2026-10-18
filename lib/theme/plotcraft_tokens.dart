import 'package:flutter/material.dart';

/// Colors for content drawn over images (covers, gallery, viewer). They do not
/// follow the app palette because the image underneath is what sets the
/// contrast, so they live in one place instead of being spread as literals.
@immutable
class PlotcraftTokens extends ThemeExtension<PlotcraftTokens> {
  const PlotcraftTokens({
    this.onImage = Colors.white,
    this.imageScrim = Colors.black,
    this.viewerBackdrop = const Color(0xFF080808),
  });

  /// Text and icons over images and cover art.
  final Color onImage;

  /// Base color for darkening overlays above images.
  final Color imageScrim;

  /// Background of the full-screen image viewer.
  final Color viewerBackdrop;

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
  }) => PlotcraftTokens(
    onImage: onImage ?? this.onImage,
    imageScrim: imageScrim ?? this.imageScrim,
    viewerBackdrop: viewerBackdrop ?? this.viewerBackdrop,
  );

  @override
  PlotcraftTokens lerp(ThemeExtension<PlotcraftTokens>? other, double t) {
    if (other is! PlotcraftTokens) return this;
    return PlotcraftTokens(
      onImage: Color.lerp(onImage, other.onImage, t)!,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
      viewerBackdrop: Color.lerp(viewerBackdrop, other.viewerBackdrop, t)!,
    );
  }
}

extension PlotcraftTokensContext on BuildContext {
  PlotcraftTokens get tokens =>
      Theme.of(this).extension<PlotcraftTokens>() ?? const PlotcraftTokens();
}
