/// When something happens in the story's own world. The author writes it the
/// way the story tells it ("Year 312", "Summer of 1987", "three days before
/// the wedding") in [label]; the optional [position] is only a number used to
/// put things in order, so no real calendar is needed.
class StoryTime {
  const StoryTime({this.label = '', this.position});

  final String label;

  /// Sort key on the story's timeline: larger is later. Null means "not
  /// placed yet".
  final double? position;

  bool get isEmpty => label.trim().isEmpty && position == null;
  bool get isPlaced => position != null;

  /// What to show: the label, or the position when there is no label.
  String get display =>
      label.trim().isNotEmpty ? label.trim() : formatPosition(position);

  StoryTime copyWith({
    String? label,
    double? position,
    bool clearPosition = false,
  }) => StoryTime(
    label: label ?? this.label,
    position: clearPosition ? null : position ?? this.position,
  );

  /// A position without a useless ".0".
  static String formatPosition(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  Map<String, Object?> toJson() => {
    if (label.trim().isNotEmpty) 'label': label.trim(),
    if (position != null) 'position': position,
  };

  /// Anything unreadable, or empty, is "no time".
  static StoryTime? fromJson(Object? json) {
    if (json is! Map) return null;
    final label = json['label'];
    final position = json['position'];
    final time = StoryTime(
      label: label is String ? label : '',
      position: position is num && position.isFinite
          ? position.toDouble()
          : null,
    );
    return time.isEmpty ? null : time;
  }

  @override
  bool operator ==(Object other) =>
      other is StoryTime &&
      other.label.trim() == label.trim() &&
      other.position == position;

  @override
  int get hashCode => Object.hash(label.trim(), position);
}
