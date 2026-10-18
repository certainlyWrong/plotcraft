import 'package:flutter/material.dart';
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
    final generated = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
    final panel = surface ?? _blend(background, generated.surface, .28);
    final raisedPanel =
        surfaceRaised ?? _blend(panel, foreground, isDark ? .08 : .035);
    final mutedPanel =
        surfaceMuted ?? _blend(background, foreground, isDark ? .06 : .035);
    final border = outline ?? generated.outline;
    final subtleBorder =
        outlineVariant ?? _blend(background, foreground, isDark ? .22 : .16);
    final mutedForeground =
        onSurfaceVariant ?? _blend(foreground, background, isDark ? .3 : .38);
    final scheme = generated.copyWith(
      primary: accent,
      onPrimary: onAccent ?? _contrastColor(accent),
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
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      focusColor: accent.withValues(alpha: .12),
      hoverColor: accent.withValues(alpha: .06),
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
          borderRadius: BorderRadius.circular(14),
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
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: subtleBorder),
        ),
        titleTextStyle: text.titleLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: mutedForeground,
          height: 1.4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: .12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: .38),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedPanel,
        isDense: true,
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyLarge?.copyWith(color: scheme.primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        border: _fieldBorder(subtleBorder),
        enabledBorder: _fieldBorder(subtleBorder),
        focusedBorder: _fieldBorder(scheme.primary, width: 1.6),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.6),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
          minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: .08),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
        backgroundColor: mutedPanel,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
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

const builtInThemes = <ThemeDefinition>[
  ThemeDefinition(
    id: 'violet',
    name: 'Violet',
    background: Color(0xFFF4F0FA),
    surface: Color(0xFFFCFAFF),
    foreground: Color(0xFF302A3D),
    accent: Color(0xFF7654A6),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'violet-dark',
    name: 'Violet Dark',
    background: Color(0xFF211A2C),
    surface: Color(0xFF2C243A),
    foreground: Color(0xFFF3ECFC),
    accent: Color(0xFFC1A2E3),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'paper',
    name: 'Paper',
    background: Color(0xFFF5F2EC),
    foreground: Color(0xFF293B38),
    accent: Color(0xFF56756C),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'paper-dark',
    name: 'Paper Dark',
    background: Color(0xFF26231E),
    surface: Color(0xFF322E28),
    foreground: Color(0xFFF2EDE3),
    accent: Color(0xFFD6B887),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'midnight',
    name: 'Midnight',
    background: Color(0xFF202526),
    foreground: Color(0xFFE9ECE8),
    accent: Color(0xFF93B5A6),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'midnight-light',
    name: 'Midnight Light',
    background: Color(0xFFEDF1F1),
    surface: Color(0xFFFAFCFC),
    foreground: Color(0xFF273233),
    accent: Color(0xFF46696A),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'lavender',
    name: 'Lavender',
    background: Color(0xFFF3EFF7),
    foreground: Color(0xFF453A54),
    accent: Color(0xFF89749F),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'lavender-dark',
    name: 'Lavender Dark',
    background: Color(0xFF25212E),
    surface: Color(0xFF302A3B),
    foreground: Color(0xFFF0EAF7),
    accent: Color(0xFFC2A8E0),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'moss',
    name: 'Moss',
    background: Color(0xFFF0F2E9),
    foreground: Color(0xFF354234),
    accent: Color(0xFF74845D),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'moss-dark',
    name: 'Moss Dark',
    background: Color(0xFF20261E),
    surface: Color(0xFF2A3227),
    foreground: Color(0xFFEEF2E8),
    accent: Color(0xFFA8BB8B),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'rose',
    name: 'Rose',
    background: Color(0xFFFAF0F2),
    surface: Color(0xFFFFFAFB),
    foreground: Color(0xFF422C34),
    accent: Color(0xFFAD526F),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'rose-dark',
    name: 'Rose Dark',
    background: Color(0xFF302128),
    surface: Color(0xFF3B2932),
    foreground: Color(0xFFF8ECF0),
    accent: Color(0xFFE49AB0),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'ocean',
    name: 'Ocean',
    background: Color(0xFFEEF4F8),
    surface: Color(0xFFF9FCFE),
    foreground: Color(0xFF263744),
    accent: Color(0xFF397596),
    isDark: false,
  ),
  ThemeDefinition(
    id: 'ocean-dark',
    name: 'Ocean Dark',
    background: Color(0xFF1D2830),
    surface: Color(0xFF273641),
    foreground: Color(0xFFEBF2F6),
    accent: Color(0xFF8CC2DE),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'plum-night',
    name: 'Plum Night',
    background: Color(0xFF211D29),
    surface: Color(0xFF2C2636),
    foreground: Color(0xFFF0EAF5),
    accent: Color(0xFFC5A4E8),
    isDark: true,
  ),
  ThemeDefinition(
    id: 'plum-day',
    name: 'Plum Day',
    background: Color(0xFFF2EFF5),
    surface: Color(0xFFFCFAFE),
    foreground: Color(0xFF352D3E),
    accent: Color(0xFF8762AA),
    isDark: false,
  ),
];
