[English](../visual-language.md) · **Português** · [Español](../es/visual-language.md)

# Linguagem visual

A interface do Plotcraft se inspira na arte do jogo [Gris](https://pt.wikipedia.org/wiki/Gris_(jogo_eletr%C3%B4nico)) (Nomada Studio, arte de Conrad Roset): aquarela e nanquim, um mundo que começa sem cor e a ganha ao longo do caminho. O site usa a mesma linguagem (`website/`), e esta página descreve como ela vive no aplicativo.

## Princípios

1. **Cor é progresso.** A janela começa cinza e ganha cor conforme o contexto: o que você está fazendo decide a cor, não um destaque fixo.
2. **Aquarela embaixo, tinta em cima.** Manchas suaves de pigmento sangram atrás do conteúdo; linhas finas de tinta (anéis, arcos, estrelas, pinceladas sob os títulos) ficam por cima.
3. **Silêncio.** Folhas de papel em vez de cartões com caixa, sem contornos duros, sem sombras fortes, sem ondulações de toque. A hierarquia vem do espaço e da tipografia.
4. **Lentidão.** Uma única curva (`PlotcraftMotion.curve`), transições de 0,2 a 1,6 s, movimento ambiente em dezenas de segundos. Nada corta.
5. **Serifa para a voz, sem serifa para a função.** Títulos e citações são em Lora; controles e texto usam a fonte de interface escolhida pela pessoa.

## Os estágios

Cada estágio tem um *pigmento* (áreas: aquarelas, amostras, gotas) e uma *tinta* (linhas, ícones, texto de destaque, o botão primário). Nos temas escuros a tinta é mais clara que o pigmento; nos claros, mais escura, para manter o contraste. Os valores ficam em `GrisStages` (`lib/core/theme/plotcraft_tokens.dart`) e coincidem com `website/src/style.css`.

| Estágio | Onde se aplica |
| --- | --- |
| Cinza | Biblioteca, preferências, visão geral do projeto |
| Vermelho | Escrita (manuscrito, capítulos) e criação de projeto |
| Verde | Elementos da história |
| Azul | Mapa da história e linha do tempo |
| Amarelo | Modo leitura e galeria |

Uma tela declara seu lugar com `StageScope(stage: ...)`; `context.tokens.ink` e `context.tokens.pigment` passam a segui-lo, e a cor sangra de um estágio ao próximo em `PlotcraftMotion.bleed` (1,6 s). No workspace, `stageForTab` (`shell/workspace_stage.dart`) leva a aba ativa ao seu estágio.

## Peças

- **Tema** — `ThemeDefinition` (`lib/core/theme/theme_definition.dart`). Dois temas embutidos, *Gris Night* (padrão) e *Gris Day*; temas JSON em `assets/themes/` continuam carregando e recebem os estágios padrão. Ids salvos dos temas antigos são levados ao mais próximo (`migrateThemeId`). O `ColorScheme` inteiro é escrito à mão e os temas dos componentes não têm ondulação nem camadas de estado.
- **Tokens** — `PlotcraftTokens` (`context.tokens`): pigmento e tinta do estágio, intensidade da aquarela e do grão, cor do papel. `PlotcraftRadii` são 8 / 12 / 14. `PlotcraftMotion` guarda a curva e as durações.
- **Efeitos** — `lib/core/ui/gris/`: `WatercolorWash` e `PaperGrain` (fragment shaders em `shaders/`, com um painter simples de reserva), `GrisBackdrop`, `CoverWash`, `OrbitRings`, `Constellation`, `ArchBridge`, `InkStroke`, `PigmentDrop`, `Reveal`, `MorphBadge`, `BrandMark` e `GrisClock`.
- **Componentes** — `lib/core/ui/`: `PlotcraftButton`, `PlotcraftChip`, `PlotcraftChoice`, `PlotcraftSegmented`, `PlotcraftSurface` / `PlotcraftCard`, `PlotcraftDialog`, `PlotcraftTextField` (uma linha de tinta sob o texto), `PlotcraftTabBar`, `PlotcraftNavIcon`, `PlotcraftSection` / `PlotcraftPageTitle` e `PlotcraftToaster`.

## Acessibilidade e desempenho

- **Contraste.** `test/gris/contrast_test.dart` verifica o WCAG AA (4,5:1) para texto, tinta, botão primário e manchas de seleção, em todos os estágios e nos dois temas, incluindo o pior caso de texto sobre o pigmento mais denso da aquarela. Esse caso define a intensidade máxima da aquarela (`washOpacity`: 20% no escuro, 24% no claro).
- **Movimento reduzido.** Com a configuração do sistema ligada, nenhum relógio ambiente roda e as revelações e os traços aparecem prontos.
- **Calmo por padrão.** O `GrisClock` roda a 20–30 fps, para enquanto a janela não está à frente e enquanto o widget está oculto (segue o `TickerMode`, então abas fechadas não animam). Atrás do workspace a aquarela roda a 8 fps. Os cartões da biblioteca só animam o selo sob o ponteiro.
- **Shaders podem falhar.** Se um programa de fragmento não carregar, a aquarela cai para gradientes radiais e o grão é omitido. `test/gris/gris_shaders_test.dart` é o único lugar onde um erro de GLSL apareceria.
- **Testes.** O que anima para sempre precisa ficar parado antes do `pumpAndSettle`: envolva o app em `MediaQuery(disableAnimations: true)`.

## Estendendo

- *Uma tela nova:* envolva-a em `StageScope` e use `context.tokens` nos destaques; evite `colorScheme.primary` para ênfase, que é um cinza neutro.
- *Um novo mapeamento de estágio:* acrescente em `stageForSection` e no teste dele.
- *Um novo efeito:* ponha em `lib/core/ui/gris/`, conduza o movimento ambiente com `GrisClock` e respeite `grisStill(context)`.
