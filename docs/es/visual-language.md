[English](../visual-language.md) · [Português](../pt-BR/visual-language.md) · **Español**

# Lenguaje visual

La interfaz de Plotcraft se inspira en el arte del juego [Gris](https://es.wikipedia.org/wiki/Gris_(videojuego)) (Nomada Studio, arte de Conrad Roset): acuarela y tinta china, un mundo que empieza sin color y lo va ganando. El sitio web usa el mismo lenguaje (`website/`), y esta página describe cómo vive en la aplicación.

## Principios

1. **El color es progreso.** La ventana empieza gris y toma color según el contexto: lo que estás haciendo decide el color, no un acento fijo.
2. **Acuarela debajo, tinta encima.** Manchas suaves de pigmento se difuminan detrás del contenido; líneas finas de tinta (anillos, arcos, estrellas, trazos bajo los títulos) van por encima.
3. **Silencio.** Hojas de papel en lugar de tarjetas con caja, sin contornos duros, sin sombras marcadas, sin ondas al tocar. La jerarquía viene del espacio y la tipografía.
4. **Lentitud.** Una sola curva (`PlotcraftMotion.curve`), transiciones de 0,2 a 1,6 s, movimiento ambiente en decenas de segundos. Nada corta.
5. **Serif para la voz, sans para la función.** Títulos y citas van en Lora; los controles y el texto usan la fuente de interfaz elegida por la persona.

## Las etapas

Cada etapa tiene un *pigmento* (áreas: acuarelas, muestras, gotas) y una *tinta* (líneas, iconos, texto de énfasis, el botón primario). En los temas oscuros la tinta es más clara que el pigmento; en los claros, más oscura, para mantener el contraste. Los valores están en `GrisStages` (`lib/core/theme/plotcraft_tokens.dart`) y coinciden con `website/src/style.css`.

| Etapa | Dónde se aplica |
| --- | --- |
| Gris | Biblioteca, preferencias, resumen del proyecto |
| Rojo | Escritura (manuscrito, capítulos) y creación de proyecto |
| Verde | Elementos de la historia |
| Azul | Mapa de la historia y línea de tiempo |
| Amarillo | Modo lectura y galería |

Una pantalla declara su lugar con `StageScope(stage: ...)`; `context.tokens.ink` y `context.tokens.pigment` lo siguen, y el color se difumina de una etapa a la siguiente en `PlotcraftMotion.bleed` (1,6 s). En el workspace, `stageForTab` (`shell/workspace_stage.dart`) lleva la pestaña activa a su etapa.

## Piezas

- **Tema** — `ThemeDefinition` (`lib/core/theme/theme_definition.dart`). Dos temas integrados, *Gris Night* (predeterminado) y *Gris Day*; los temas JSON de `assets/themes/` se siguen cargando y reciben las etapas estándar. Los ids guardados de los temas antiguos se llevan al más cercano (`migrateThemeId`). El `ColorScheme` completo se escribe a mano y los temas de los componentes no tienen ondas ni capas de estado.
- **Tokens** — `PlotcraftTokens` (`context.tokens`): pigmento y tinta de la etapa, intensidad de la acuarela y del grano, color del papel. `PlotcraftRadii` son 8 / 12 / 14. `PlotcraftMotion` guarda la curva y las duraciones.
- **Efectos** — `lib/core/ui/gris/`: `WatercolorWash` y `PaperGrain` (fragment shaders en `shaders/`, con un painter sencillo de respaldo), `GrisBackdrop`, `CoverWash`, `OrbitRings`, `Constellation`, `ArchBridge`, `InkStroke`, `PigmentDrop`, `Reveal`, `MorphBadge`, `BrandMark` y `GrisClock`.
- **Componentes** — `lib/core/ui/`: `PlotcraftButton`, `PlotcraftChip`, `PlotcraftChoice`, `PlotcraftSegmented`, `PlotcraftSurface` / `PlotcraftCard`, `PlotcraftDialog`, `PlotcraftTextField` (una línea de tinta bajo el texto), `PlotcraftTabBar`, `PlotcraftNavIcon`, `PlotcraftSection` / `PlotcraftPageTitle` y `PlotcraftToaster`.

## Accesibilidad y rendimiento

- **Contraste.** `test/gris/contrast_test.dart` comprueba el WCAG AA (4,5:1) para texto, tinta, botón primario y manchas de selección, en todas las etapas y en ambos temas, incluido el peor caso de texto sobre el pigmento más denso de la acuarela. Ese caso fija la intensidad máxima de la acuarela (`washOpacity`: 20 % en oscuro, 24 % en claro).
- **Movimiento reducido.** Con el ajuste del sistema activado, no corre ningún reloj ambiente y las revelaciones y los trazos aparecen terminados.
- **Tranquilo por defecto.** `GrisClock` late a 20–30 fps, se detiene mientras la ventana no está al frente y mientras su widget está oculto (sigue el `TickerMode`, así que las pestañas cerradas no animan). Detrás del workspace la acuarela corre a 8 fps. Las tarjetas de la biblioteca solo animan la insignia bajo el puntero.
- **Los shaders pueden fallar.** Si un programa de fragmento no carga, la acuarela recurre a degradados radiales y se omite el grano. `test/gris/gris_shaders_test.dart` es el único lugar donde aparecería un error de GLSL.
- **Pruebas.** Lo que anima para siempre debe quedarse quieto antes de `pumpAndSettle`: envuelve la app en `MediaQuery(disableAnimations: true)`.

## Ampliarlo

- *Una pantalla nueva:* envuélvela en `StageScope` y usa `context.tokens` para los acentos; evita `colorScheme.primary` para dar énfasis, que es un gris neutro.
- *Un nuevo mapeo de etapa:* añádelo a `stageForSection` y a su prueba.
- *Un nuevo efecto:* ponlo en `lib/core/ui/gris/`, conduce el movimiento ambiente con `GrisClock` y respeta `grisStill(context)`.
