import '../tool_spec.dart';
import 'app_tools.dart';
import 'asset_tools.dart';
import 'element_tools.dart';
import 'library_tools.dart';
import 'manuscript_tools.dart';
import 'meta_tools.dart';
import 'type_tools.dart';

/// Every tool of the server, in the order a client lists them.
List<ToolSpec> allTools() => [
  ...metaTools(),
  ...libraryTools(),
  ...manuscriptTools(),
  ...elementTools(),
  ...typeTools(),
  ...assetTools(),
  ...appTools(),
];
