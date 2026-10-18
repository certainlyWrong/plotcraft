// Prints the Markdown table of every tool, for the README:
//   dart run tool/print_catalog.dart
import 'package:plotcraft_mcp/src/tool_spec.dart';
import 'package:plotcraft_mcp/src/tools/all.dart';

void main() {
  final tools = allTools();
  final buffer = StringBuffer()
    ..writeln('| Tool | What it does | Kind |')
    ..writeln('| --- | --- | --- |');
  for (final tool in tools) {
    final sentence = tool.description.split(RegExp(r'(?<=[.!?])\s')).first;
    final kind = switch (tool.kind) {
      ToolKind.read => 'read',
      ToolKind.write => 'write',
      ToolKind.destructive => '**destructive** (needs confirmation)',
    };
    buffer.writeln(
      '| `${tool.name}` | ${sentence.replaceAll('|', '\\|')} | $kind |',
    );
  }
  print(buffer);
  print('${tools.length} tools');
}
