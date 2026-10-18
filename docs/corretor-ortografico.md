# Corretor ortográfico no editor rico

Resultado do teste de viabilidade feito antes de adotar o `flutter_quill`: **é viável**, com o corretor do próprio sistema.

## O problema
O `flutter_quill` desenha o texto por conta própria e não usa o `SpellCheckService` do Flutter, que é o que o `TextField` usa. O corretor do sistema precisa então ser ligado ao Quill por outro caminho.

## O que foi verificado
- **Gancho de desenho.** O Quill aceita um `textSpanBuilder` em `QuillEditorConfig`. Ele recebe cada trecho de texto junto com o deslocamento no documento (`node.documentOffset + nodeOffset`), então dá para dividir o trecho nas palavras erradas e sublinhá-las com uma linha ondulada. É só pintura: nada é gravado no documento, e portanto o Delta salvo e o histórico de desfazer ficam limpos (um teste confere que o Delta não contém `underline` nem `wavy`).
- **Menu de sugestões.** `contextMenuBuilder` recebe o estado do editor, que expõe `contextMenuButtonItems` e `contextMenuAnchors`. O menu normal é mantido e as sugestões entram na frente.
- **Posição dos sublinhados ao digitar.** Os intervalos acompanham cada edição (`Delta.transformPosition`), então o sublinhado fica na palavra até a próxima checagem. Respostas de checagens antigas são descartadas.
- **Desfazer.** A troca por uma sugestão é uma única edição do Quill. Observação para os testes e para o carregamento: o documento deve ser criado a partir do JSON salvo (`Document.fromJson`). Um documento montado com `insert` depois de criado faz o primeiro "desfazer" voltar ao texto vazio.

## Código nativo (macOS)
Medições com o `NSSpellChecker` em um texto de 10 mil palavras (1.100 erros):

| Forma | Tempo |
|---|---|
| `checkSpelling` em laço, só os intervalos | 439 ms |
| `checkSpelling` em laço, com sugestões para 300 erros | 3,8 s |
| `requestChecking` assíncrono, texto inteiro | 91 ms |
| `requestChecking`, um parágrafo de 400 caracteres | 2,6 ms |
| sugestões de uma palavra | 16 ms |

Decisões a partir disso:
- A checagem usa `requestChecking` (assíncrono, sem limite de erros) e devolve **só os intervalos**.
- As sugestões vêm de uma chamada separada (`suggest`), feita **sob demanda**, quando a pessoa abre o menu sobre uma palavra.
- Com a identificação automática de idioma ligada, o idioma pedido era ignorado. Ela é desligada a cada chamada.
- `learn` adiciona uma palavra ao dicionário do usuário.

Medido no app macOS de verdade (`tool/spellcheck_probe.dart`): texto de 66 mil caracteres com 4.000 erros em cerca de 120 ms pelo canal; em `pt-BR` só os erros reais são marcados, e em `en` as palavras portuguesas também.

## Desempenho no Dart
Capítulo de 10 mil palavras com 1.428 erros (teste de widget em modo debug, mais lento que o app): primeira pintura com sublinhados 129 ms, e uma tecla digitada repinta em 31 ms. O Quill monta todos os parágrafos do documento, então o custo cresce com o tamanho do capítulo.

## Estrutura
- `lib/core/spellcheck/spell_check_backend.dart`: contrato (`check`, `suggest`, `learn`) e a implementação por canal do macOS.
- `lib/core/spellcheck/quill_spell_checker.dart`: liga um `QuillController` ao corretor, mantém os intervalos e fornece `spanBuilder` e `buildContextMenu`.
- `macos/Runner/MainFlutterWindow.swift`: métodos `checkRanges`, `suggest` e `learn`.
- `tool/spellcheck_probe.dart`: roda o corretor nativo uma vez e imprime o resultado (`flutter run -d macos -t tool/spellcheck_probe.dart`).

## Ainda não feito
- Windows (`ISpellChecker`) e Linux (enchant ou hunspell) precisam de implementações do mesmo contrato; sem elas o editor funciona, só sem sublinhados.
- Checagem incremental por parágrafo: hoje o texto inteiro é checado após a pausa na digitação, o que é rápido o bastante para capítulos normais.
- Ligar o corretor ao editor do workspace (acontece quando o Quill substituir o editor de Markdown).
