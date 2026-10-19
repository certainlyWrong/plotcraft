import 'dart:math' as math;

import 'graph_settings.dart';
import 'story_graph.dart';

/// Force-directed layout (nodes repel, links pull, a weak gravity keeps the
/// map together) that cools down as it settles. Pure Dart: no Flutter.
class GraphLayout {
  /// [previous] holds positions already known (saved, or from the layout this
  /// one replaces). When it covers every node the picture is restored as it
  /// was and stays still; nodes it lacks start next to the nodes they are
  /// linked to and the layout moves a little to make room for them.
  GraphLayout(
    this.graph, {
    Map<String, ({double x, double y})>? previous,
    GraphSettings settings = const GraphSettings(),
  }) {
    linkDistance = settings.linkDistance;
    repulsion = settings.repulsion;
    gravity = settings.gravity;
    final count = graph.nodes.length;
    var missing = 0;
    for (var i = 0; i < count; i++) {
      final node = graph.nodes[i];
      final old = previous?[node.id];
      // A circle with a small deterministic offset, so equal graphs always
      // settle the same way.
      final angle = 2 * math.pi * i / math.max(count, 1);
      final radius = 40.0 + 12 * math.sqrt(count.toDouble());
      if (old == null) missing++;
      _x[node.id] = old?.x ?? math.cos(angle) * radius + (i % 7) * 1.7;
      _y[node.id] = old?.y ?? math.sin(angle) * radius + (i % 5) * 1.3;
      _vx[node.id] = 0;
      _vy[node.id] = 0;
    }
    if (previous != null && previous.isNotEmpty) {
      if (missing == 0) {
        alpha = 0;
      } else {
        _placeNewNearNeighbors(previous);
        alpha = 0.35;
      }
    }
  }

  void _placeNewNearNeighbors(Map<String, ({double x, double y})> previous) {
    var n = 0;
    for (final node in graph.nodes) {
      if (previous.containsKey(node.id)) continue;
      n++;
      final known = [
        for (final id in graph.neighbors(node.id))
          if (previous.containsKey(id)) previous[id]!,
      ];
      if (known.isEmpty) continue;
      final cx = known.fold(0.0, (sum, p) => sum + p.x) / known.length;
      final cy = known.fold(0.0, (sum, p) => sum + p.y) / known.length;
      final angle = n * 2.399963; // golden angle: neighbours spread out
      _x[node.id] = cx + math.cos(angle) * linkDistance * 0.8;
      _y[node.id] = cy + math.sin(angle) * linkDistance * 0.8;
    }
  }

  final StoryGraph graph;

  /// How far apart linked nodes want to be.
  double linkDistance = GraphSettings.defaultLinkDistance;

  /// Multipliers for the push between nodes and the pull to the middle.
  double repulsion = 1;
  double gravity = 1;

  /// Applies the forces of [settings]; heats the layout up when they changed.
  void applySettings(GraphSettings settings) {
    final changed =
        settings.linkDistance != linkDistance ||
        settings.repulsion != repulsion ||
        settings.gravity != gravity;
    linkDistance = settings.linkDistance;
    repulsion = settings.repulsion;
    gravity = settings.gravity;
    if (changed) reheat(0.7);
  }

  final _x = <String, double>{};
  final _y = <String, double>{};
  final _vx = <String, double>{};
  final _vy = <String, double>{};
  final _pinned = <String>{};

  /// 1 right after a change, fading to 0 as the layout settles.
  double alpha = 1;

  bool get settled => alpha < 0.02;

  double xOf(String id) => _x[id] ?? 0;
  double yOf(String id) => _y[id] ?? 0;

  Map<String, ({double x, double y})> get positions => {
    for (final node in graph.nodes) node.id: (x: xOf(node.id), y: yOf(node.id)),
  };

  /// Heats the simulation up again, for example after a node was moved.
  void reheat([double value = 0.5]) => alpha = math.max(alpha, value);

  void pin(String id, double x, double y) {
    if (!_x.containsKey(id)) return;
    _pinned.add(id);
    _x[id] = x;
    _y[id] = y;
    _vx[id] = 0;
    _vy[id] = 0;
  }

  void unpin(String id) => _pinned.remove(id);

  /// Moves every node to a fresh starting point and heats up the layout.
  void scramble() {
    final count = graph.nodes.length;
    for (var i = 0; i < count; i++) {
      final id = graph.nodes[i].id;
      final angle = 2 * math.pi * i / math.max(count, 1) + 0.5;
      final radius = 40.0 + 12 * math.sqrt(count.toDouble());
      _x[id] = math.cos(angle) * radius;
      _y[id] = math.sin(angle) * radius;
      _vx[id] = 0;
      _vy[id] = 0;
    }
    _pinned.clear();
    alpha = 1;
  }

  /// One simulation step; returns false once the layout has settled.
  bool step() {
    if (settled) return false;
    final nodes = graph.nodes;
    final n = nodes.length;
    // Repulsion between every pair.
    for (var i = 0; i < n; i++) {
      final a = nodes[i].id;
      for (var j = i + 1; j < n; j++) {
        final b = nodes[j].id;
        var dx = _x[a]! - _x[b]!;
        var dy = _y[a]! - _y[b]!;
        var d2 = dx * dx + dy * dy;
        if (d2 < 0.01) {
          dx = (i - j).isEven ? 0.1 : -0.1;
          dy = 0.1;
          d2 = 0.02;
        }
        final d = math.sqrt(d2);
        final force = 5200 * repulsion / d2 * alpha;
        final fx = dx / d * force;
        final fy = dy / d * force;
        _vx[a] = _vx[a]! + fx;
        _vy[a] = _vy[a]! + fy;
        _vx[b] = _vx[b]! - fx;
        _vy[b] = _vy[b]! - fy;
      }
    }
    // Links pull their ends toward the ideal length.
    for (final edge in graph.edges) {
      final a = edge.sourceId;
      final b = edge.targetId;
      if (!_x.containsKey(a) || !_x.containsKey(b)) continue;
      final dx = _x[b]! - _x[a]!;
      final dy = _y[b]! - _y[a]!;
      final d = math.max(math.sqrt(dx * dx + dy * dy), 0.1);
      final force = (d - linkDistance) * 0.06 * alpha;
      final fx = dx / d * force;
      final fy = dy / d * force;
      _vx[a] = _vx[a]! + fx;
      _vy[a] = _vy[a]! + fy;
      _vx[b] = _vx[b]! - fx;
      _vy[b] = _vy[b]! - fy;
    }
    // Gravity toward the origin, then move with friction.
    for (final node in nodes) {
      final id = node.id;
      if (_pinned.contains(id)) continue;
      _vx[id] = (_vx[id]! - _x[id]! * 0.012 * gravity * alpha) * 0.82;
      _vy[id] = (_vy[id]! - _y[id]! * 0.012 * gravity * alpha) * 0.82;
      _x[id] = _x[id]! + _vx[id]!.clamp(-40, 40);
      _y[id] = _y[id]! + _vy[id]!.clamp(-40, 40);
    }
    alpha *= 0.985;
    return true;
  }

  /// Runs the simulation to rest (used for the first picture and tests).
  void settle({int maxSteps = 400}) {
    for (var i = 0; i < maxSteps && step(); i++) {}
  }
}
