export default {
  meta: {
    title: 'Plotcraft — architect your stories',
    description:
      'Plotcraft is a desktop app to architect stories before and while you write: elements, relations, a story map, a timeline and a reading mode, in local files that belong to you.',
  },
  nav: {
    demo: 'Try it',
    features: 'Features',
    showcase: 'Tour',
    sample: 'Sample story',
    download: 'Download',
    mcp: 'AI',
    github: 'GitHub',
    language: 'Language',
    theme: 'Switch theme',
  },
  hero: {
    tryDemo: 'Try it in your browser',
    eyebrow: 'A desktop app for storytellers',
    title: 'Architect your stories before and while you write.',
    subtitle:
      'Characters, places, relationships and chapters in one place, kept in local files that belong to you.',
    download: 'Download for {platform}',
    allDownloads: 'All downloads',
    seeFeatures: 'See what it does',
    version: 'Version {version}',
    early: 'Early stage: it works, and it is still growing.',
    imageAlt: 'Plotcraft showing the sheet of a character next to the list of the story’s elements',
  },
  platforms: { macos: 'macOS', windows: 'Windows', linux: 'Linux' },
  features: {
    title: 'Everything the story needs, next to the text',
    intro:
      'What you write and what you plan stay connected, for any genre and any format.',
    items: {
      elements: {
        title: 'Story elements',
        text: 'Characters, places, objects, creatures, organizations, events, concepts and notes, plus your own types with the details your story asks for.',
      },
      phases: {
        title: 'Phases and relations',
        text: 'Show how an element changes chapter by chapter, and link elements with labels that read both ways.',
      },
      map: {
        title: 'Story map',
        text: 'An interactive graph of elements, relations, chapters and where each element is cited.',
      },
      timeline: {
        title: 'Timeline',
        text: 'Who appears where, by chapter, and the world’s own chronology with free-form dates.',
      },
      writing: {
        title: 'Rich-text writing',
        text: 'Fonts, colors, headings, images, find and replace, autosave, and mentions that link names to elements.',
      },
      reading: {
        title: 'Reading mode',
        text: 'The book as a reader would see it: a chapter at a time, adjustable text, names that open their element.',
      },
      gallery: {
        title: 'Gallery',
        text: 'Visual references in a mosaic that respects each image’s real proportion, tied to elements and phases.',
      },
      files: {
        title: 'Local files',
        text: 'Every project is a folder of Markdown, JSON and images. Copy it, back it up, version it. Nothing is locked in.',
      },
      ai: {
        title: 'Works with AI',
        text: 'A built-in MCP server lets Claude and other clients create and edit the same projects, safely.',
      },
    },
  },
  showcase: {
    title: 'A quick tour',
    intro: 'Every screen below comes from the sample story that ships with the app.',
    tabs: {
      map: {
        label: 'Story map',
        title: 'See how everything connects',
        text: 'Elements, relations, chapters and where each element is cited, with filters by type, search, zoom and focus on one element and its connections.',
      },
      timeline: {
        label: 'Timeline',
        title: 'Who appears where',
        text: 'A matrix by chapter with the phases that begin there, and the world’s chronology in order or to scale, with dates written the way your story tells them.',
      },
      reading: {
        label: 'Reading',
        title: 'Read it like a reader',
        text: 'One chapter at a time in a comfortable column, with progress for the whole book. Names open their element with a click.',
      },
      editor: {
        label: 'Writing',
        title: 'Write with your world at hand',
        text: 'A rich-text editor with mentions: hover a name for the element’s card and the phase it is in at that chapter.',
      },
      gallery: {
        label: 'Gallery',
        title: 'References, as they are',
        text: 'Each image keeps its own proportion, whether portrait or landscape, and can be used as a cover, in a phase or in the text.',
      },
      theme: {
        label: 'Themes',
        title: 'Make it yours',
        text: 'Eight themes with light and dark variants, your own JSON themes, interface fonts, and fonts that travel with the project.',
      },
    },
  },
  sample: {
    title: 'Try it with a complete story',
    text: 'Plotcraft ships with Herdeiros do Silêncio (in Portuguese), so you can explore without starting from scratch. On the home screen, choose “Explore the sample story”: it is copied to your projects folder and opens like any other project.',
    story:
      'Seven Voices hold the universe together, each with a single bearer, passed on by inheritance at a price.',
    stats: { chapters: 'chapters', elements: 'linked elements', plots: 'plots', images: 'images' },
    imageAlt: 'The Plotcraft library showing the sample story',
  },
  download: {
    title: 'Download Plotcraft',
    intro: 'Free builds for macOS, Windows and Linux. Your stories stay in files on your computer.',
    latest: 'Latest release',
    prerelease: 'pre-release',
    published: 'Published on {date}',
    app: 'Plotcraft',
    mcp: 'MCP server',
    mcpHint: 'Lets an AI client work on your projects.',
    button: 'Download',
    recommended: 'Recommended for you',
    notAvailable: 'Not in this release',
    checksums: 'Checksums (SHA-256)',
    releaseNotes: 'Release notes',
    allReleases: 'All releases on GitHub',
    loading: 'Looking for the latest release…',
    none: {
      title: 'No release yet',
      text: 'The first builds have not been published yet. You can build Plotcraft from source in the meantime.',
    },
    error: {
      title: 'Could not load the releases',
      text: 'GitHub did not answer. The releases page has every file.',
    },
    notes: {
      title: 'Good to know',
      unsigned:
        'The builds are not code-signed yet, so your system warns you the first time you open them.',
      macos:
        'macOS: Control-click the app, choose Open and confirm. If it says the app is damaged, run the command below once.',
      windows: 'Windows: in the SmartScreen window, choose More info, then Run anyway.',
      linux: 'Linux: extract the archive and run plotcraft/plotcraft. It needs GTK 3 (libgtk-3-0).',
    },
    fromSource: 'Build from source',
  },
  mcp: {
    title: 'Let an AI help, without losing control',
    text: 'The MCP server lets Claude Code, Claude Desktop and other clients create and edit the same projects the app opens, with more than 60 tools. You see the changes appear while it works.',
    points: {
      revisions: 'It reads before it writes and uses revisions, so it never overwrites what you typed.',
      confirm: 'Anything that deletes needs explicit confirmation, and removed chapters and elements are archived.',
      readOnly: 'It can run in read-only mode, and it works on your local files only.',
    },
    docs: 'Read the MCP guide',
  },
  footer: {
    tagline: 'Plotcraft — architect your stories.',
    docs: 'Documentation',
    source: 'Source code',
    releases: 'Releases',
    built: 'Made with Flutter and Vue.',
  },
}
