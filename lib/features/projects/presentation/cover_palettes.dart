import '../../../core/theme/plotcraft_tokens.dart';

/// Cover colours, one per stage of the journey: a pigment and the paler ink it
/// thins to. A project's `coverIndex` picks one; the order is the order in which
/// colour enters the world (grey, red, green, blue, yellow).
final coverPalettes = [
  for (final stage in StageId.values)
    [GrisStages.dark[stage]!.pigment, GrisStages.dark[stage]!.ink],
];
