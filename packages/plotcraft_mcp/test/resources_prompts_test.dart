import 'package:dart_mcp/client.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late Harness h;
  late String project;
  late String chapter;

  setUp(() async {
    h = await Harness.start();
    final made = await h.makeProject('Livro');
    project = made.id;
    chapter = (await (await h.story(made)).chapters()).single.id;
  });
  tearDown(() => h.close());

  Future<String> read(String uri) async {
    final result = await h.connection.readResource(
      ReadResourceRequest(uri: uri),
    );
    return (result.contents.single as TextResourceContents).text;
  }

  test('guias e lista de projetos como recursos', () async {
    final resources = (await h.connection.listResources(ListResourcesRequest()))
        .resources;
    expect(
      resources.map((r) => r.uri),
      containsAll([
        'plotcraft://guide/data-model',
        'plotcraft://guide/markdown',
        'plotcraft://projects',
      ]),
    );
    expect(await read('plotcraft://guide/data-model'), contains('revision'));
    expect(await read('plotcraft://projects'), contains('Livro'));
    final templates = (await h.connection.listResourceTemplates(
      ListResourceTemplatesRequest(),
    )).resourceTemplates;
    expect(templates, hasLength(4));
  });

  test('capítulo, elemento e projeto por URI', () async {
    await h.call('write_chapter', {
      'project': project,
      'chapter_id': chapter,
      'markdown': 'Maria correu.',
    });
    await h.call('create_element', {
      'project': project,
      'id': 'maria',
      'type': 'character',
      'title': 'Maria',
    });
    expect(await read('plotcraft://projects/$project'), contains('"chapters"'));
    expect(
      await read('plotcraft://projects/$project/chapters/$chapter'),
      contains('Maria correu.'),
    );
    expect(
      await read('plotcraft://projects/$project/elements/maria'),
      contains('"title": "Maria"'),
    );
  });

  test('prompts guiados listam seus argumentos', () async {
    final prompts = (await h.connection.listPrompts(ListPromptsRequest()))
        .prompts;
    expect(
      prompts.map((p) => p.name),
      containsAll([
        'story_bible_from_premise',
        'draft_chapter',
        'continuity_check',
        'develop_character',
        'revise_chapter',
      ]),
    );
    final result = await h.connection.getPrompt(
      GetPromptRequest(
        name: 'story_bible_from_premise',
        arguments: {'project': 'Livro', 'premise': 'Uma corredora.'},
      ),
    );
    final text = (result.messages.single.content as TextContent).text;
    expect(text, contains('Uma corredora.'));
    expect(text, contains('create_element'));
  });
}
