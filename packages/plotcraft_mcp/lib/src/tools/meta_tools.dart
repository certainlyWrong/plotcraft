import '../tool_spec.dart';

const serverVersion = '0.1.0';

List<ToolSpec> metaTools() => [
  ToolSpec(
    name: 'get_server_info',
    title: 'Server information',
    description:
        'Describes this Plotcraft MCP server: version, the projects folder, '
        'whether it is read-only, and how many projects it sees.',
    kind: ToolKind.read,
    handler: (call) async {
      final config = call.context.config;
      return {
        'name': 'plotcraft',
        'version': serverVersion,
        'projects_folder': config.root,
        'extra_project_folders': config.projectFolders,
        'read_only': config.readOnly,
        'projects_found': (await call.context.projects()).length,
      };
    },
  ),
];
