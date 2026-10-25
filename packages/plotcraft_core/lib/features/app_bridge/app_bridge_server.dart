import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bridge_protocol.dart';
import '../../core/file_system.dart';

typedef BridgeHandler = Future<Object?> Function(Map<String, Object?> params);

/// The side that answers (the app). It keeps a heartbeat so the MCP server
/// knows the app is running, and serves the requests left in the inbox.
class AppBridgeServer {
  AppBridgeServer(
    String root, {
    required this.handlers,
    this.version = '',
    this.status = _noStatus,
    this.heartbeat = const Duration(seconds: 3),
    this.poll = const Duration(milliseconds: 150),
  }) : _folder = BridgeFolder(root);

  static Map<String, Object?> _noStatus() => const {};

  final BridgeFolder _folder;
  final Map<String, BridgeHandler> handlers;
  final String version;

  /// Extra facts written in the heartbeat (theme, language...).
  final Map<String, Object?> Function() status;
  final Duration heartbeat;
  final Duration poll;

  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  bool _busy = false;
  bool _stopped = true;
  final _startedAt = DateTime.now().toUtc();

  String get root => _folder.root;

  Future<void> start() async {
    if (!_stopped) return;
    _stopped = false;
    try {
      await _folder.inbox.create(recursive: true);
      await _folder.outbox.create(recursive: true);
      await _clearOld();
      await _writeHeartbeat();
    } on FileSystemException {
      // The folder is not writable; the bridge stays off.
      _stopped = true;
      return;
    }
    _heartbeatTimer = Timer.periodic(heartbeat, (_) => _writeHeartbeat());
    _pollTimer = Timer.periodic(poll, (_) => _serve());
  }

  Future<void> stop() async {
    _stopped = true;
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    try {
      await _folder.appFile.delete();
    } on FileSystemException {
      // Nothing to remove.
    }
  }

  Future<void> _writeHeartbeat() async {
    if (_stopped) return;
    try {
      final temp = fs.file('${_folder.appFile.path}.tmp');
      await temp.writeAsString(
        jsonEncode({
          'pid': pid,
          'version': version,
          'started_at': _startedAt.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'projects_folder': root,
          ...status(),
        }),
      );
      await temp.rename(_folder.appFile.path);
    } on FileSystemException {
      // Try again at the next beat.
    }
  }

  /// Requests left over from a previous run are not answered.
  Future<void> _clearOld() async {
    for (final directory in [_folder.inbox, _folder.outbox]) {
      await for (final entity in directory.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } on FileSystemException {
            // Ignore.
          }
        }
      }
    }
  }

  Future<void> _serve() async {
    if (_busy || _stopped) return;
    _busy = true;
    try {
      final requests = <File>[];
      await for (final entity in _folder.inbox.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          requests.add(entity);
        }
      }
      requests.sort((a, b) => a.path.compareTo(b.path));
      for (final file in requests) {
        await _answer(file);
      }
    } on FileSystemException {
      // The folder disappeared; keep polling.
    } finally {
      _busy = false;
    }
  }

  Future<void> _answer(File file) async {
    Map<String, dynamic> request;
    try {
      request = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      return; // Probably still being written.
    } on FileSystemException {
      return;
    }
    try {
      await file.delete();
    } on FileSystemException {
      return;
    }
    final id = '${request['id']}';
    Map<String, Object?> response;
    final handler = handlers['${request['method']}'];
    if (handler == null) {
      response = _error(
        'unknown_method',
        'Unknown method "${request['method']}".',
      );
    } else {
      try {
        final params = Map<String, Object?>.from(
          (request['params'] as Map?) ?? const {},
        );
        final result = await handler(params);
        response = {
          'ok': true,
          'result': result is Map ? result : {'value': result},
        };
      } on BridgeError catch (error) {
        response = _error(error.code, error.message);
      } catch (error) {
        response = _error('internal', '$error');
      }
    }
    final target = fs.file(p.join(_folder.outbox.path, '$id.json'));
    final temp = fs.file('${target.path}.tmp');
    await temp.writeAsString(jsonEncode({'id': id, ...response}));
    await temp.rename(target.path);
  }

  Map<String, Object?> _error(String code, String message) => {
    'ok': false,
    'error': {'code': code, 'message': message},
  };
}
