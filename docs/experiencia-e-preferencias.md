# Experiência e preferências

## Desktop em primeiro lugar

Plotcraft é essencialmente desktop. A interface principal deve priorizar navegação confortável entre projetos e um espaço de trabalho adequado a sessões longas de desenvolvimento de histórias. A tecnologia atual é Flutter; requisitos específicos de plataformas e comportamento de janelas ainda precisam ser definidos.

## Temas

O aplicativo oferece temas visuais selecionáveis e salva a escolha localmente. Violet (padrão), Paper, Midnight, Lavender, Moss, Rose, Ocean e Plum possuem variantes claras e escuras definidas em código. Também é possível incluir temas JSON em `assets/themes/`; o app encontra esses arquivos no manifesto de assets e os adiciona à lista de temas.

Cada arquivo de tema define `id`, `name`, `brightness` (`light` ou `dark`), `background`, `foreground` e `accent`. `surface`, `surfaceRaised`, `surfaceMuted`, `outline`, `outlineVariant`, `onSurfaceVariant` e `onAccent` são opcionais; quando ausentes, o app deriva valores coerentes a partir da paleta principal para manter compatibilidade com temas existentes. As cores usam hexadecimal no formato `#RRGGBB`. Um exemplo funcional está em `assets/themes/ink-and-copper.json`. Como são assets do Flutter, novos arquivos entram no aplicativo ao compilar uma nova versão.

## Idiomas

A interface usa `easy_localization` e carrega traduções JSON de `assets/translations/`. Os arquivos `en.json` e `pt.json` fornecem inglês (padrão) e português. O app detecta os arquivos de tradução disponíveis e monta a lista de idiomas a partir deles; para adicionar um idioma, inclua seu arquivo JSON nesse diretório usando o código de idioma como nome. A preferência de idioma é salva pelo próprio `easy_localization`.

- Inglês — idioma padrão.
- Português.

O idioma da interface não determina o idioma em que a pessoa escreve suas histórias. As chaves de tradução ficam organizadas por área (`home`, `project`, `preferences` e `sidebar`) para permitir o crescimento dos textos sem concentrar traduções na interface.

## Fonte da interface

A fonte padrão é **Times New Roman**. A pessoa pode escolher outra família no painel de preferências. A lista inicial inclui DM Sans, Lora, Merriweather e Roboto, carregadas pelo pacote `google_fonts`; as opções ficam centralizadas em `lib/theme/interface_fonts.dart` para facilitar sua extensão. Os arquivos das fontes selecionáveis e suas licenças ficam em `assets/fonts/`; a busca de fontes pela rede fica desativada e a troca usa somente arquivos locais. A preferência é salva localmente e aplicada a todos os estilos de texto.

## Pasta de projetos

O aplicativo usa a pasta `Plotcraft` dentro do diretório de documentos do sistema para novos projetos. Em Preferências, a pessoa pode escolher outra pasta ou restaurar a localização padrão. A escolha é persistida localmente. Os projetos existentes permanecem em seus locais atuais; a biblioteca mantém seus caminhos. Consulte [Modelo de projeto](modelo-de-projeto.md) para a estrutura de cada pasta.

No macOS, a escolha usa um painel nativo que também registra a autorização para acessar a pasta em sessões futuras. O painel começa na pasta padrão quando ela existe; caso contrário, abre no diretório existente mais próximo. Cancelar a escolha mantém a preferência atual.
