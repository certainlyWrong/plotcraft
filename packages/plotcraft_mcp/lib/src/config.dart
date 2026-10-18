/// How the server was started.
class ServerConfig {
  const ServerConfig({
    this.root,
    this.projectFolders = const [],
    this.readOnly = false,
    this.logFile,
  });

  /// Folder whose direct subfolders are projects (the Plotcraft projects
  /// folder).
  final String? root;

  /// Extra project folders outside [root].
  final List<String> projectFolders;

  /// When true every tool that changes something refuses to run.
  final bool readOnly;

  /// Where to write the server's own diagnostics (stderr when null).
  final String? logFile;
}
