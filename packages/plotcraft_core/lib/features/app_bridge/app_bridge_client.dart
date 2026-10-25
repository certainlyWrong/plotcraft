import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bridge_protocol.dart';
import '../../core/file_system.dart';

/// The side that asks (the MCP server).
class AppBridgeClient {
  AppBridgeClient(
    String root, {
    this.timeout = const Duration(seconds: 10),
    this.poll = const Duration(milliseconds: 100),
    this.staleAfter = const Duration(seconds: 10),
  }) : _folder = BridgeFolder(root);

  final BridgeFolder _folder;
  final Duration timeout;
  final Duration poll;

  /// The app counts as closed when its heartbeat is older than this.
  final Duration staleAfter;

  /// What the running app wrote about itself, or null when it is not running
  /// (no heartbeat, or an old one left by a crash).
  Future<Map<String, Object?>?> appStatus() async {
    try {
      final json = jsonDecode(await _folder.appFile.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final updated = DateTime.tryParse('${json['updated_at']}');
      if (updated == null ||
          DateTime.now().toUtc().difference(updated.toUtc()) > staleAfter) {
        return null;
      }
      return json;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Asks the app to run [method] and returns its result.
  Future<Map<String, Object?>> call(
    String method, [
    Map<String, Object?> params = const {},
  ]) async {
    if (await appStatus() == null) {
      throw const BridgeError(
        'app_not_running',
        'The Plotcraft app is not running (or it uses another projects '
            'folder).',
      );
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
    await _folder.inbox.create(recursive: true);
    final request = fs.file(p.join(_folder.inbox.path, '$id.json'));
    final temp = fs.file('${request.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'id': id, 'method': method, 'params': params}),
    );
    await temp.rename(request.path);

    final response = fs.file(p.join(_folder.outbox.path, '$id.json'));
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await response.exists()) {
        Map<String, dynamic> body;
        try {
          body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        } on FormatException {
          // Still being written: try again on the next tick.
          await Future<void>.delayed(poll);
          continue;
        }
        await _quietDelete(response);
        if (body['ok'] == true) {
          return Map<String, Object?>.from(
            (body['result'] as Map?) ?? const <String, Object?>{},
          );
        }
        final error = (body['error'] as Map?) ?? const {};
        throw BridgeError(
          '${error['code'] ?? 'internal'}',
          '${error['message'] ?? 'The app could not do that.'}',
        );
      }
      await Future<void>.delayed(poll);
    }
    await _quietDelete(request);
    throw BridgeError(
      'timeout',
      'The app did not answer "$method" within ${timeout.inSeconds} seconds.',
    );
  }

  static int _counter = 0;

  Future<void> _quietDelete(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
