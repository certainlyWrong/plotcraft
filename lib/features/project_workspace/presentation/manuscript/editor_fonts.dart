/// Fonts offered in the editor's font menu: display name -> font family.
/// These are the families bundled with the app (see `pubspec.yaml`) plus the
/// default interface font, so a chapter looks the same on every computer.
const bundledEditorFontFamilies = [
  'Lora',
  'Merriweather',
  'DM Sans',
  'Roboto',
  'Times New Roman',
];

/// The same fonts as a menu: display name -> font family.
final bundledEditorFonts = <String, String>{
  for (final family in bundledEditorFontFamilies) family: family,
};

/// Sizes offered in the editor's size menu: label -> value stored in the Delta.
const editorFontSizes = <String, String>{
  '10': '10',
  '12': '12',
  '14': '14',
  '16': '16',
  '18': '18',
  '20': '20',
  '24': '24',
  '28': '28',
  '36': '36',
  '48': '48',
};
