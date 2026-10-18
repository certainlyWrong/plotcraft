import 'package:dart_mcp/server.dart';
import 'package:stream_channel/stream_channel.dart';

import 'config.dart';
import 'context.dart';
import 'tools/all.dart';
import 'tools/meta_tools.dart';

const _instructions = '''
Plotcraft is a story-architecting app. A project is a book (or manga) made of
chapters, plus "elements" (characters, places, objects, creatures,
organizations, events, concepts, notes) with images, phases, relations and
details.

Start with list_projects (or create_project), then work by project id.
Read before you write: get_chapter / get_element return a "revision" that you
send back as base_revision so you never overwrite something the author changed
meanwhile (a CONFLICT error means: read again and redo your change).
Write chapters in Markdown; link a name to an element with
[[element:<element id>|Name]]. Destructive tools need confirm: true and
confirm_name.
''';

/// The MCP server: tools, and later resources and prompts, over any channel.
base class PlotcraftMcpServer extends MCPServer with ToolsSupport {
  PlotcraftMcpServer(StreamChannel<String> channel, ServerConfig config)
    : context = ToolContext(config),
      super.fromStreamChannel(
        channel,
        implementation: Implementation(
          name: 'plotcraft',
          version: serverVersion,
        ),
        instructions: _instructions,
      ) {
    for (final spec in allTools()) {
      registerTool(spec.definition, (request) => spec.run(request, context));
    }
  }

  final ToolContext context;
}
