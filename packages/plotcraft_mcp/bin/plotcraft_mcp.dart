import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:plotcraft_mcp/plotcraft_mcp.dart';

const _usage = '''
Plotcraft MCP server (stdio).

Usage: plotcraft_mcp --root <projects folder> [options]

''';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'root',
      abbr: 'r',
      help:
          'Folder whose subfolders are Plotcraft projects '
          '(or set PLOTCRAFT_ROOT).',
    )
    ..addMultiOption(
      'project',
      abbr: 'p',
      help: 'Extra project folder outside --root (repeatable).',
    )
    ..addFlag(
      'read-only',
      negatable: false,
      help: 'Refuse every tool that changes something.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage)
      ..writeln(parser.usage);
    exit(64);
  }
  if (options.flag('help')) {
    stdout
      ..writeln(_usage)
      ..writeln(parser.usage);
    return;
  }
  final root = options.option('root') ?? Platform.environment['PLOTCRAFT_ROOT'];
  final projects = options.multiOption('project');
  if (root == null && projects.isEmpty) {
    stderr
      ..writeln('Give a projects folder with --root or set PLOTCRAFT_ROOT.')
      ..writeln(parser.usage);
    exit(64);
  }
  // stdout carries the protocol; everything else goes to stderr.
  PlotcraftMcpServer(
    stdioChannel(input: stdin, output: stdout),
    ServerConfig(
      root: root,
      projectFolders: projects,
      readOnly: options.flag('read-only'),
    ),
  );
}
