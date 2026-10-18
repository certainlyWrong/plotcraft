class InterfaceFont {
  const InterfaceFont({required this.family, required this.provider});

  final String family;
  final InterfaceFontProvider provider;
}

enum InterfaceFontProvider { system, googleFonts }

const defaultInterfaceFont = 'Times New Roman';

/// Add Google Fonts families here to make them available in Preferences.
const interfaceFonts = <InterfaceFont>[
  InterfaceFont(
    family: defaultInterfaceFont,
    provider: InterfaceFontProvider.system,
  ),
  InterfaceFont(family: 'DM Sans', provider: InterfaceFontProvider.googleFonts),
  InterfaceFont(family: 'Lora', provider: InterfaceFontProvider.googleFonts),
  InterfaceFont(
    family: 'Merriweather',
    provider: InterfaceFontProvider.googleFonts,
  ),
  InterfaceFont(family: 'Roboto', provider: InterfaceFontProvider.googleFonts),
];
