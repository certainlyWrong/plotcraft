class InterfaceFont {
  const InterfaceFont({required this.family, this.isSystem = false});

  final String family;

  /// System fonts are not bundled; the operating system provides them.
  final bool isSystem;
}

const defaultInterfaceFont = 'Times New Roman';

/// Bundled families are declared under `flutter: fonts:` in `pubspec.yaml`
/// (files in `assets/fonts/`). Add the family there and here to make it
/// available in Preferences.
const interfaceFonts = <InterfaceFont>[
  InterfaceFont(family: defaultInterfaceFont, isSystem: true),
  InterfaceFont(family: 'DM Sans'),
  InterfaceFont(family: 'Lora'),
  InterfaceFont(family: 'Merriweather'),
  InterfaceFont(family: 'Roboto'),
];
