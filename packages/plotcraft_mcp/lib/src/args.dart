import 'package:plotcraft_core/features/project_workspace/services/story_error.dart';

/// Typed access to the arguments of a tool call. A missing or mistyped
/// argument becomes a `validation` error that names the argument.
class Args {
  Args(Map<String, Object?>? raw) : _raw = raw ?? const {};

  final Map<String, Object?> _raw;

  Map<String, Object?> get raw => _raw;

  bool has(String key) => _raw.containsKey(key) && _raw[key] != null;

  Never _wrong(String key, String expected) =>
      throw StoryError.validation('Argument "$key" must be $expected.');

  String string(String key) {
    final value = _raw[key];
    if (value == null) {
      throw StoryError.validation('Argument "$key" is required.');
    }
    if (value is! String) _wrong(key, 'a string');
    return value;
  }

  String? optString(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is! String) _wrong(key, 'a string');
    return value;
  }

  int? optInt(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.truncate()) return value.toInt();
    _wrong(key, 'an integer');
  }

  bool boolean(String key, {bool defaultValue = false}) {
    final value = _raw[key];
    if (value == null) return defaultValue;
    if (value is! bool) _wrong(key, 'true or false');
    return value;
  }

  bool? optBool(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is! bool) _wrong(key, 'true or false');
    return value;
  }

  List<String>? optStringList(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is! List || value.any((item) => item is! String)) {
      _wrong(key, 'a list of strings');
    }
    return value.cast<String>();
  }

  List<Map<String, Object?>>? optObjectList(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is! List || value.any((item) => item is! Map)) {
      _wrong(key, 'a list of objects');
    }
    return [for (final item in value) Map<String, Object?>.from(item as Map)];
  }

  Map<String, Object?>? optObject(String key) {
    final value = _raw[key];
    if (value == null) return null;
    if (value is! Map) _wrong(key, 'an object');
    return Map<String, Object?>.from(value);
  }

  /// The string value of [key] when it is one of [allowed].
  String choice(String key, List<String> allowed, {String? defaultValue}) {
    final value = optString(key) ?? defaultValue;
    if (value == null) {
      throw StoryError.validation('Argument "$key" is required.');
    }
    if (!allowed.contains(value)) {
      _wrong(key, 'one of ${allowed.join(', ')}');
    }
    return value;
  }
}
