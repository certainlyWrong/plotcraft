import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/theme/interface_fonts.dart';
import 'package:plotcraft/theme/theme_definition.dart';

void main() {
  for (final font in interfaceFonts) {
    test('${font.family}: todos os estilos do tema usam a fonte escolhida', () {
      for (final definition in builtInThemes.take(2)) {
        final theme = definition.toThemeData(fontFamily: font.family);
        final styles = <String, TextStyle?>{
          'bodyMedium': theme.textTheme.bodyMedium,
          'labelLarge': theme.textTheme.labelLarge,
          'titleLarge': theme.textTheme.titleLarge,
          'dialog.title': theme.dialogTheme.titleTextStyle,
          'dialog.content': theme.dialogTheme.contentTextStyle,
          'tooltip': theme.tooltipTheme.textStyle,
          'snackbar': theme.snackBarTheme.contentTextStyle,
          'popup': theme.popupMenuTheme.textStyle,
          'chip': theme.chipTheme.labelStyle,
          'input.hint': theme.inputDecorationTheme.hintStyle,
          'input.label': theme.inputDecorationTheme.labelStyle,
          'listTile.title': theme.listTileTheme.titleTextStyle,
          'button.filled': theme.filledButtonTheme.style?.textStyle?.resolve(
            {},
          ),
          'segmented': theme.segmentedButtonTheme.style?.textStyle?.resolve({}),
          'menu.item': theme.menuButtonTheme.style?.textStyle?.resolve({}),
          'button.text': theme.textButtonTheme.style?.textStyle?.resolve({}),
        };
        styles.forEach((name, style) {
          expect(style, isNotNull, reason: '$name sem estilo');
          expect(
            style!.fontFamily,
            font.family,
            reason: '$name não herdou a fonte ${font.family}',
          );
        });
      }
    });
  }
}
