int _last = 0;

/// A short ID based on the clock that never repeats within the process, even
/// when several are asked for in the same microsecond (a loop that creates
/// relations or phases would otherwise get the same ID twice).
String newTimeId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _last = now > _last ? now : _last + 1;
  return _last.toRadixString(36);
}
