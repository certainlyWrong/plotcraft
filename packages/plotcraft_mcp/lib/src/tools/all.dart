import '../tool_spec.dart';
import 'library_tools.dart';
import 'meta_tools.dart';

/// Every tool of the server, in the order a client lists them.
List<ToolSpec> allTools() => [...metaTools(), ...libraryTools()];
