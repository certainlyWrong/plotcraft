[English](../experience-and-preferences.md) · [Português](../pt-BR/experience-and-preferences.md) · **Español**

# Experiencia y preferencias

## Escritorio primero

Plotcraft es esencialmente una aplicación de escritorio. La interfaz principal debe priorizar una navegación cómoda entre proyectos y un espacio de trabajo adecuado para sesiones largas de desarrollo de historias. La tecnología actual es Flutter; los requisitos específicos de plataforma y el comportamiento de las ventanas aún están por definir.

## Ventana y densidad

La ventana se abre a 1280x800 y tiene un tamaño mínimo de 1000x680 (`lib/core/platform/window_service.dart`). Por eso las pantallas no tienen diseños con el ancho de un teléfono. La interfaz es compacta: botones y campos de 36 px, con una línea de tinta bajo el texto en lugar de una caja rellena, y esquinas suaves (8 px en los controles, 12 px en los paneles y 14 px en las superficies, definidos en `PlotcraftRadii`). No hay ondas al tocar ni sombras marcadas; el aspecto se describe en [Lenguaje visual](visual-language.md). Los colores de texto e iconos sobre imágenes y los de la etapa actual están en `PlotcraftTokens` (`lib/core/theme/plotcraft_tokens.dart`).

## Temas

La aplicación ofrece temas visuales seleccionables y guarda la elección en local. Hay dos temas integrados, **Gris Night** (el predeterminado) y **Gris Day**, que toman la paleta del recorrido de acuarela del sitio web (véase [Lenguaje visual](visual-language.md)). Los temas de versiones anteriores (Violet, Paper, Midnight y los demás) se retiraron; una elección guardada con uno de ellos pasa al tema integrado más cercano: el oscuro a Gris Night y el claro a Gris Day. También se pueden añadir temas JSON en `assets/themes/`; la aplicación encuentra esos archivos en el manifiesto de assets y los añade a la lista de temas. Un tema JSON recibe los colores de etapa estándar para su brillo.

Cada archivo de tema define `id`, `name`, `brightness` (`light` o `dark`), `background`, `foreground` y `accent`. `surface`, `surfaceRaised`, `surfaceMuted`, `outline`, `outlineVariant`, `onSurfaceVariant` y `onAccent` son opcionales; si faltan, la aplicación deriva valores coherentes a partir de la paleta principal para mantener la compatibilidad con los temas existentes. Los colores usan hexadecimal en el formato `#RRGGBB`. Hay un ejemplo funcional en `assets/themes/ink-and-copper.json`. Como son assets de Flutter, los archivos nuevos entran en la aplicación al compilar una versión nueva.

## Idiomas

La interfaz usa `easy_localization` y carga traducciones JSON desde `assets/translations/`. Los archivos `en.json` y `pt.json` ofrecen inglés (el predeterminado) y portugués. La aplicación detecta los archivos de traducción disponibles y construye la lista de idiomas a partir de ellos; para añadir un idioma, incluya su archivo JSON en ese directorio usando el código del idioma como nombre. La preferencia de idioma la guarda el propio `easy_localization`.

- Inglés — el idioma predeterminado.
- Portugués.

El idioma de la interfaz no determina el idioma en que la persona escribe sus historias. Las claves de traducción están organizadas por área (`home`, `project`, `preferences` y `sidebar`) para que los textos puedan crecer sin concentrar las traducciones en la interfaz.

## Fuente de la interfaz

La fuente predeterminada es **Times New Roman**. La persona puede elegir otra familia en el panel de preferencias. La lista inicial incluye DM Sans, Lora, Merriweather y Roboto, empaquetadas con la aplicación. Cada familia se declara en `pubspec.yaml` (sección `fonts`, archivos en `assets/fonts/`) y se lista en `lib/core/theme/interface_fonts.dart`; el cambio usa solo archivos locales, sin red. Los pesos empaquetados son regular y medio; los pesos mayores usan el más cercano de la misma familia. La preferencia se guarda en local y se aplica a todos los estilos de texto, incluidos diálogos, sugerencias, menús y campos, porque `ThemeData` los deriva todos del mismo `TextTheme`.

## Carpeta de proyectos

La aplicación usa la carpeta `Plotcraft` dentro del directorio de documentos del sistema para los proyectos nuevos. En Preferencias, la persona puede elegir otra carpeta o restaurar la ubicación predeterminada. La elección se guarda en local. Los proyectos existentes permanecen donde están; la biblioteca conserva sus rutas. Consulte [Modelo de proyecto](project-model.md) para ver la estructura de cada carpeta.

En macOS, la elección usa un panel nativo que además registra la autorización para acceder a la carpeta en sesiones futuras. El panel empieza en la carpeta predeterminada cuando existe; si no, se abre en el directorio existente más cercano. Cancelar la elección mantiene la preferencia actual.
