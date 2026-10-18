import 'package:dart_mcp/server.dart';

GetPromptResult _prompt(String description, String text) => GetPromptResult(
  description: description,
  messages: [
    PromptMessage(
      role: Role.user,
      content: Content.text(text: text),
    ),
  ],
);

PromptArgument _arg(String name, String description, {bool required = true}) =>
    PromptArgument(name: name, description: description, required: required);

String _value(GetPromptRequest request, String name) =>
    (request.arguments?[name] as String?)?.trim() ?? '';

/// Prompts: ready-made instructions that say which tools to use and how.
void registerPrompts(PromptsSupport server) {
  server
    ..addPrompt(
      Prompt(
        name: 'story_bible_from_premise',
        description:
            'Build the story bible of a project from a premise: elements '
            'with relations and a chapter outline.',
        arguments: [
          _arg('project', 'Project id or title (create it first if needed).'),
          _arg('premise', 'The idea of the story, in a few sentences.'),
        ],
      ),
      (request) => _prompt(
        'Story bible',
        'Using the Plotcraft tools, develop the story bible of project '
            '"${_value(request, 'project')}" from this premise:\n\n'
            '${_value(request, 'premise')}\n\n'
            'Steps: 1) read the resource plotcraft://guide/data-model; '
            '2) call get_project and list_elements to see what exists; '
            '3) create the main elements with create_element (characters, places, '
            'objects, organizations...), each with a summary, aliases and its '
            'type details (see list_element_types); create elements that others '
            'point to first; 4) add relations with add_relation and phases '
            'anchored to chapters with add_phase when the story changes them; '
            '5) outline the book: add_chapter for each chapter with a one-line '
            'summary as its first text; 6) report what you created. Do not delete '
            'or overwrite anything that already exists.',
      ),
    )
    ..addPrompt(
      Prompt(
        name: 'draft_chapter',
        description:
            'Write or continue a chapter consistent with the elements.',
        arguments: [
          _arg('project', 'Project id or title.'),
          _arg('chapter_id', 'The chapter to write (see list_chapters).'),
          _arg('direction', 'What should happen in it.'),
        ],
      ),
      (request) => _prompt(
        'Draft a chapter',
        'In project "${_value(request, 'project')}", write chapter '
            '"${_value(request, 'chapter_id')}": ${_value(request, 'direction')}\n\n'
            'First read the previous chapters (get_chapter), the elements that '
            'appear (get_element with chapter_id, so you use the phase in force) '
            'and the Markdown guide (plotcraft://guide/markdown). Write with '
            'write_chapter (mode append when continuing; send base_revision when '
            'replacing), linking names as [[element:id|Name]]. Keep the voice and '
            'facts of the existing text.',
      ),
    )
    ..addPrompt(
      Prompt(
        name: 'continuity_check',
        description:
            'Look for contradictions between the text and the elements.',
        arguments: [_arg('project', 'Project id or title.')],
      ),
      (request) => _prompt(
        'Continuity check',
        'Check the continuity of project "${_value(request, 'project')}". '
            'Read every element (list_elements, get_element) and every chapter '
            '(list_chapters, get_chapter). Report contradictions: details that '
            'differ from the elements (age, appearance, relations), things that '
            'happen before a phase says they could, names or aliases used '
            'inconsistently, and elements that are never mentioned '
            '(get_element_references). Quote the chapter and the text for each '
            'finding. Change nothing unless asked.',
      ),
    )
    ..addPrompt(
      Prompt(
        name: 'develop_character',
        description:
            'Flesh out a character with details, backstory and phases.',
        arguments: [
          _arg('project', 'Project id or title.'),
          _arg('element_id', 'The character (see list_elements).'),
        ],
      ),
      (request) => _prompt(
        'Develop a character',
        'In project "${_value(request, 'project')}", deepen element '
            '"${_value(request, 'element_id')}". Read it (get_element), the '
            'chapters where it appears (get_element_references) and its '
            'relations. Then fill the empty details with update_element, add a '
            '"Backstory" section with add_section, and propose phases anchored to '
            'the chapters where the character changes (add_phase). Keep what is '
            'already written; only add.',
      ),
    )
    ..addPrompt(
      Prompt(
        name: 'revise_chapter',
        description: 'Revise a chapter for a goal, keeping the formatting.',
        arguments: [
          _arg('project', 'Project id or title.'),
          _arg('chapter_id', 'The chapter to revise.'),
          _arg('goal', 'What to improve (pace, clarity, tone...).'),
        ],
      ),
      (request) => _prompt(
        'Revise a chapter',
        'Revise chapter "${_value(request, 'chapter_id')}" of project '
            '"${_value(request, 'project')}" with this goal: '
            '${_value(request, 'goal')}\n\n'
            'Read it with get_chapter (format delta shows colors and fonts). '
            'Prefer small precise changes with edit_chapter (replace_text, '
            'insert_after_text...), which keep formatting and links; use '
            'write_chapter replace only for a full rewrite, and send '
            'base_revision. Summarise what you changed.',
      ),
    );
}
