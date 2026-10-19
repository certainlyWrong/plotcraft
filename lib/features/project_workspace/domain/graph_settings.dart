enum GraphLabels {
  /// Labels show when zoomed in enough, and for the focused node.
  auto,
  always,
  never,
}

/// How the map is drawn and laid out. Plain values so they can be saved with
/// the project's view state.
class GraphSettings {
  const GraphSettings({
    this.linkDistance = defaultLinkDistance,
    this.repulsion = 1,
    this.gravity = 1,
    this.nodeSize = 1,
    this.linkWidth = 1,
    this.labels = GraphLabels.auto,
    this.showOrphans = true,
    this.showRelations = true,
    this.showMentions = true,
    this.showPhases = true,
    this.showDetails = true,
    this.focusDepth = 0,
  });

  static const defaultLinkDistance = 110.0;

  /// How far apart linked nodes want to be.
  final double linkDistance;

  /// How strongly nodes push each other away (1 = normal).
  final double repulsion;

  /// How strongly nodes are pulled toward the middle (1 = normal).
  final double gravity;

  /// Multiplies the size of the nodes.
  final double nodeSize;

  /// Multiplies the thickness of the links.
  final double linkWidth;
  final GraphLabels labels;

  /// Elements with no link at all.
  final bool showOrphans;

  /// Which kinds of link are drawn.
  final bool showRelations;
  final bool showMentions;
  final bool showPhases;
  final bool showDetails;

  /// 0 shows the whole map; 1, 2, 3 show the selected node and what is that
  /// many links away from it.
  final int focusDepth;

  static const ranges = (
    linkDistance: (40.0, 320.0),
    repulsion: (0.2, 4.0),
    gravity: (0.0, 4.0),
    nodeSize: (0.5, 2.5),
    linkWidth: (0.5, 4.0),
  );

  GraphSettings copyWith({
    double? linkDistance,
    double? repulsion,
    double? gravity,
    double? nodeSize,
    double? linkWidth,
    GraphLabels? labels,
    bool? showOrphans,
    bool? showRelations,
    bool? showMentions,
    bool? showPhases,
    bool? showDetails,
    int? focusDepth,
  }) => GraphSettings(
    linkDistance: linkDistance ?? this.linkDistance,
    repulsion: repulsion ?? this.repulsion,
    gravity: gravity ?? this.gravity,
    nodeSize: nodeSize ?? this.nodeSize,
    linkWidth: linkWidth ?? this.linkWidth,
    labels: labels ?? this.labels,
    showOrphans: showOrphans ?? this.showOrphans,
    showRelations: showRelations ?? this.showRelations,
    showMentions: showMentions ?? this.showMentions,
    showPhases: showPhases ?? this.showPhases,
    showDetails: showDetails ?? this.showDetails,
    focusDepth: focusDepth ?? this.focusDepth,
  );

  /// The settings that change the layout (the others only change the picture).
  bool sameForces(GraphSettings other) =>
      other.linkDistance == linkDistance &&
      other.repulsion == repulsion &&
      other.gravity == gravity;

  Map<String, Object?> toJson() => {
    'linkDistance': linkDistance,
    'repulsion': repulsion,
    'gravity': gravity,
    'nodeSize': nodeSize,
    'linkWidth': linkWidth,
    'labels': labels.name,
    'showOrphans': showOrphans,
    'showRelations': showRelations,
    'showMentions': showMentions,
    'showPhases': showPhases,
    'showDetails': showDetails,
    'focusDepth': focusDepth,
  };

  /// Anything missing or out of range falls back to the default.
  factory GraphSettings.fromJson(Object? json) {
    if (json is! Map) return const GraphSettings();
    double number(String key, double fallback, (double, double) range) {
      final value = json[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(range.$1, range.$2)
          : fallback;
    }

    bool flag(String key) => json[key] is bool ? json[key] as bool : true;
    final depth = json['focusDepth'];
    return GraphSettings(
      linkDistance: number(
        'linkDistance',
        defaultLinkDistance,
        ranges.linkDistance,
      ),
      repulsion: number('repulsion', 1, ranges.repulsion),
      gravity: number('gravity', 1, ranges.gravity),
      nodeSize: number('nodeSize', 1, ranges.nodeSize),
      linkWidth: number('linkWidth', 1, ranges.linkWidth),
      labels: GraphLabels.values.firstWhere(
        (l) => l.name == json['labels'],
        orElse: () => GraphLabels.auto,
      ),
      showOrphans: flag('showOrphans'),
      showRelations: flag('showRelations'),
      showMentions: flag('showMentions'),
      showPhases: flag('showPhases'),
      showDetails: flag('showDetails'),
      focusDepth: depth is int ? depth.clamp(0, 3) : 0,
    );
  }
}
