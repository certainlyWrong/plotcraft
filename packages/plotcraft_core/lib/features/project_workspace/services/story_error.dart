/// Why an operation on a story was refused. The [code] is stable (callers
/// match on it); [message] and [hint] are written for a person or an AI.
enum StoryErrorCode {
  notFound,
  conflict,
  validation,
  confirmationRequired,
  readOnly,
}

class StoryError implements Exception {
  const StoryError(this.code, this.message, {this.hint});

  const StoryError.notFound(String what, {String? hint})
    : this(StoryErrorCode.notFound, '$what was not found.', hint: hint);

  const StoryError.validation(String message, {String? hint})
    : this(StoryErrorCode.validation, message, hint: hint);

  final StoryErrorCode code;
  final String message;
  final String? hint;

  @override
  String toString() => 'StoryError(${code.name}): $message';
}
