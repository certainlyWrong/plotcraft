# Plotcraft

Plotcraft é um aplicativo desktop para arquitetar histórias. A proposta vai além de escrever texto: cada história é um projeto organizado, com contexto, metadados e ferramentas para desenvolver seus elementos antes e durante a escrita.

> O aplicativo ainda está em estágio inicial. A documentação descreve a visão e os conceitos pretendidos; não representa funcionalidades já disponíveis.

## Documentação

- [Visão do produto](docs/visao-do-produto.md) — propósito, público e experiência desejada.
- [Modelo de projeto](docs/modelo-de-projeto.md) — o que compõe um projeto de história.
- [Experiência e preferências](docs/experiencia-e-preferencias.md) — foco desktop, temas e idiomas.
- [MCP](docs/mcp.md) — como uma IA cria e gerencia histórias pelo Plotcraft (servidor em [`packages/plotcraft_mcp`](packages/plotcraft_mcp/README.md)).

## Estado atual

A área de projetos permite criar, buscar, ordenar e excluir projetos, além de escolher entre temas, idiomas e fontes. Cada projeto abre em um espaço de trabalho em painéis, com abas para visão geral, configurações, galeria, capítulos e elementos.

Os elementos narrativos (personagens, lugares, objetos, criaturas, organizações, eventos, conceitos, notas e tipos próprios) têm ícone e cor, apelidos, etiquetas, detalhes definidos pelo tipo, imagens da galeria ou do computador, relações, seções e fases ligadas a capítulos. O manuscrito é editado em texto rico (fontes, cores, alinhamento, listas, imagens da galeria), com corretor ortográfico do sistema no macOS e menções aos elementos. Os dados ficam em arquivos locais na pasta de cada projeto.

Uma IA pode trabalhar nos mesmos projetos por meio do servidor MCP (`tool/build_mcp.sh` gera o executável): ela cria capítulos, elementos, relações e fases, e o aplicativo mostra o resultado enquanto ela trabalha.
