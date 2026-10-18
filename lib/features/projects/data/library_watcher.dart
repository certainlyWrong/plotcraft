import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Tells when projects appear, disappear or change their manifest inside the
/// projects folder (for example when the MCP server creates one). Events from
/// inside a project's content are ignored: the workspace watches those.
class LibraryWatcher {
  LibraryWatcher(
    this.root, {
    this.debounce = const Duration(milliseconds: 600),
  });

  final String root;
  final Duration debounce;

  final _controller = StreamController<void>.broadcast();
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _timer;
  bool _disposed = false;

  Stream<void> get changes => _controller.stream;

  void start() {
    if (_disposed || _subscription != null) return;
    try {
      _subscription = Directory(root)
          .watch(recursive: true)
          .listen(_onEvent, onError: (_) {});
    } on UnsupportedError {
      _subscription = Directory(root).watch().listen(_onEvent, onError: (_) {});
    } on FileSystemException {
      // The folder does not exist (yet); nothing to watch.
    }
  }

  /// A project folder itself or its `project.json`, not what is inside.
  bool _relevant(String path) {
    final parts = p.split(p.relative(path, from: root));
    if (parts.any((part) => part.startsWith('.') && part != '.')) return false;
    return parts.length == 1 ||
        (parts.length == 2 && parts.last == 'project.json');
  }

  void _onEvent(FileSystemEvent event) {
    if (!_relevant(event.path)) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      if (!_disposed) _controller.add(null);
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_controller.close());
  }
}
