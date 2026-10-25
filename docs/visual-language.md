**English** · [Português](pt-BR/visual-language.md) · [Español](es/visual-language.md)

# Visual language

Plotcraft's interface is inspired by the art of the game [Gris](https://en.wikipedia.org/wiki/Gris) (Nomada Studio, art by Conrad Roset): watercolour and Indian ink, a world that starts without colour and gains it as you go. The website uses the same language (`website/`), and this page describes how it lives in the app.

## Principles

1. **Colour is progress.** The window starts grey and takes on colour by context: what you are doing decides the colour, not a fixed accent.
2. **Watercolour under, ink above.** Soft pools of pigment bleed behind the content; thin ink lines (rings, arches, stars, strokes under titles) sit on top.
3. **Quiet.** Sheets of paper instead of boxed cards, no hard outlines, no drop shadows, no ripples. Hierarchy comes from space and type.
4. **Slow.** One easing (`PlotcraftMotion.curve`), transitions of 0.2–1.6 s, ambient motion in tens of seconds. Nothing cuts.
5. **Serif for voice, sans for function.** Titles and quotes are Lora; controls and body text use the interface font the person chose.

## The stages

Each stage has a *pigment* (areas: washes, swatches, drops) and an *ink* (lines, icons, accent text, the primary button). On dark themes the ink is lighter than the pigment, on light themes darker, so it always keeps contrast. The values live in `GrisStages` (`lib/core/theme/plotcraft_tokens.dart`) and match `website/src/style.css`.

| Stage | Where it applies |
| --- | --- |
| Grey | Library, preferences, project overview |
| Red | Writing (manuscript, chapters) and creating a project |
| Green | Story elements |
| Blue | Story map and timeline |
| Yellow | Reading mode and the gallery |

A screen declares its place with `StageScope(stage: ...)`; `context.tokens.ink` and `context.tokens.pigment` then follow it, and colour bleeds from one stage to the next over `PlotcraftMotion.bleed` (1.6 s). In the workspace, `stageForTab` (`shell/workspace_stage.dart`) maps the active tab to its stage.

## Building blocks

- **Theme** — `ThemeDefinition` (`lib/core/theme/theme_definition.dart`). Two built-in themes, *Gris Night* (default) and *Gris Day*; JSON themes in `assets/themes/` still load and receive the standard stages. Saved ids from the old themes are mapped to the nearest one (`migrateThemeId`). The whole `ColorScheme` is written by hand, and component themes drop ripples and state layers.
- **Tokens** — `PlotcraftTokens` (`context.tokens`): stage pigment and ink, wash and grain strength, paper colour. `PlotcraftRadii` are 8 / 12 / 14. `PlotcraftMotion` holds the curve and durations.
- **Effects** — `lib/core/ui/gris/`: `WatercolorWash` and `PaperGrain` (fragment shaders in `shaders/`, with a plain-painter fallback), `GrisBackdrop`, `CoverWash`, `OrbitRings`, `Constellation`, `ArchBridge`, `InkStroke`, `PigmentDrop`, `Reveal`, `MorphBadge`, `BrandMark` and `GrisClock`.
- **Components** — `lib/core/ui/`: `PlotcraftButton`, `PlotcraftChip`, `PlotcraftChoice`, `PlotcraftSegmented`, `PlotcraftSurface` / `PlotcraftCard`, `PlotcraftDialog`, `PlotcraftTextField` (an ink line under the text), `PlotcraftTabBar`, `PlotcraftNavIcon`, `PlotcraftSection` / `PlotcraftPageTitle` and `PlotcraftToaster`.

## Accessibility and performance

- **Contrast.** `test/gris/contrast_test.dart` checks WCAG AA (4.5:1) for text, ink, the primary button and selected patches, on every stage and both themes, including the worst case of text over the thickest pigment of the wash. That case sets how strong the wash may be (`washOpacity`: 20% dark, 24% light).
- **Reduced motion.** With the system setting on, no ambient clock runs and reveals and drawings appear finished.
- **Calm by default.** `GrisClock` ticks at 20–30 fps, stops while the window is not in front and while its widget is hidden (it follows `TickerMode`, so closed tabs do not animate). Behind the workspace the wash runs at 8 fps. Library cards animate their badge only under the pointer.
- **Shaders can fail.** If a fragment program does not load, the wash falls back to radial gradients and the grain is omitted. `test/gris/gris_shaders_test.dart` is the only place a GLSL mistake would show.
- **Tests.** Anything that animates forever must be told to stand still before `pumpAndSettle`: wrap the app in `MediaQuery(disableAnimations: true)`.

## Extending it

- *A new screen:* wrap it in `StageScope` and use `context.tokens` for accents; avoid `colorScheme.primary` for emphasis, which is a neutral grey.
- *A new stage mapping:* add it to `stageForSection` and its test.
- *A new effect:* put it in `lib/core/ui/gris/`, drive any ambient motion with `GrisClock`, and honour `grisStill(context)`.
