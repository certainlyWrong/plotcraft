**English** · [Português](pt-BR/experience-and-preferences.md) · [Español](es/experience-and-preferences.md)

# Experience and preferences

## Desktop first

Plotcraft is essentially a desktop app. The main interface should prioritize comfortable navigation between projects and a workspace suited to long story-development sessions. The current technology is Flutter; specific platform requirements and window behavior still need to be defined.

## Window and density

The window opens at 1280x800 with a minimum size of 1000x680 (`lib/core/platform/window_service.dart`). For that reason the screens have no phone-width layouts. The interface is compact: 36 px buttons and fields with a line of ink under the text rather than a filled box, and soft corners (8 px on controls, 12 px on panels and 14 px on surfaces, defined in `PlotcraftRadii`). There are no ripples and no drop shadows; the look is described in [Visual language](visual-language.md). Text and icon colors over images and the colors of the current stage live in `PlotcraftTokens` (`lib/core/theme/plotcraft_tokens.dart`).

## Themes

The app offers selectable visual themes and saves the choice locally. Two themes are built in, **Gris Night** (the default) and **Gris Day**, both taking their palette from the website's watercolour journey (see [Visual language](visual-language.md)). The themes of earlier versions (Violet, Paper, Midnight and the rest) were retired; a choice saved with one of them is mapped to the nearest built-in theme, dark to Gris Night and light to Gris Day. You can also add JSON themes to `assets/themes/`; the app finds those files in the asset manifest and adds them to the theme list. A JSON theme gets the standard stage colors for its brightness.

Each theme file defines `id`, `name`, `brightness` (`light` or `dark`), `background`, `foreground` and `accent`. `surface`, `surfaceRaised`, `surfaceMuted`, `outline`, `outlineVariant`, `onSurfaceVariant` and `onAccent` are optional; when missing, the app derives consistent values from the main palette to stay compatible with existing themes. Colors use hexadecimal in the `#RRGGBB` format. A working example is in `assets/themes/ink-and-copper.json`. Because they are Flutter assets, new files enter the app when a new version is built.

## Languages

The interface uses `easy_localization` and loads JSON translations from `assets/translations/`. The files `en.json` and `pt.json` provide English (the default) and Portuguese. The app detects the available translation files and builds the language list from them; to add a language, put its JSON file in that directory, using the language code as the name. The language preference is saved by `easy_localization` itself.

- English — the default language.
- Portuguese.

The interface language does not determine the language in which people write their stories. Translation keys are organized by area (`home`, `project`, `preferences` and `sidebar`) so the texts can grow without concentrating translations in the interface.

## Interface font

The default font is **Times New Roman**. The person can pick another family in the preferences panel. The initial list includes DM Sans, Lora, Merriweather and Roboto, bundled with the app. Each family is declared in `pubspec.yaml` (the `fonts` section, files in `assets/fonts/`) and listed in `lib/core/theme/interface_fonts.dart`; switching uses local files only, with no network. The bundled weights are regular and medium; heavier weights use the closest one of the same family. The preference is saved locally and applied to every text style, including dialogs, tooltips, menus and fields, because `ThemeData` derives all of them from the same `TextTheme`.

## Projects folder

The app uses the `Plotcraft` folder inside the system documents directory for new projects. In Preferences, the person can choose another folder or restore the default location. The choice is persisted locally. Existing projects stay where they are; the library keeps their paths. See [Project model](project-model.md) for the structure of each folder.

On macOS, the choice uses a native panel that also records the authorization to access the folder in future sessions. The panel starts in the default folder when it exists; otherwise it opens in the nearest existing directory. Cancelling the choice keeps the current preference.
