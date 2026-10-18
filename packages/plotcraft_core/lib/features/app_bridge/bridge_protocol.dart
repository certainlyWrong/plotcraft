import 'dart:io';

import 'package:path/path.dart' as p;

/// How Plotcraft (the app) and the MCP server talk to each other: files in
/// `<projects folder>/.plotcraft/`, which both can reach even when the app is
/// sandboxed.
///
/// * `app.json` is rewritten every few seconds by the running app;
/// * a request is a file `inbox/<id>.json` written by the server;
/// * the app answers with `outbox/<id>.json`.
class BridgeFolder {
  const BridgeFolder(this.root);

  final String root;

  String get path => p.join(root, '.plotcraft');
  File get appFile => File(p.join(path, 'app.json'));
  Directory get inbox => Directory(p.join(path, 'inbox'));
  Directory get outbox => Directory(p.join(path, 'outbox'));
}

/// A failure reported by the other side, or by the transport.
class BridgeError implements Exception {
  const BridgeError(this.code, this.message);

  /// `app_not_running`, `timeout`, `unknown_method`, `invalid_params`,
  /// `unsupported` or `internal`.
  final String code;
  final String message;

  @override
  String toString() => 'BridgeError($code): $message';
}
