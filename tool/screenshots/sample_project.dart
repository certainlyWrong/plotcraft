// Builds realistic sample projects on disk, through the same repositories the
// app uses, so the screenshots show real data.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:path/path.dart' as p;
import 'package:plotcraft/core/icons/icon_ref.dart';
import 'package:plotcraft/features/project_workspace/data/project_workspace_repository.dart';
import 'package:plotcraft/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft/features/project_workspace/domain/element_image.dart';
import 'package:plotcraft/features/project_workspace/domain/element_relation.dart';
import 'package:plotcraft/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_anchor.dart';
import 'package:plotcraft/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft/features/project_workspace/domain/rich/rich_document.dart';
import 'package:plotcraft/features/projects/data/project_creation_service.dart';
import 'package:plotcraft/features/projects/domain/project_metadata_input.dart';
import 'package:plotcraft/features/projects/domain/story_project.dart';

import 'harness.dart';

ProjectMetadataInput _input({
  required String title,
  String subtitle = '',
  String author = '',
  String description = '',
  String genre = '',
  List<String> tags = const [],
  int cover = 0,
  String format = 'book',
  String? coverPath,
}) => ProjectMetadataInput(
  title: title,
  subtitle: subtitle,
  author: author,
  description: description,
  genre: genre,
  tags: tags,
  coverIndex: cover,
  coverSourcePath: coverPath,
  primaryFormat: format,
);

Map<String, dynamic> _mention(String id, String name) => {
  RichDocument.mentionKey: RichDocument.mention(id, name),
};

/// A book with chapters, elements, a gallery and a custom element type.
Future<StoryProject> buildSampleBook(Directory root) async {
  final images = Directory(p.join(root.path, '_images'))
    ..createSync(recursive: true);
  final palette = [
    (const Color(0xFFB86D52), const Color(0xFFE5B99C)),
    (const Color(0xFF526E70), const Color(0xFFB5C7B4)),
    (const Color(0xFF66608A), const Color(0xFFB9A9C9)),
    (const Color(0xFF9B7842), const Color(0xFFE3CE9B)),
    (const Color(0xFF4B657E), const Color(0xFF9FB9C8)),
    (const Color(0xFFA14D6B), const Color(0xFFE6B1C3)),
  ];
  final names = [
    'pista-ao-amanhecer',
    'tenis-dourado',
    'linha-de-chegada',
    'vento-de-sal',
    'treino-noturno',
    'arquibancada',
  ];
  final files = <String>[];
  for (var i = 0; i < palette.length; i++) {
    final path = p.join(images.path, '${names[i]}.png');
    await writeGradientImage(path, palette[i].$1, palette[i].$2);
    files.add(path);
  }
  final coverPath = p.join(images.path, 'capa.png');
  await writeGradientImage(
    coverPath,
    const Color(0xFF3D5A80),
    const Color(0xFFEE6C4D),
    width: 600,
    height: 900,
  );

  var project = await ProjectCreationService().create(
    _input(
      title: 'A Corredora',
      subtitle: 'Correndo e sonhando',
      author: 'Adriano Sousa',
      description: 'Maria treina todas as manhãs na pista de sal, entre o vento e a promessa de uma última corrida que pode mudar o destino da cidade.',
      genre: 'Esportes',
      tags: ['corrida', 'superação', 'cidade de sal'],
      cover: 0,
      coverPath: coverPath,
    ),
    root.path,
  );
  final repo = ProjectWorkspaceRepository();
  project = (await repo.gallery.importImages(project, files)).project;
  final gallery = await repo.gallery.items(project);
  String galleryId(String stem) =>
      gallery.firstWhere((g) => g.file.startsWith(stem)).id;

  // Chapters.
  final single = await repo.load(project);
  var book = (await repo.book.setChapterMode(project, single.book, true));
  project = book.project;
  final first = book.book.chapters.first;
  final chapters = <BookChapter>[first];
  for (final title in ['A largada', 'Vento contrário']) {
    final added = await repo.book.addChapter(project, book.book, title);
    project = added.project;
    book = added;
    chapters.add(added.book.chapters.last);
  }
  final renamed = [
    BookChapter(id: chapters[0].id, title: 'A pista de sal'),
    ...chapters.skip(1),
  ];
  book = await repo.book.updateChapters(project, book.book, renamed);
  project = book.project;

  Delta chapterOne() => Delta()
    ..insert('A pista de sal')
    ..insert('\n', {'header': 1})
    ..insert('O dia ainda não tinha decidido se ia chover quando ')
    ..insert('Maria', _mention('maria', 'Maria'))
    ..insert(' amarrou os cadarços do ')
    ..insert('tênis dourado', {'bold': true})
    ..insert(
      '. A pista de sal brilhava devagar, como se guardasse a noite inteira dentro dela.\n',
    )
    ..insert('— Hoje é o dia — disse ')
    ..insert('Lia', _mention('lia', 'Lia'))
    ..insert(', sem tirar os olhos do cronômetro.\n')
    ..insert('Maria respirou fundo e olhou para a ')
    ..insert('arquibancada vazia', {'italic': true})
    ..insert('. Um dia, pensou, aquele lugar estaria cheio.\n')
    ..insert('Ela correu. O vento vinha do mar e cheirava a promessa.', {
      'color': '#B86D52',
      'font': 'Merriweather',
    })
    ..insert('\n', {'align': 'left'})
    ..insert(RichDocument.galleryImage(galleryId('pista')))
    ..insert('\n')
    ..insert('Primeira volta: ')
    ..insert('1min52', {'bold': true})
    ..insert('\n', {'list': 'bullet'})
    ..insert('Segunda volta: ')
    ..insert('1min49', {'bold': true})
    ..insert('\n', {'list': 'bullet'})
    ..insert('Era o suficiente para sonhar.\n');
  Delta chapterTwo() => Delta()
    ..insert('A largada')
    ..insert('\n', {'header': 1})
    ..insert('A pista de sal estava cheia pela primeira vez. ')
    ..insert('Maria', _mention('maria', 'Maria'))
    ..insert(' procurou o rosto de ')
    ..insert('Lia', _mention('lia', 'Lia'))
    ..insert(' na multidão e encontrou apenas o brilho do ')
    ..insert('tênis dourado', _mention('tenis', 'Tênis Dourado'))
    ..insert(' refletido nas poças.\nO apito soou. Maria correu.\n');
  Delta chapterThree() => Delta()
    ..insert('Vento contrário')
    ..insert('\n', {'header': 1})
    ..insert(
      'Na reta final, o vento mudou de lado. Lia gritou algo que ela não ouviu. Havia sal no ar e sal nos olhos.\n',
    );
  final deltas = [chapterOne(), chapterTwo(), chapterThree()];
  for (var i = 0; i < 3; i++) {
    final saved = await repo.book.saveBookDocument(
      project,
      book.book,
      book.book.chapters[i].id,
      deltas[i],
    );
    project = saved.project;
    book = saved;
  }

  // A custom element type.
  const magia = ElementType(
    id: 't_ritual',
    name: 'Ritual',
    icon: IconRef('RpgAwesome', 'crystal_ball'),
    colorValue: 0xFF7B5EA7,
    fields: [
      ElementField(id: 'quando', label: 'Quando acontece'),
      ElementField(
        id: 'efeito',
        label: 'Efeito',
        kind: ElementFieldKind.longText,
      ),
    ],
  );
  project = await repo.types.save(project, [magia]);

  DateTime now() => DateTime.now();
  final maria = NarrativeElement(
    id: 'maria',
    typeId: 'character',
    title: 'Maria',
    aliases: const ['A Corredora', 'Mari'],
    summary: 'Corredora da pista de sal. Teimosa, silenciosa e rápida.',
    tags: const ['protagonista'],
    images: [
      ElementImage.gallery(galleryId('tenis')),
      ElementImage.gallery(galleryId('linha')),
    ],
    fields: const {
      'age': '17',
      'occupation': 'Corredora',
      'personality': 'Obstinada, observadora, pouco falante.',
    },
    sections: const [
      NarrativeSection(
        id: 's1',
        title: 'Origem',
        markdown:
            'Cresceu perto do mar, onde aprendeu a correr contra o vento.',
      ),
    ],
    phases: [
      NarrativePhase(
        id: 'p1',
        title: 'Antes da corrida',
        description: 'Insegura, treina sozinha de madrugada.',
        anchor: NarrativeAnchor.chapter(chapters[0].id),
        image: ElementImage.gallery(galleryId('tenis')),
      ),
      NarrativePhase(
        id: 'p2',
        title: 'Depois da largada',
        description: 'Ganha confiança diante do público.',
        anchor: NarrativeAnchor.chapter(chapters[1].id),
        fieldOverrides: const {'personality': 'Corajosa, mas ainda calada.'},
      ),
    ],
    relations: const [
      ElementRelation(
        id: 'r1',
        targetId: 'lia',
        label: 'amiga de',
        reciprocalLabel: 'amiga de',
      ),
      ElementRelation(
        id: 'r2',
        targetId: 'tenis',
        label: 'é dona de',
        reciprocalLabel: 'pertence a',
      ),
    ],
    createdAt: now(),
    updatedAt: now(),
  );
  final lia = NarrativeElement(
    id: 'lia',
    typeId: 'character',
    title: 'Lia',
    summary: 'Treinadora e amiga de infância.',
    tags: const ['apoio'],
    fields: const {'age': '35', 'occupation': 'Treinadora'},
    sections: const [],
    phases: const [],
    createdAt: now(),
    updatedAt: now(),
  );
  final pista = NarrativeElement(
    id: 'pista',
    typeId: 'place',
    title: 'Pista de Sal',
    aliases: const ['a pista'],
    summary: 'Pista natural sobre uma antiga salina, que brilha ao amanhecer.',
    tags: const ['cenário'],
    images: [
      ElementImage.gallery(galleryId('pista')),
      ElementImage.gallery(galleryId('vento')),
    ],
    fields: const {'region': 'Litoral', 'climate': 'Seco e ventoso'},
    sections: const [],
    phases: const [],
    createdAt: now(),
    updatedAt: now(),
  );
  final tenis = NarrativeElement(
    id: 'tenis',
    typeId: 'object',
    title: 'Tênis Dourado',
    summary: 'Herança de família. Dizem que corre sozinho.',
    tags: const ['apoio'],
    fields: const {'origin': 'Herança do avô', 'owner': 'Maria'},
    sections: const [],
    phases: const [],
    createdAt: now(),
    updatedAt: now(),
  );
  final ritual = NarrativeElement(
    id: 'ritual',
    typeId: 't_ritual',
    title: 'Corrida do Sal',
    summary: 'Cerimônia anual em que os corredores atravessam a salina.',
    tags: const ['cenário'],
    fields: const {
      'quando': 'Na primeira maré baixa do ano',
      'efeito': 'Quem vence escolhe o nome do ano.',
    },
    sections: const [],
    phases: const [],
    createdAt: now(),
    updatedAt: now(),
  );
  for (final element in [maria, lia, pista, tenis, ritual]) {
    project = (await repo.narrative.saveElement(project, element)).$1;
  }
  return project;
}

/// A manga project, with a few elements and gallery images.
Future<StoryProject> buildSampleManga(Directory root) async {
  final images = Directory(p.join(root.path, '_manga'))
    ..createSync(recursive: true);
  final path = p.join(images.path, 'p1.png');
  await writeGradientImage(
    path,
    const Color(0xFF222831),
    const Color(0xFF948979),
    width: 600,
    height: 900,
  );
  var project = await ProjectCreationService().create(
    _input(
      title: 'Linhas de Tinta',
      subtitle: 'Capítulo zero',
      author: 'Equipe Tinta',
      description: 'Um mangá sobre aprendizes de desenhistas numa cidade que nunca dorme.',
      genre: 'Seinen',
      tags: ['mangá', 'drama'],
      cover: 4,
      format: 'manga',
      coverPath: path,
    ),
    root.path,
  );
  final repo = ProjectWorkspaceRepository();
  project = (await repo.gallery.importImages(project, [path])).project;
  project = (await repo.narrative.saveElement(
    project,
    NarrativeElement(
      id: 'hana',
      typeId: 'character',
      title: 'Hana',
      summary: 'Aprendiz de desenhista.',
      sections: const [],
      phases: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  )).$1;
  return project;
}

/// A project that is just created: nothing in it yet.
Future<StoryProject> buildEmptyBook(
  Directory root, {
  String title = 'Cidades de Sal',
}) => ProjectCreationService().create(
  _input(title: title, subtitle: 'Rascunho', genre: 'Fantasia', cover: 3),
  root.path,
);
