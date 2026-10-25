import 'package:file/file.dart';
import 'package:file/local.dart';

/// The file system every repository reads and writes through.
///
/// On the desktop it is the real disk. The web demo has no disk, so its
/// `main` swaps in a `MemoryFileSystem` before anything else runs. The files it
/// hands out are `dart:io` files, so the code that uses them does not change.
FileSystem fs = const LocalFileSystem();
