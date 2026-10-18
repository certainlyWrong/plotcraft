// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ThemeStore on _ThemeStore, Store {
  Computed<ThemeDefinition>? _$selectedThemeComputed;

  @override
  ThemeDefinition get selectedTheme =>
      (_$selectedThemeComputed ??= Computed<ThemeDefinition>(
        () => super.selectedTheme,
        name: '_ThemeStore.selectedTheme',
      )).value;

  late final _$themesAtom = Atom(name: '_ThemeStore.themes', context: context);

  @override
  ObservableList<ThemeDefinition> get themes {
    _$themesAtom.reportRead();
    return super.themes;
  }

  @override
  set themes(ObservableList<ThemeDefinition> value) {
    _$themesAtom.reportWrite(value, super.themes, () {
      super.themes = value;
    });
  }

  late final _$selectedThemeIdAtom = Atom(
    name: '_ThemeStore.selectedThemeId',
    context: context,
  );

  @override
  String get selectedThemeId {
    _$selectedThemeIdAtom.reportRead();
    return super.selectedThemeId;
  }

  @override
  set selectedThemeId(String value) {
    _$selectedThemeIdAtom.reportWrite(value, super.selectedThemeId, () {
      super.selectedThemeId = value;
    });
  }

  late final _$fontFamilyAtom = Atom(
    name: '_ThemeStore.fontFamily',
    context: context,
  );

  @override
  String get fontFamily {
    _$fontFamilyAtom.reportRead();
    return super.fontFamily;
  }

  @override
  set fontFamily(String value) {
    _$fontFamilyAtom.reportWrite(value, super.fontFamily, () {
      super.fontFamily = value;
    });
  }

  late final _$isLoadingFontAtom = Atom(
    name: '_ThemeStore.isLoadingFont',
    context: context,
  );

  @override
  bool get isLoadingFont {
    _$isLoadingFontAtom.reportRead();
    return super.isLoadingFont;
  }

  @override
  set isLoadingFont(bool value) {
    _$isLoadingFontAtom.reportWrite(value, super.isLoadingFont, () {
      super.isLoadingFont = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    '_ThemeStore.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$selectAsyncAction = AsyncAction(
    '_ThemeStore.select',
    context: context,
  );

  @override
  Future<void> select(String id) {
    return _$selectAsyncAction.run(() => super.select(id));
  }

  late final _$selectFontAsyncAction = AsyncAction(
    '_ThemeStore.selectFont',
    context: context,
  );

  @override
  Future<bool> selectFont(String family) {
    return _$selectFontAsyncAction.run(() => super.selectFont(family));
  }

  @override
  String toString() {
    return '''
themes: ${themes},
selectedThemeId: ${selectedThemeId},
fontFamily: ${fontFamily},
isLoadingFont: ${isLoadingFont},
selectedTheme: ${selectedTheme}
    ''';
  }
}
