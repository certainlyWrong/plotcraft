import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Tells when something other than the app changes files inside a project
/// folder (another program, the MCP server). Events come in bursts, so they
/// are merged: [changes] fires once, [debounce] after the last one.
class ProjectChangeWatcher {
  ProjectChangeWatcher(
    this.folder, {
    this.debounce = const Duration(milliseconds: 400),
  });

  final String folder;
  final Duration debounce;

  final _controller = StreamController<void>.broadcast();
  final _subscriptions = <StreamSubscription<FileSystemEvent>>[];
  Timer? _timer;
  bool _disposed = false;

  Stream<void> get changes => _controller.stream;

  void start() {
    if (_disposed || _subscriptions.isNotEmpty) return;
    try {
      _subscriptions.add(
        Directory(folder)
            .watch(recursive: true)
            .listen(_onEvent, onError: (_) {}),
      );
    } on UnsupportedError {
      // Recursive watching does not exist on every platform: watch the
      // folders that hold the project's files one by one.
      for (final path in [
        folder,
        p.join(folder, 'content', 'book'),
        p.join(folder, 'content', 'book', 'chapters'),
        p.join(folder, 'content', 'narrative'),
        p.join(folder, 'content', 'narrative', 'elements'),
        p.join(folder, 'gallery'),
      ]) {
        if (Directory(path).existsSync()) {
          _subscriptions.add(
            Directory(path).watch().listen(_onEvent, onError: (_) {}),
          );
        }
      }
    } on FileSystemException {
      // The folder is gone or not readable: nothing to watch.
    }
  }

  static const _ignoredFolders = {'.plotcraft', 'archive', 'migration-backup'};

  /// Whether an event on [path] is worth reloading for: not a temporary file
  /// of an atomic write, and not the server's own log or the archives.
  bool _relevant(String path) {
    final name = p.basename(path);
    if (name.endsWith('.tmp') || name.endsWith('.removing')) return false;
    final relative = p.relative(path, from: folder);
    return !p.split(relative).any(_ignoredFolders.contains);
  }

  void _onEvent(FileSystemEvent event) {
    // A folder's own events only echo changes of the files in it.
    if (event.isDirectory || !_relevant(event.path)) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!_disposed) _controller.add(null);
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_controller.close());
  }
}
