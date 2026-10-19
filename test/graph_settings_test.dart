import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft/features/project_workspace/domain/graph_layout.dart';
import 'package:plotcraft/features/project_workspace/domain/graph_settings.dart';
import 'package:plotcraft/features/project_workspace/domain/story_graph.dart';

StoryGraph _graph(int count) => StoryGraph(
  nodes: [
    for (var i = 0; i < count; i++)
      StoryGraphNode(
        id: 'n$i',
        kind: StoryGraphNodeKind.element,
        refId: 'n$i',
        label: 'N$i',
        typeId: 'character',
      ),
  ],
  edges: [
    for (var i = 1; i < count; i++)
      StoryGraphEdge(
        sourceId: 'n${i - 1}',
        targetId: 'n$i',
        kind: StoryGraphEdgeKind.relation,
      ),
  ],
);

void main() {
  group('GraphSettings', () {
    test('vai e volta no JSON', () {
      const settings = GraphSettings(
        linkDistance: 200,
        repulsion: 2.5,
        gravity: 0.5,
        nodeSize: 1.5,
        linkWidth: 2,
        labels: GraphLabels.always,
        showOrphans: false,
        showMentions: false,
        focusDepth: 2,
      );
      final back = GraphSettings.fromJson(settings.toJson());
      expect(back.toJson(), settings.toJson());
    });

    test('valores ausentes ou fora da faixa voltam ao padrão ou ao limite', () {
      final settings = GraphSettings.fromJson({
        'linkDistance': 99999,
        'repulsion': 'muito',
        'labels': 'desconhecido',
        'showOrphans': 'sim',
        'focusDepth': 9,
      });
      expect(settings.linkDistance, GraphSettings.ranges.linkDistance.$2);
      expect(settings.repulsion, 1);
      expect(settings.labels, GraphLabels.auto);
      expect(settings.showOrphans, isTrue);
      expect(settings.focusDepth, 3);
      expect(
        GraphSettings.fromJson(null).toJson(),
        const GraphSettings().toJson(),
      );
    });

    test('sameForces ignora o que só muda o desenho', () {
      const base = GraphSettings();
      expect(
        base.sameForces(base.copyWith(nodeSize: 2, showPhases: false)),
        isTrue,
      );
      expect(base.sameForces(base.copyWith(repulsion: 2)), isFalse);
    });
  });

  group('StoryGraph', () {
    test('reach segue as ligações até a profundidade pedida', () {
      final graph = _graph(5);
      expect(graph.reach('n0', 0), {'n0'});
      expect(graph.reach('n0', 2), {'n0', 'n1', 'n2'});
      expect(graph.reach('n2', 1), {'n1', 'n2', 'n3'});
      expect(graph.reach('n0', 9), hasLength(5));
    });

    test('whereEdges tira ligações e mantém os nós', () {
      final graph = _graph(3).whereEdges((e) => e.targetId != 'n2');
      expect(graph.nodes, hasLength(3));
      expect(graph.edges, hasLength(1));
    });
  });

  group('GraphLayout', () {
    double meanLinkLength(GraphLayout layout) {
      var total = 0.0;
      for (final e in layout.graph.edges) {
        final dx = layout.xOf(e.sourceId) - layout.xOf(e.targetId);
        final dy = layout.yOf(e.sourceId) - layout.yOf(e.targetId);
        total += math.sqrt(dx * dx + dy * dy);
      }
      return total / layout.graph.edges.length;
    }

    test('mais distância entre ligados abre o desenho', () {
      final graph = _graph(8);
      final near = GraphLayout(
        graph,
        settings: const GraphSettings(linkDistance: 60),
      )..settle(maxSteps: 600);
      final far = GraphLayout(
        graph,
        settings: const GraphSettings(linkDistance: 220),
      )..settle(maxSteps: 600);
      expect(meanLinkLength(far), greaterThan(meanLinkLength(near) * 1.5));
    });

    test('mais repulsão afasta os nós, mais gravidade aproxima do meio', () {
      final graph = _graph(8);
      final loose = GraphLayout(
        graph,
        settings: const GraphSettings(repulsion: 3, gravity: 0.2),
      )..settle(maxSteps: 600);
      final tight = GraphLayout(
        graph,
        settings: const GraphSettings(repulsion: 0.4, gravity: 3),
      )..settle(maxSteps: 600);
      double spread(GraphLayout l) {
        var m = 0.0;
        for (final n in l.graph.nodes) {
          m += math.sqrt(l.xOf(n.id) * l.xOf(n.id) + l.yOf(n.id) * l.yOf(n.id));
        }
        return m / l.graph.nodes.length;
      }

      expect(spread(loose), greaterThan(spread(tight)));
    });

    test('applySettings reaquece só quando as forças mudam', () {
      final layout = GraphLayout(_graph(4))..settle();
      expect(layout.settled, isTrue);
      layout.applySettings(const GraphSettings(nodeSize: 2));
      expect(layout.settled, isTrue);
      layout.applySettings(const GraphSettings(linkDistance: 200));
      expect(layout.settled, isFalse);
    });

    test('com todas as posições conhecidas o desenho volta parado', () {
      final graph = _graph(6);
      final first = GraphLayout(graph)..settle();
      final restored = GraphLayout(graph, previous: first.positions);
      expect(restored.settled, isTrue);
      expect(restored.positions, first.positions);
      restored.settle();
      expect(restored.positions, first.positions);
    });

    test('um nó novo nasce perto de quem está ligado a ele', () {
      final small = _graph(4);
      final first = GraphLayout(small)..settle();
      final bigger = _graph(5); // n4 is linked to n3
      final next = GraphLayout(bigger, previous: first.positions);
      expect(next.settled, isFalse);
      final dx = next.xOf('n4') - next.xOf('n3');
      final dy = next.yOf('n4') - next.yOf('n3');
      expect(math.sqrt(dx * dx + dy * dy), lessThan(200));
    });
  });
}
