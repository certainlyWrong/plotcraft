import 'package:flutter/material.dart';

import 'plotcraft_tokens.dart';

class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
    required this.foreground,
    required this.isDark,
    this.surface,
    this.surfaceRaised,
    this.surfaceMuted,
    this.outline,
    this.outlineVariant,
    this.onSurfaceVariant,
    this.onAccent,
  });

  final String id;
  final String name;
  final Color background;
  final Color accent;
  final Color foreground;
  final bool isDark;
  final Color? surface;
  final Color? surfaceRaised;
  final Color? surfaceMuted;
  final Color? outline;
  final Color? outlineVariant;
  final Color? onSurfaceVariant;
  final Color? onAccent;

  ThemeData toThemeData({required String fontFamily}) {
    final panel = surface ?? _blend(background, foreground, isDark ? .05 : .02);
    final raisedPanel =
        surfaceRaised ?? _blend(panel, foreground, isDark ? .08 : .035);
    final mutedPanel =
        surfaceMuted ?? _blend(background, foreground, isDark ? .06 : .035);
    final border = outline ?? _blend(background, foreground, isDark ? .4 : .34);
    final subtleBorder =
        outlineVariant ?? _blend(background, foreground, isDark ? .16 : .13);
    final mutedForeground =
        onSurfaceVariant ?? _blend(foreground, background, isDark ? .3 : .38);
    final stages = isDark ? GrisStages.dark : GrisStages.light;
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: onAccent ?? _contrastColor(accent),
      primaryContainer: _blend(raisedPanel, accent, .16),
      onPrimaryContainer: foreground,
      secondary: mutedForeground,
      onSecondary: background,
      secondaryContainer: _blend(raisedPanel, accent, .18),
      onSecondaryContainer: foreground,
      tertiary: _blend(accent, foreground, .35),
      onTertiary: _contrastColor(_blend(accent, foreground, .35)),
      error: stages[StageId.red]!.ink,
      onError: _contrastColor(stages[StageId.red]!.ink),
      surface: panel,
      onSurface: foreground,
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: subtleBorder,
      surfaceContainerLowest: background,
      surfaceContainerLow: mutedPanel,
      surfaceContainer: panel,
      surfaceContainerHigh: raisedPanel,
      surfaceContainerHighest: _blend(raisedPanel, foreground, .04),
      inverseSurface: foreground,
      onInverseSurface: background,
      surfaceTint: Colors.transparent,
      scrim: _blend(foreground, const Color(0xFF000000), isDark ? .85 : .6),
      shadow: _blend(foreground, const Color(0xFF000000), isDark ? .9 : .7),
    );
    // The base theme is built first so every component theme below derives
    // its text style from the same font-aware text theme.
    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: fontFamily,
      colorScheme: scheme,
    );
    final text = base.textTheme;
    return base.copyWith(
      extensions: [
        PlotcraftTokens(
          stage: stages[StageId.grey]!,
          // Weak enough that text keeps AA contrast even where the pigment
          // lies thickest (test/gris/contrast_test.dart).
          washOpacity: isDark ? .2 : .24,
          paper: panel,
          isDark: isDark,
        ),
      ],
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.compact,
      splashFactory: NoSplash.splashFactory,
      focusColor: accent.withValues(alpha: .10),
      hoverColor: accent.withValues(alpha: .07),
      highlightColor: accent.withValues(alpha: .08),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: .3),
        selectionHandleColor: accent,
      ),
      cardTheme: CardThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
          side: BorderSide(color: subtleBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: subtleBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
          side: BorderSide(color: subtleBorder),
        ),
        titleTextStyle: text.headlineSmall?.copyWith(
          color: foreground,
          fontFamily: PlotcraftFonts.serif,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.15,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: mutedForeground,
          height: 1.4,
        ),
      ),
      // Buttons have no state layer or ripple: hover is a faint wash of the
      // accent, focus a line of ink, and the primary button blooms a drop of
      // pigment (see PlotcraftButton). Labels are medium, never bold.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: .12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
          overlayColor: Colors.transparent,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          ),
          textStyle: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: .2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => _hovered(states)
                ? scheme.primary.withValues(alpha: .08)
                : Colors.transparent,
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? scheme.primary
                  : _hovered(states)
                  ? scheme.outline
                  : scheme.outlineVariant,
              width: states.contains(WidgetState.focused) ? 1.6 : 1,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlotcraftRadii.control),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            text.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => _hovered(states)
                ? scheme.primary.withValues(alpha: .09)
                : Colors.transparent,
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlotcraftRadii.control),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            text.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: .2,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyLarge?.copyWith(color: scheme.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        border: _fieldBorder(subtleBorder),
        enabledBorder: _fieldBorder(subtleBorder),
        focusedBorder: _fieldBorder(scheme.primary, width: 1.6),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.6),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .38)
                : _hovered(states)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlotcraftRadii.control),
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => _hovered(states)
                ? scheme.primary.withValues(alpha: .08)
                : Colors.transparent,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: scheme.shadow.withValues(alpha: .35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        textStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: mutedForeground),
        labelType: NavigationRailLabelType.none,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withValues(alpha: .08),
        selectedColor: scheme.primary.withValues(alpha: .2),
        secondarySelectedColor: scheme.primary.withValues(alpha: .2),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
        waitDuration: const Duration(milliseconds: 500),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          foreground.withValues(alpha: isDark ? .3 : .22),
        ),
      ),
      // Small controls: a hairline track and a small round thumb, a leaf-shaped
      // check, and progress as a thin line. No tonal fills, no state layers.
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: subtleBorder,
        thumbColor: scheme.primary,
        overlayColor: Colors.transparent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackShape: const RectangularSliderTrackShape(),
        showValueIndicator: ShowValueIndicator.never,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineWidth: const WidgetStatePropertyAll(1),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : border,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: .22)
              : Colors.transparent,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : mutedForeground,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: border, width: 1.2),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: subtleBorder,
        linearMinHeight: 2,
        circularTrackColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
          side: BorderSide(color: subtleBorder),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : Colors.transparent,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: subtleBorder)),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: subtleBorder),
            ),
          ),
        ),
      ),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(background),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.bodyMedium),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static bool _hovered(Set<WidgetState> states) =>
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused);

  /// Fields are a line of ink under the text, not a box.
  static UnderlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );

  static Color _blend(Color first, Color second, double amount) =>
      Color.lerp(first, second, amount)!;

  static Color _contrastColor(Color color) =>
      color.computeLuminance() > .38 ? const Color(0xFF201B27) : Colors.white;

  factory ThemeDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final brightness = json['brightness'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        brightness is! String ||
        !const {'light', 'dark'}.contains(brightness)) {
      throw const FormatException('Theme requires id, name and brightness.');
    }
    return ThemeDefinition(
      id: id,
      name: name,
      background: _parseColor(json['background'] as String),
      accent: _parseColor(json['accent'] as String),
      foreground: _parseColor(json['foreground'] as String? ?? '#293B38'),
      surface: _optionalColor(json, 'surface'),
      surfaceRaised: _optionalColor(json, 'surfaceRaised'),
      surfaceMuted: _optionalColor(json, 'surfaceMuted'),
      outline: _optionalColor(json, 'outline'),
      outlineVariant: _optionalColor(json, 'outlineVariant'),
      onSurfaceVariant: _optionalColor(json, 'onSurfaceVariant'),
      onAccent: _optionalColor(json, 'onAccent'),
      isDark: brightness == 'dark',
    );
  }

  static Color? _optionalColor(Map<String, dynamic> json, String key) =>
      json[key] == null ? null : _parseColor(json[key] as String);

  static Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6) {
      throw FormatException('Expected a six-digit hex color: $value');
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Previous theme ids and the Gris theme that replaces each, so a saved
/// preference never points at a theme that no longer exists.
String migrateThemeId(String id) {
  if (builtInThemes.any((theme) => theme.id == id)) return id;
  const darkIds = {
    'violet-dark',
    'paper-dark',
    'midnight',
    'lavender-dark',
    'moss-dark',
    'rose-dark',
    'ocean-dark',
    'plum-night',
  };
  return darkIds.contains(id) ? 'gris-night' : 'gris-day';
}

const builtInThemes = <ThemeDefinition>[
  ThemeDefinition(
    id: 'gris-night',
    name: 'Gris Night',
    background: Color(0xFF202526),
    surface: Color(0xFF2A3031),
    surfaceRaised: Color(0xFF323A3B),
    foreground: Color(0xFFE9ECE8),
    onSurfaceVariant: Color(0xFFA8B3AE),
    accent: Color(0xFFB9C0BF),
    onAccent: Color(0xFF17201D),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'gris-day',
    name: 'Gris Day',
    background: Color(0xFFEDF1F1),
    surface: Color(0xFFFAFCFC),
    surfaceRaised: Color(0xFFFFFFFF),
    foreground: Color(0xFF273233),
    onSurfaceVariant: Color(0xFF4A595A),
    accent: Color(0xFF4F5A5B),
    onAccent: Color(0xFFFFFFFF),
    isDark: false,
  ),
];
