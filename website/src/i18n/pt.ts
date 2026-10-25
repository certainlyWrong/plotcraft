import type en from './en'

const pt: typeof en = {
  meta: {
    title: 'Plotcraft — arquitete suas histórias',
    description:
      'O Plotcraft é um aplicativo desktop para arquitetar histórias antes e durante a escrita: elementos, relações, mapa da história, linha do tempo e modo leitura, em arquivos locais que são seus.',
  },
  nav: {
    demo: 'Experimente',
    features: 'Recursos',
    showcase: 'Tour',
    sample: 'História de exemplo',
    download: 'Download',
    mcp: 'IA',
    github: 'GitHub',
    language: 'Idioma',
    theme: 'Trocar tema',
  },
  hero: {
    tryDemo: 'Experimente no navegador',
    eyebrow: 'Um aplicativo desktop para quem conta histórias',
    title: 'Arquitete suas histórias antes e durante a escrita.',
    subtitle:
      'Personagens, lugares, relações e capítulos no mesmo lugar, em arquivos locais que são seus.',
    download: 'Baixar para {platform}',
    allDownloads: 'Todos os downloads',
    seeFeatures: 'Veja o que ele faz',
    version: 'Versão {version}',
    early: 'Estágio inicial: já funciona e ainda está crescendo.',
    imageAlt: 'O Plotcraft mostrando a ficha de um personagem ao lado da lista de elementos da história',
  },
  platforms: { macos: 'macOS', windows: 'Windows', linux: 'Linux' },
  features: {
    title: 'Tudo o que a história precisa, ao lado do texto',
    intro: 'O que você escreve e o que você planeja ficam ligados, para qualquer gênero e formato.',
    items: {
      elements: {
        title: 'Elementos da história',
        text: 'Personagens, lugares, objetos, criaturas, organizações, eventos, conceitos e notas, além de tipos próprios com os detalhes que a sua história pede.',
      },
      phases: {
        title: 'Fases e relações',
        text: 'Mostre como um elemento muda capítulo a capítulo e ligue elementos com rótulos que se leem nos dois sentidos.',
      },
      map: {
        title: 'Mapa da história',
        text: 'Um grafo interativo de elementos, relações, capítulos e de onde cada elemento é citado.',
      },
      timeline: {
        title: 'Linha do tempo',
        text: 'Quem aparece onde, por capítulo, e a cronologia do próprio mundo com datas livres.',
      },
      writing: {
        title: 'Escrita em texto rico',
        text: 'Fontes, cores, títulos, imagens, busca e substituição, salvamento automático e menções que ligam nomes a elementos.',
      },
      reading: {
        title: 'Modo leitura',
        text: 'O livro como um leitor o veria: um capítulo por vez, texto ajustável e nomes que abrem o elemento.',
      },
      gallery: {
        title: 'Galeria',
        text: 'Referências visuais em um mosaico que respeita a proporção real de cada imagem, ligadas a elementos e fases.',
      },
      files: {
        title: 'Arquivos locais',
        text: 'Cada projeto é uma pasta de Markdown, JSON e imagens. Copie, faça backup, versione. Nada fica preso.',
      },
      ai: {
        title: 'Funciona com IA',
        text: 'Um servidor MCP embutido deixa o Claude e outros clientes criarem e editarem os mesmos projetos, com segurança.',
      },
    },
  },
  showcase: {
    title: 'Um tour rápido',
    intro: 'Todas as telas abaixo vêm da história de exemplo que acompanha o aplicativo.',
    tabs: {
      map: {
        label: 'Mapa',
        title: 'Veja como tudo se liga',
        text: 'Elementos, relações, capítulos e onde cada elemento é citado, com filtros por tipo, busca, zoom e foco em um elemento e suas ligações.',
      },
      timeline: {
        label: 'Linha do tempo',
        title: 'Quem aparece onde',
        text: 'Uma matriz por capítulo com as fases que começam ali, e a cronologia do mundo em ordem ou em escala, com datas escritas do jeito que a sua história conta.',
      },
      reading: {
        label: 'Leitura',
        title: 'Leia como um leitor',
        text: 'Um capítulo por vez em uma coluna confortável, com o progresso do livro todo. Os nomes abrem o elemento com um clique.',
      },
      editor: {
        label: 'Escrita',
        title: 'Escreva com o seu mundo à mão',
        text: 'Um editor de texto rico com menções: passe o mouse sobre um nome para ver o cartão do elemento e a fase em que ele está naquele capítulo.',
      },
      gallery: {
        label: 'Galeria',
        title: 'Referências, como elas são',
        text: 'Cada imagem mantém a sua proporção, em retrato ou paisagem, e pode ser usada como capa, em uma fase ou no texto.',
      },
      theme: {
        label: 'Temas',
        title: 'Deixe com a sua cara',
        text: 'Oito temas com variantes clara e escura, temas JSON próprios, fontes de interface e fontes que viajam com o projeto.',
      },
    },
  },
  sample: {
    title: 'Experimente com uma história completa',
    text: 'O Plotcraft leva Herdeiros do Silêncio para você explorar sem começar do zero. Na tela inicial, escolha “Explorar a história de exemplo”: ela é copiada para a sua pasta de projetos e abre como qualquer outro projeto.',
    story:
      'Sete Vozes sustentam o universo, cada uma com um único portador, passadas em herança por um preço.',
    stats: { chapters: 'capítulos', elements: 'elementos ligados', plots: 'plots', images: 'imagens' },
    imageAlt: 'A biblioteca do Plotcraft com a história de exemplo',
  },
  download: {
    title: 'Baixe o Plotcraft',
    intro: 'Versões gratuitas para macOS, Windows e Linux. Suas histórias ficam em arquivos no seu computador.',
    latest: 'Última versão',
    prerelease: 'pré-lançamento',
    published: 'Publicada em {date}',
    app: 'Plotcraft',
    mcp: 'Servidor MCP',
    mcpHint: 'Deixa um cliente de IA trabalhar nos seus projetos.',
    button: 'Baixar',
    recommended: 'Recomendado para você',
    notAvailable: 'Não está nesta versão',
    checksums: 'Somas de verificação (SHA-256)',
    releaseNotes: 'Notas da versão',
    allReleases: 'Todas as versões no GitHub',
    loading: 'Procurando a última versão…',
    none: {
      title: 'Ainda não há versões',
      text: 'As primeiras versões ainda não foram publicadas. Enquanto isso, dá para compilar o Plotcraft a partir do código.',
    },
    error: {
      title: 'Não foi possível carregar as versões',
      text: 'O GitHub não respondeu. A página de versões tem todos os arquivos.',
    },
    notes: {
      title: 'Bom saber',
      unsigned:
        'As versões ainda não são assinadas digitalmente, então o sistema avisa na primeira vez que você as abre.',
      macos:
        'macOS: clique no aplicativo com a tecla Control, escolha Abrir e confirme. Se disser que o aplicativo está danificado, execute uma vez o comando abaixo.',
      windows: 'Windows: na janela do SmartScreen, escolha Mais informações e depois Executar assim mesmo.',
      linux: 'Linux: extraia o arquivo e execute plotcraft/plotcraft. Precisa do GTK 3 (libgtk-3-0).',
    },
    fromSource: 'Compilar a partir do código',
  },
  mcp: {
    title: 'Deixe uma IA ajudar, sem perder o controle',
    text: 'O servidor MCP deixa o Claude Code, o Claude Desktop e outros clientes criarem e editarem os mesmos projetos que o aplicativo abre, com mais de 60 ferramentas. Você vê as mudanças aparecerem enquanto ela trabalha.',
    points: {
      revisions: 'Ela lê antes de escrever e usa revisões, então nunca sobrescreve o que você digitou.',
      confirm: 'Tudo o que apaga exige confirmação explícita, e capítulos e elementos removidos são arquivados.',
      readOnly: 'Pode rodar em modo somente leitura e trabalha apenas nos seus arquivos locais.',
    },
    docs: 'Leia o guia do MCP',
  },
  footer: {
    tagline: 'Plotcraft — arquitete suas histórias.',
    docs: 'Documentação',
    source: 'Código-fonte',
    releases: 'Versões',
    built: 'Feito com Flutter e Vue.',
  },
}

export default pt
