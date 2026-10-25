import type en from './en'

const es: typeof en = {
  meta: {
    title: 'Plotcraft — planifica tus historias',
    description:
      'Plotcraft es una aplicación de escritorio para planificar historias antes y mientras las escribes: elementos, relaciones, mapa de la historia, línea de tiempo y modo lectura, en archivos locales que son tuyos.',
  },
  nav: {
    demo: 'Pruébalo',
    features: 'Funciones',
    showcase: 'Recorrido',
    sample: 'Historia de ejemplo',
    download: 'Descarga',
    mcp: 'IA',
    github: 'GitHub',
    language: 'Idioma',
    theme: 'Cambiar tema',
  },
  hero: {
    tryDemo: 'Pruébalo en el navegador',
    eyebrow: 'Una aplicación de escritorio para quien cuenta historias',
    title: 'Planifica tus historias antes y mientras las escribes.',
    subtitle:
      'Personajes, lugares, relaciones y capítulos en un mismo sitio, en archivos locales que son tuyos.',
    download: 'Descargar para {platform}',
    allDownloads: 'Todas las descargas',
    seeFeatures: 'Mira lo que hace',
    version: 'Versión {version}',
    early: 'Fase temprana: ya funciona y sigue creciendo.',
    imageAlt: 'Plotcraft mostrando la ficha de un personaje junto a la lista de elementos de la historia',
  },
  platforms: { macos: 'macOS', windows: 'Windows', linux: 'Linux' },
  features: {
    title: 'Todo lo que la historia necesita, junto al texto',
    intro: 'Lo que escribes y lo que planificas permanecen conectados, para cualquier género y formato.',
    items: {
      elements: {
        title: 'Elementos de la historia',
        text: 'Personajes, lugares, objetos, criaturas, organizaciones, eventos, conceptos y notas, además de tipos propios con los detalles que tu historia pide.',
      },
      phases: {
        title: 'Fases y relaciones',
        text: 'Muestra cómo cambia un elemento capítulo a capítulo y vincula elementos con etiquetas que se leen en los dos sentidos.',
      },
      map: {
        title: 'Mapa de la historia',
        text: 'Un grafo interactivo de elementos, relaciones, capítulos y de dónde se cita cada elemento.',
      },
      timeline: {
        title: 'Línea de tiempo',
        text: 'Quién aparece dónde, por capítulo, y la cronología del propio mundo con fechas libres.',
      },
      writing: {
        title: 'Escritura en texto enriquecido',
        text: 'Fuentes, colores, títulos, imágenes, búsqueda y reemplazo, guardado automático y menciones que vinculan nombres con elementos.',
      },
      reading: {
        title: 'Modo lectura',
        text: 'El libro como lo vería un lector: un capítulo cada vez, texto ajustable y nombres que abren su elemento.',
      },
      gallery: {
        title: 'Galería',
        text: 'Referencias visuales en un mosaico que respeta la proporción real de cada imagen, ligadas a elementos y fases.',
      },
      files: {
        title: 'Archivos locales',
        text: 'Cada proyecto es una carpeta de Markdown, JSON e imágenes. Cópiala, haz copias de seguridad, versiónala. Nada queda atrapado.',
      },
      ai: {
        title: 'Funciona con IA',
        text: 'Un servidor MCP integrado permite que Claude y otros clientes creen y editen los mismos proyectos, con seguridad.',
      },
    },
  },
  showcase: {
    title: 'Un recorrido rápido',
    intro: 'Todas las pantallas de abajo salen de la historia de ejemplo que acompaña a la aplicación.',
    tabs: {
      map: {
        label: 'Mapa',
        title: 'Mira cómo se conecta todo',
        text: 'Elementos, relaciones, capítulos y dónde se cita cada elemento, con filtros por tipo, búsqueda, zoom y foco en un elemento y sus conexiones.',
      },
      timeline: {
        label: 'Línea de tiempo',
        title: 'Quién aparece dónde',
        text: 'Una matriz por capítulo con las fases que empiezan allí, y la cronología del mundo en orden o a escala, con fechas escritas como las cuenta tu historia.',
      },
      reading: {
        label: 'Lectura',
        title: 'Lee como un lector',
        text: 'Un capítulo cada vez en una columna cómoda, con el progreso de todo el libro. Los nombres abren su elemento con un clic.',
      },
      editor: {
        label: 'Escritura',
        title: 'Escribe con tu mundo a mano',
        text: 'Un editor de texto enriquecido con menciones: pasa el ratón sobre un nombre para ver la tarjeta del elemento y la fase en que está en ese capítulo.',
      },
      gallery: {
        label: 'Galería',
        title: 'Referencias, tal como son',
        text: 'Cada imagen conserva su proporción, en vertical o en horizontal, y se puede usar como portada, en una fase o en el texto.',
      },
      theme: {
        label: 'Temas',
        title: 'Hazlo tuyo',
        text: 'Ocho temas con variantes clara y oscura, temas JSON propios, fuentes de interfaz y fuentes que viajan con el proyecto.',
      },
    },
  },
  sample: {
    title: 'Pruébalo con una historia completa',
    text: 'Plotcraft incluye Herdeiros do Silêncio (en portugués) para que lo explores sin empezar de cero. En la pantalla de inicio, elige «Explorar la historia de ejemplo»: se copia a tu carpeta de proyectos y se abre como cualquier otro proyecto.',
    story:
      'Siete Voces sostienen el universo, cada una con un único portador, transmitidas en herencia a cambio de un precio.',
    stats: { chapters: 'capítulos', elements: 'elementos enlazados', plots: 'tramas', images: 'imágenes' },
    imageAlt: 'La biblioteca de Plotcraft con la historia de ejemplo',
  },
  download: {
    title: 'Descarga Plotcraft',
    intro: 'Versiones gratuitas para macOS, Windows y Linux. Tus historias se quedan en archivos en tu ordenador.',
    latest: 'Última versión',
    prerelease: 'versión preliminar',
    published: 'Publicada el {date}',
    app: 'Plotcraft',
    mcp: 'Servidor MCP',
    mcpHint: 'Permite que un cliente de IA trabaje en tus proyectos.',
    button: 'Descargar',
    recommended: 'Recomendado para ti',
    notAvailable: 'No está en esta versión',
    checksums: 'Sumas de comprobación (SHA-256)',
    releaseNotes: 'Notas de la versión',
    allReleases: 'Todas las versiones en GitHub',
    loading: 'Buscando la última versión…',
    none: {
      title: 'Aún no hay versiones',
      text: 'Las primeras versiones todavía no se han publicado. Mientras tanto, puedes compilar Plotcraft desde el código.',
    },
    error: {
      title: 'No se pudieron cargar las versiones',
      text: 'GitHub no respondió. La página de versiones tiene todos los archivos.',
    },
    notes: {
      title: 'Conviene saber',
      unsigned:
        'Las versiones todavía no están firmadas digitalmente, así que el sistema te avisa la primera vez que las abres.',
      macos:
        'macOS: haz clic en la aplicación con la tecla Control pulsada, elige Abrir y confirma. Si dice que la aplicación está dañada, ejecuta una vez el comando de abajo.',
      windows: 'Windows: en la ventana de SmartScreen, elige Más información y luego Ejecutar de todas formas.',
      linux: 'Linux: extrae el archivo y ejecuta plotcraft/plotcraft. Necesita GTK 3 (libgtk-3-0).',
    },
    fromSource: 'Compilar desde el código',
  },
  mcp: {
    title: 'Deja que una IA ayude, sin perder el control',
    text: 'El servidor MCP permite que Claude Code, Claude Desktop y otros clientes creen y editen los mismos proyectos que abre la aplicación, con más de 60 herramientas. Ves aparecer los cambios mientras trabaja.',
    points: {
      revisions: 'Lee antes de escribir y usa revisiones, así que nunca sobrescribe lo que has escrito.',
      confirm: 'Todo lo que borra exige confirmación explícita, y los capítulos y elementos quitados se archivan.',
      readOnly: 'Puede funcionar en modo de solo lectura y trabaja solo con tus archivos locales.',
    },
    docs: 'Lee la guía del MCP',
  },
  footer: {
    tagline: 'Plotcraft — planifica tus historias.',
    docs: 'Documentación',
    source: 'Código fuente',
    releases: 'Versiones',
    built: 'Hecho con Flutter y Vue.',
  },
}

export default es
