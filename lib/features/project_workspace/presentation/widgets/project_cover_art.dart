import 'dart:io';

import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../../models/story_project.dart';
import '../../../project_creation/presentation/cover_palettes.dart';
import '../../../../theme/plotcraft_tokens.dart';

class ProjectCoverArt extends StatelessWidget {
  const ProjectCoverArt({
    super.key,
    required this.project,
    this.showTitle = true,
  });

  final StoryProject project;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final palette = coverPalettes[project.coverIndex % coverPalettes.length];
    final cover = project.coverFile == null || project.directoryPath == null
        ? null
        : File(p.join(project.directoryPath!, project.coverFile!));
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
            ),
          ),
          if (cover != null)
            Image.file(
              cover,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else
            Positioned(
              right: -18,
              top: -55,
              child: Icon(
                Feather.book_open,
                size: 250,
                color: context.tokens.onImage.withValues(alpha: .15),
              ),
            ),
          if (showTitle) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.tokens.imageScrim.withValues(alpha: .65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: context.tokens.onImage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (project.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      project.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.tokens.onImage.withValues(alpha: .9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
