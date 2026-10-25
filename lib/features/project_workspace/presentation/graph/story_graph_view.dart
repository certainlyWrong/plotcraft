import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:plotcraft_core/features/project_workspace/domain/book_content.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type.dart';
import 'package:plotcraft_core/features/project_workspace/domain/element_type_catalog.dart';
import 'package:plotcraft_core/features/project_workspace/domain/narrative_element.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/mention_scan.dart';

import '../../../../core/icons/icon_data.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../domain/graph_layout.dart';
import '../../domain/graph_settings.dart';
import '../../domain/story_graph.dart';
import '../element_colors.dart';
import '../elements/element_type_label.dart';
import '../shell/workspace_icons.dart';
import '../../../../core/ui/plotcraft_choice.dart';
import '../../../../core/ui/plotcraft_chip.dart';
import '../../../../core/theme/plotcraft_tokens.dart';

/// Obsidian-like map of the story: elements (and the chapters where they are
/// written or where their phases begin) as nodes, relations as links. Drag a
/// node to move it, drag the background to pan, scroll or pinch to zoom,
/// double-click to open. The display options panel changes the forces, the
/// size of things and what is shown; the view is saved between sessions.
class StoryGraphView extends StatefulWidget {
  const StoryGraphView({
    super.key,
    required this.elements,
    required this.chapters,
    required this.types,
    this.presence = const [],
    required this.onOpenElement,
    required this.onOpenChapter,
    this.initialState,
    this.onStateChanged,
    this.fullscreen = false,
    this.onToggleFullscreen,
  });

  final List<NarrativeElement> elements;
  final List<BookChapter> chapters;
  final List<ElementType> types;

  /// Where each element is written, a chapter at a time.
  final List<ChapterPresence> presence;
  final ValueChanged<String> onOpenElement;
  final ValueChanged<String> onOpenChapter;

  /// What the view looked like last time (see [StoryGraphViewState.toJson]).
  final Map<String, Object?>? initialState;

  /// Called, a moment after each change, with what to save.
  final ValueChanged<Map<String, Object?>>? onStateChanged;
  final bool fullscreen;
  final VoidCallback? onToggleFullscreen;

  @override
  State<StoryGraphView> createState() => _StoryGraphViewState();
}

class _StoryGraphViewState extends State<StoryGraphView>
    with SingleTickerProviderStateMixin {
  static const _minScale = 0.2;
  static const _maxScale = 4.0;
  static const _doubleTap = Duration(milliseconds: 350);
  static const _saveDelay = Duration(milliseconds: 600);

  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Timer? _saveTimer;

  StoryGraph _full = StoryGraph.empty;
  StoryGraph _visible = StoryGraph.empty;
  GraphLayout _layout = GraphLayout(StoryGraph.empty);
  String _signature = '';

  /// Every position ever known, so a node that is hidden for a while comes
  /// back where it was.
  final _known = <String, ({double x, double y})>{};

  final _hiddenTypes = <String>{};
  bool _showChapters = true;
  GraphSettings _settings = const GraphSettings();
  bool _panelOpen = false;
  String _query = '';

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  bool _needsFit = true;

  String? _hover;
  String? _selected;
  String? _dragging;
  String? _lastTapNode;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  // Gesture start values for pan and zoom.
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    _restore(widget.initialState);
    _rebuild(force: true);
  }

  @override
  void didUpdateWidget(StoryGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuild();
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) _saveNow();
    _saveTimer?.cancel();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  // --- Saved view ---------------------------------------------------------

  void _restore(Map<String, Object?>? state) {
    if (state == null) return;
    final saved = StoryGraphViewState.fromJson(state);
    _settings = saved.settings;
    _hiddenTypes.addAll(saved.hiddenTypes);
    _showChapters = saved.showChapters;
    _known.addAll(saved.positions);
    if (saved.scale != null && saved.offset != null) {
      _scale = saved.scale!.clamp(_minScale, _maxScale);
      _offset = saved.offset!;
      _needsFit = false;
    }
  }

  void _scheduleSave() {
    if (widget.onStateChanged == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _saveNow);
  }

  void _saveNow() {
    final callback = widget.onStateChanged;
    if (callback == null) return;
    _known.addAll(_layout.positions);
    callback(
      StoryGraphViewState(
        scale: _scale,
        offset: _offset,
        hiddenTypes: _hiddenTypes,
        showChapters: _showChapters,
        settings: _settings,
        positions: _known,
      ).toJson(),
    );
  }

  // --- Data ---------------------------------------------------------------

  ElementType? _typeOf(String typeId) =>
      ElementTypeCatalog.resolve(typeId, widget.types);

  NarrativeElement? _elementOf(StoryGraphNode node) =>
      widget.elements.where((element) => element.id == node.refId).firstOrNull;

  /// Rebuilds the graph when what it shows has changed, keeping positions.
  void _rebuild({bool force = false}) {
    final full = StoryGraph.build(
      elements: widget.elements,
      chapters: widget.chapters,
      presence: widget.presence,
      types: widget.types,
    );
    final visible = _filtered(full);
    final signature = _signatureOf(visible);
    _full = full;
    if (!force && signature == _signature) return;
    _known.addAll(_layout.positions);
    _signature = signature;
    _visible = visible;
    final fresh = _known.isEmpty;
    _layout = GraphLayout(visible, previous: _known, settings: _settings);
    if (fresh) {
      _layout.settle(maxSteps: 160);
      _needsFit = true;
    }
    if (_selected != null && !visible.nodes.any((n) => n.id == _selected)) {
      _selected = null;
    }
    _wake();
    _scheduleSave();
  }

  StoryGraph _filtered(StoryGraph full) {
    var graph = full
        .where(
          (node) => switch (node.kind) {
            StoryGraphNodeKind.chapter => _showChapters,
            StoryGraphNodeKind.element => !_hiddenTypes.contains(node.typeId),
          },
        )
        .whereEdges(
          (edge) => switch (edge.kind) {
            StoryGraphEdgeKind.relation => _settings.showRelations,
            StoryGraphEdgeKind.mention => _settings.showMentions,
            StoryGraphEdgeKind.phase => _settings.showPhases,
            StoryGraphEdgeKind.reference => _settings.showDetails,
          },
        );
    final focus = _selected;
    if (_settings.focusDepth > 0 &&
        focus != null &&
        graph.nodes.any((n) => n.id == focus)) {
      final keep = graph.reach(focus, _settings.focusDepth);
      graph = graph.where((node) => keep.contains(node.id));
    }
    final degrees = graph.degrees;
    return graph.where(
      (node) =>
          node.id == focus ||
          (degrees[node.id] ?? 0) > 0 ||
          (node.kind == StoryGraphNodeKind.element && _settings.showOrphans),
    );
  }

  static String _signatureOf(StoryGraph graph) =>
      '${graph.nodes.map((n) => '${n.id}=${n.label}:${n.typeId}').join(',')}|'
      '${graph.edges.map((e) => '${e.sourceId}>${e.targetId}:${e.kind.name}:${e.label}').join(',')}';

  void _applyFilters() {
    setState(() => _rebuild(force: true));
  }

  void _setSettings(GraphSettings next) {
    final previous = _settings;
    setState(() {
      _settings = next;
      if (!previous.sameForces(next)) {
        _layout.applySettings(next);
        _wake();
      }
      final filtersChanged =
          previous.showOrphans != next.showOrphans ||
          previous.showRelations != next.showRelations ||
          previous.showMentions != next.showMentions ||
          previous.showPhases != next.showPhases ||
          previous.showDetails != next.showDetails ||
          previous.focusDepth != next.focusDepth;
      if (filtersChanged) _rebuild(force: true);
    });
    _frame.value++;
    _scheduleSave();
  }

  // --- Simulation ---------------------------------------------------------

  /// True while the layout is moving, so that its final resting place is
  /// saved once it stops (and nothing is saved when it never moved).
  bool _moving = false;

  void _wake() {
    if (!_layout.settled) _moving = true;
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    if (!_layout.step()) {
      _ticker.stop();
      if (_moving) {
        _moving = false;
        _scheduleSave();
      }
    }
    _frame.value++;
  }

  // --- Geometry -----------------------------------------------------------

  Offset _toWorld(Offset screen) => (screen - _offset) / _scale;

  double _radiusOf(String id, Map<String, int> degrees) =>
      (11 + math.min(15.0, 2.6 * math.sqrt((degrees[id] ?? 0).toDouble()))) *
      _settings.nodeSize;

  String? _hit(Offset screen) {
    final world = _toWorld(screen);
    final degrees = _visible.degrees;
    for (final node in _visible.nodes.reversed) {
      final center = Offset(_layout.xOf(node.id), _layout.yOf(node.id));
      final reach = _radiusOf(node.id, degrees) + 4 / _scale;
      if ((world - center).distance <= reach) return node.id;
    }
    return null;
  }

  void _fit() {
    if (_size.isEmpty || _visible.nodes.isEmpty) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final node in _visible.nodes) {
      final x = _layout.xOf(node.id), y = _layout.yOf(node.id);
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    const margin = 90.0;
    final width = math.max(maxX - minX, 1) + margin * 2;
    final height = math.max(maxY - minY, 1) + margin * 2;
    _scale = math
        .min(_size.width / width, _size.height / height)
        .clamp(_minScale, 1.4);
    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    _offset = Offset(_size.width / 2, _size.height / 2) - center * _scale;
    _needsFit = false;
  }

  void _zoomAt(Offset focal, double factor) {
    final world = _toWorld(focal);
    _scale = (_scale * factor).clamp(_minScale, _maxScale);
    _offset = focal - world * _scale;
    _frame.value++;
    _scheduleSave();
  }

  void _zoomCenter(double factor) =>
      _zoomAt(Offset(_size.width / 2, _size.height / 2), factor);

  // --- Gestures -----------------------------------------------------------

  void _onScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = details.localFocalPoint;
    _dragging = _hit(details.localFocalPoint);
    if (_dragging != null) {
      _selected = _dragging;
      final world = _toWorld(details.localFocalPoint);
      _layout.pin(_dragging!, world.dx, world.dy);
      _layout.reheat(0.3);
      _wake();
      setState(() {});
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final dragging = _dragging;
    if (dragging != null) {
      final world = _toWorld(details.localFocalPoint);
      _layout.pin(dragging, world.dx, world.dy);
      _layout.reheat(0.3);
      _wake();
      _frame.value++;
      return;
    }
    final world0 = (_startFocal - _startOffset) / _startScale;
    _scale = (_startScale * details.scale).clamp(_minScale, _maxScale);
    _offset = details.localFocalPoint - world0 * _scale;
    _frame.value++;
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final dragging = _dragging;
    if (dragging != null) _layout.unpin(dragging);
    _dragging = null;
    _scheduleSave();
  }

  void _onTapUp(TapUpDetails details) {
    final node = _hit(details.localPosition);
    final now = DateTime.now();
    if (node != null &&
        node == _lastTapNode &&
        now.difference(_lastTap) < _doubleTap) {
      _open(node);
      _lastTapNode = null;
    } else {
      _lastTapNode = node;
      _lastTap = now;
    }
    setState(() {
      _selected = node;
      // Focus mode follows the selection.
      if (_settings.focusDepth > 0) _rebuild(force: true);
    });
  }

  void _open(String nodeId) {
    final node = _visible.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;
    switch (node.kind) {
      case StoryGraphNodeKind.element:
        widget.onOpenElement(node.refId);
      case StoryGraphNodeKind.chapter:
        widget.onOpenChapter(node.refId);
    }
  }

  void _onHover(PointerHoverEvent event) {
    final node = _hit(event.localPosition);
    if (node != _hover) {
      setState(() => _hover = node);
    }
  }

  void _onSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _zoomAt(event.localPosition, math.exp(-event.scrollDelta.dy / 400));
    }
  }

  void _rearrange() {
    setState(() {
      _layout.scramble();
      _layout.settle(maxSteps: 160);
      _known.addAll(_layout.positions);
      _fit();
      _wake();
    });
    _frame.value++;
    _scheduleSave();
  }

  void _escape() {
    if (_panelOpen) {
      setState(() => _panelOpen = false);
    } else if (widget.fullscreen) {
      widget.onToggleFullscreen?.call();
    }
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_full.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              WorkspaceIcons.graph,
              size: 38,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'workspace.graph_empty'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _escape,
        for (final meta in const [true, false]) ...{
          SingleActivator(
            LogicalKeyboardKey.equal,
            meta: meta,
            control: !meta,
          ): () =>
              _zoomCenter(1.25),
          SingleActivator(
            LogicalKeyboardKey.minus,
            meta: meta,
            control: !meta,
          ): () =>
              _zoomCenter(0.8),
          SingleActivator(
            LogicalKeyboardKey.digit0,
            meta: meta,
            control: !meta,
          ): () => setState(() {
            _fit();
            _frame.value++;
            _scheduleSave();
          }),
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _controls(context),
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    if (size != _size) {
                      _size = size;
                      if (_needsFit) _fit();
                    }
                    return Stack(
                      children: [
                        Positioned.fill(child: _canvas(context)),
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: _legend(context),
                        ),
                        if (_selected != null)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: _selectionCard(context),
                          ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _toolCluster(context),
                        ),
                        if (_panelOpen)
                          Positioned(
                            top: 12,
                            right: 64,
                            width: 300,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: math.max(160, size.height - 24),
                              ),
                              child: _settingsPanel(context),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _canvas(BuildContext context) {
    final theme = Theme.of(context);
    return Listener(
      onPointerSignal: _onSignal,
      child: MouseRegion(
        onHover: _onHover,
        onExit: (_) {
          if (_hover != null) setState(() => _hover = null);
        },
        cursor: _hover != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: _onTapUp,
          child: CustomPaint(
            painter: _GraphPainter(this, theme, context.tokens.ink),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = <String, int>{};
    for (final node in _full.nodes) {
      if (node.typeId != null) {
        counts[node.typeId!] = (counts[node.typeId!] ?? 0) + 1;
      }
    }
    final hasChapters = _full.nodes.any(
      (n) => n.kind == StoryGraphNodeKind.chapter,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              onChanged: (value) => setState(() {
                _query = value.trim();
                _frame.value++;
              }),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'workspace.graph_search'.tr(),
                prefixIcon: const Icon(Feather.search, size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
              ),
            ),
          ),
          for (final entry in counts.entries)
            _typeChip(context, entry.key, entry.value),
          if (hasChapters)
            PlotcraftChip(
              icon: WorkspaceIcons.manuscript,
              label: 'workspace.graph_chapters'.tr(),
              selected: _showChapters,
              onTap: () {
                _showChapters = !_showChapters;
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _typeChip(BuildContext context, String typeId, int count) {
    final type = _typeOf(typeId);
    final color = type?.color ?? Theme.of(context).colorScheme.primary;
    final shown = !_hiddenTypes.contains(typeId);
    return PlotcraftChip(
      icon: (type?.icon ?? IconRef.fallback).data,
      iconColor: shown ? color : Theme.of(context).colorScheme.outline,
      label: '${type?.label ?? typeId} · $count',
      selected: shown,
      onTap: () {
        if (!shown) {
          _hiddenTypes.remove(typeId);
        } else {
          _hiddenTypes.add(typeId);
        }
        _applyFilters();
      },
    );
  }

  /// Display options, zoom and full screen, in a small column over the map.
  Widget _toolCluster(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tool(
      IconData icon,
      String tooltip,
      VoidCallback onPressed, {
      bool on = false,
    }) => Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        style: on
            ? IconButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
              )
            : null,
        icon: Icon(icon, size: 18),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tool(
            Feather.sliders,
            'workspace.graph_display'.tr(),
            () => setState(() => _panelOpen = !_panelOpen),
            on: _panelOpen,
          ),
          tool(Feather.plus, 'workspace.zoom_in'.tr(), () => _zoomCenter(1.25)),
          tool(
            Feather.minus,
            'workspace.zoom_out'.tr(),
            () => _zoomCenter(0.8),
          ),
          tool(Feather.maximize, 'workspace.graph_fit'.tr(), () {
            setState(_fit);
            _frame.value++;
            _scheduleSave();
          }),
          if (widget.onToggleFullscreen != null)
            tool(
              widget.fullscreen ? Feather.minimize_2 : Feather.maximize_2,
              widget.fullscreen
                  ? 'book.exit_fullscreen'.tr()
                  : 'book.fullscreen'.tr(),
              widget.onToggleFullscreen!,
            ),
        ],
      ),
    );
  }

  Widget _settingsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const ranges = GraphSettings.ranges;

    Widget heading(String key) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        key.tr(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );

    Widget slider(
      String key,
      double value,
      (double, double) range,
      ValueChanged<double> onChanged,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key.tr(), style: theme.textTheme.bodySmall),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.clamp(range.$1, range.$2),
            min: range.$1,
            max: range.$2,
            onChanged: onChanged,
          ),
        ),
      ],
    );

    Widget toggle(String key, bool value, ValueChanged<bool> onChanged) =>
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(key.tr(), style: theme.textTheme.bodyMedium),
          value: value,
          onChanged: onChanged,
        );

    final s = _settings;
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        // The panel scrolls (wheel, trackpad, drag) without drawing a bar.
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'workspace.graph_display'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _panelOpen = false),
                      icon: const Icon(Feather.x, size: 16),
                    ),
                  ],
                ),
                heading('workspace.graph_forces'),
                slider(
                  'workspace.graph_link_distance',
                  s.linkDistance,
                  ranges.linkDistance,
                  (v) => _setSettings(s.copyWith(linkDistance: v)),
                ),
                slider(
                  'workspace.graph_repulsion',
                  s.repulsion,
                  ranges.repulsion,
                  (v) => _setSettings(s.copyWith(repulsion: v)),
                ),
                slider(
                  'workspace.graph_gravity',
                  s.gravity,
                  ranges.gravity,
                  (v) => _setSettings(s.copyWith(gravity: v)),
                ),
                heading('workspace.graph_appearance'),
                slider(
                  'workspace.graph_node_size',
                  s.nodeSize,
                  ranges.nodeSize,
                  (v) => _setSettings(s.copyWith(nodeSize: v)),
                ),
                slider(
                  'workspace.graph_link_width',
                  s.linkWidth,
                  ranges.linkWidth,
                  (v) => _setSettings(s.copyWith(linkWidth: v)),
                ),
                const SizedBox(height: 4),
                Text(
                  'workspace.graph_labels'.tr(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                PlotcraftChoice<GraphLabels>(
                  options: [
                    PlotcraftChoiceOption(
                      value: GraphLabels.auto,
                      label: 'workspace.graph_labels_auto'.tr(),
                    ),
                    PlotcraftChoiceOption(
                      value: GraphLabels.always,
                      label: 'workspace.graph_labels_always'.tr(),
                    ),
                    PlotcraftChoiceOption(
                      value: GraphLabels.never,
                      label: 'workspace.graph_labels_never'.tr(),
                    ),
                  ],
                  selected: s.labels,
                  onChanged: (v) => _setSettings(s.copyWith(labels: v)),
                ),
                heading('workspace.graph_show'),
                toggle(
                  'workspace.graph_show_orphans',
                  s.showOrphans,
                  (v) => _setSettings(s.copyWith(showOrphans: v)),
                ),
                toggle(
                  'workspace.graph_show_relations',
                  s.showRelations,
                  (v) => _setSettings(s.copyWith(showRelations: v)),
                ),
                toggle(
                  'workspace.graph_show_mentions',
                  s.showMentions,
                  (v) => _setSettings(s.copyWith(showMentions: v)),
                ),
                toggle(
                  'workspace.graph_show_phases',
                  s.showPhases,
                  (v) => _setSettings(s.copyWith(showPhases: v)),
                ),
                toggle(
                  'workspace.graph_show_details',
                  s.showDetails,
                  (v) => _setSettings(s.copyWith(showDetails: v)),
                ),
                heading('workspace.graph_focus'),
                Text(
                  'workspace.graph_focus_hint'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                PlotcraftChoice<int>(
                  options: [
                    PlotcraftChoiceOption(
                      value: 0,
                      label: 'workspace.graph_focus_all'.tr(),
                    ),
                    const PlotcraftChoiceOption(value: 1, label: '1'),
                    const PlotcraftChoiceOption(value: 2, label: '2'),
                    const PlotcraftChoiceOption(value: 3, label: '3'),
                  ],
                  selected: s.focusDepth,
                  onChanged: (v) => _setSettings(s.copyWith(focusDepth: v)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlotcraftButton(
                      icon: Feather.shuffle,
                      label: 'workspace.graph_rearrange'.tr(),
                      variant: PlotcraftButtonVariant.secondary,
                      onPressed: _rearrange,
                    ),
                    PlotcraftButton(
                      icon: Feather.rotate_ccw,
                      label: 'workspace.graph_reset'.tr(),
                      variant: PlotcraftButtonVariant.text,
                      onPressed: () => _setSettings(const GraphSettings()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    Widget line(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 8),
        Text(text, style: style),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(
            Container(width: 22, height: 2, color: scheme.outline),
            'workspace.graph_legend_relation'.tr(),
          ),
          if (_visible.edges.any(
            (e) => e.kind == StoryGraphEdgeKind.mention,
          )) ...[
            const SizedBox(height: 4),
            line(
              Container(width: 22, height: 1, color: scheme.outline),
              'workspace.graph_legend_mention'.tr(),
            ),
          ],
          if (_visible.edges.any(
            (e) => e.kind == StoryGraphEdgeKind.phase,
          )) ...[
            const SizedBox(height: 4),
            line(
              Text('- - -', style: style),
              'workspace.graph_legend_phase'.tr(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _selectionCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final node = _visible.nodes.where((n) => n.id == _selected).firstOrNull;
    if (node == null) return const SizedBox.shrink();
    final isElement = node.kind == StoryGraphNodeKind.element;
    final type = isElement ? _typeOf(node.typeId ?? '') : null;
    final links = _visible.neighbors(node.id).length;
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${isElement ? (type?.label ?? '') : 'workspace.graph_chapter'.tr()}'
            ' · $links ${'workspace.graph_links'.tr()}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: PlotcraftButton(
              icon: Feather.arrow_right,
              label: 'workspace.graph_open'.tr(),
              variant: PlotcraftButtonVariant.secondary,
              onPressed: () => _open(node.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// What is saved of the map between sessions: where the view is, the filters,
/// the display options and the position of every node.
class StoryGraphViewState {
  const StoryGraphViewState({
    this.scale,
    this.offset,
    this.hiddenTypes = const {},
    this.showChapters = true,
    this.settings = const GraphSettings(),
    this.positions = const {},
  });

  final double? scale;
  final Offset? offset;
  final Set<String> hiddenTypes;
  final bool showChapters;
  final GraphSettings settings;
  final Map<String, ({double x, double y})> positions;

  Map<String, Object?> toJson() => {
    if (scale != null) 'scale': scale,
    if (offset != null) 'offsetX': offset!.dx,
    if (offset != null) 'offsetY': offset!.dy,
    'hiddenTypes': hiddenTypes.toList(),
    'showChapters': showChapters,
    'settings': settings.toJson(),
    'positions': {
      for (final entry in positions.entries)
        entry.key: [entry.value.x, entry.value.y],
    },
  };

  /// Anything unreadable is ignored, so a damaged file never breaks the map.
  factory StoryGraphViewState.fromJson(Map<String, Object?> json) {
    double? number(Object? value) =>
        value is num && value.isFinite ? value.toDouble() : null;
    final positions = <String, ({double x, double y})>{};
    final raw = json['positions'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! List || value.length != 2) {
          continue;
        }
        final x = number(value[0]), y = number(value[1]);
        if (x != null && y != null) {
          positions[entry.key as String] = (x: x, y: y);
        }
      }
    }
    final ox = number(json['offsetX']), oy = number(json['offsetY']);
    return StoryGraphViewState(
      scale: number(json['scale']),
      offset: ox != null && oy != null ? Offset(ox, oy) : null,
      hiddenTypes: {
        for (final id in (json['hiddenTypes'] as List? ?? const []))
          if (id is String) id,
      },
      showChapters: json['showChapters'] is bool
          ? json['showChapters'] as bool
          : true,
      settings: GraphSettings.fromJson(json['settings']),
      positions: positions,
    );
  }
}

/// Draws links, then nodes, then labels. Text is laid out once per string and
/// cached, and drawn at a constant size on screen whatever the zoom.
class _GraphPainter extends CustomPainter {
  _GraphPainter(this.state, this.theme, this.ink)
    : super(repaint: state._frame);

  final _StoryGraphViewState state;
  final ThemeData theme;

  /// Ink of the current stage: the lines, rings and labels of the map.
  final Color ink;

  static final _text = <String, TextPainter>{};

  TextPainter _paragraph(
    String text,
    TextStyle style, {
    double maxWidth = 160,
  }) {
    // Text drawn here (names, link labels) uses the theme's font, like the
    // rest of the interface; icon glyphs bring their own family.
    final family = style.fontFamily ?? theme.textTheme.bodyMedium?.fontFamily;
    final styled = style.fontFamily == null
        ? style.copyWith(fontFamily: family)
        : style;
    final key =
        '${style.color?.toARGB32()}|${style.fontSize}|${style.fontWeight}|'
        '$family|$maxWidth|$text';
    return _text.putIfAbsent(key, () {
      if (_text.length > 600) _text.clear();
      return TextPainter(
        text: TextSpan(text: text, style: styled),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scheme = theme.colorScheme;
    final layout = state._layout;
    final graph = state._visible;
    final scale = state._scale;
    final settings = state._settings;
    final degrees = graph.degrees;
    final focusId = state._hover ?? state._selected;
    final focusSet = focusId == null
        ? null
        : {focusId, ...graph.neighbors(focusId)};
    final query = state._query.toLowerCase();
    final matches = query.isEmpty
        ? null
        : {
            for (final node in graph.nodes)
              if (node.label.toLowerCase().contains(query)) node.id,
          };

    bool dimmed(String id) {
      if (matches != null) return !matches.contains(id);
      if (focusSet != null) return !focusSet.contains(id);
      return false;
    }

    canvas
      ..save()
      ..translate(state._offset.dx, state._offset.dy)
      ..scale(scale);

    // Links.
    for (final edge in graph.edges) {
      final a = Offset(layout.xOf(edge.sourceId), layout.yOf(edge.sourceId));
      final b = Offset(layout.xOf(edge.targetId), layout.yOf(edge.targetId));
      final active = focusId != null && edge.touches(focusId);
      final faded = matches != null
          ? !(matches.contains(edge.sourceId) &&
                matches.contains(edge.targetId))
          : focusId != null && !active;
      final base =
          (active ? 2.2 : 1.3) +
          (edge.kind == StoryGraphEdgeKind.mention
              ? math.min(2.5, 0.35 * (edge.weight - 1))
              : 0);
      final paint = Paint()
        ..color = active ? ink : ink.withValues(alpha: faded ? 0.10 : 0.38)
        ..strokeWidth = base * settings.linkWidth / scale
        ..style = PaintingStyle.stroke;
      if (edge.kind == StoryGraphEdgeKind.phase) {
        _dashed(canvas, a, b, paint, 7 / scale, 5 / scale);
      } else {
        canvas.drawLine(a, b, paint);
      }
    }

    // Nodes.
    for (final node in graph.nodes) {
      final center = Offset(layout.xOf(node.id), layout.yOf(node.id));
      final radius = state._radiusOf(node.id, degrees);
      final isChapter = node.kind == StoryGraphNodeKind.chapter;
      final element = isChapter ? null : state._elementOf(node);
      final type = isChapter ? null : state._typeOf(node.typeId ?? '');
      final color = isChapter ? ink : (element?.color ?? type?.color ?? ink);
      final icon = isChapter
          ? WorkspaceIcons.manuscript
          : ((element?.icon ?? type?.icon) ?? IconRef.fallback).data;
      final fade = dimmed(node.id) ? 0.22 : 1.0;
      final selected = node.id == state._selected;

      // A drop of pigment: a soft halo bleeding past the edge (only on maps of
      // a reasonable size, since a blur per node is not free), the body, and a
      // finer ring of ink where the colour pooled.
      if (graph.nodes.length <= 150) {
        canvas.drawCircle(
          center,
          radius * 1.18,
          Paint()
            ..color = color.withValues(alpha: 0.35 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .3),
        );
      }
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: 0.86 * fade),
      );
      canvas.drawCircle(
        center,
        radius - .6 / scale,
        Paint()
          ..color = Color.lerp(
            color,
            Colors.black,
            .25,
          )!.withValues(alpha: 0.5 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 / scale,
      );
      if (selected || node.id == focusId) {
        canvas.drawCircle(
          center,
          radius + 4 / scale,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 / scale,
        );
      }

      // Icon: laid out at 16 and scaled to the node.
      final onColor =
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black87;
      final glyph = _paragraph(
        String.fromCharCode(icon.codePoint),
        TextStyle(
          fontSize: 16,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: onColor.withValues(alpha: fade),
        ),
        maxWidth: 40,
      );
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(radius * 1.05 / 16)
        ..translate(-glyph.width / 2, -glyph.height / 2);
      glyph.paint(canvas, Offset.zero);
      canvas.restore();

      // Label, at a constant on-screen size.
      final inFocus = (focusSet?.contains(node.id) ?? false) || selected;
      final showLabel = switch (settings.labels) {
        GraphLabels.always => true,
        GraphLabels.never => node.id == focusId || selected,
        GraphLabels.auto => scale >= 0.55 || inFocus,
      };
      if (showLabel && fade > 0.5) {
        final label = _paragraph(
          node.label,
          TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: fade),
          ),
        );
        canvas
          ..save()
          ..translate(center.dx, center.dy + radius + 4)
          ..scale(1 / scale)
          ..translate(-label.width / 2, 0);
        label.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // Label of the links around the focused node.
    if (focusId != null) {
      for (final edge in graph.edges) {
        final mention = edge.kind == StoryGraphEdgeKind.mention;
        final fieldLabel = edge.labelKey != null
            ? edge.labelKey!.tr()
            : edge.label;
        if (!edge.touches(focusId) || (fieldLabel.isEmpty && !mention)) {
          continue;
        }
        final a = Offset(layout.xOf(edge.sourceId), layout.yOf(edge.sourceId));
        final b = Offset(layout.xOf(edge.targetId), layout.yOf(edge.targetId));
        final text = mention
            ? '${edge.weight}×'
            : edge.targetId == focusId && edge.reciprocalLabel.isNotEmpty
            ? edge.reciprocalLabel
            : fieldLabel;
        final para = _paragraph(
          text,
          TextStyle(fontSize: 11, color: scheme.onSurface),
          maxWidth: 140,
        );
        final mid = (a + b) / 2;
        canvas
          ..save()
          ..translate(mid.dx, mid.dy)
          ..scale(1 / scale);
        final box = Rect.fromCenter(
          center: Offset.zero,
          width: para.width + 12,
          height: para.height + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(8)),
          Paint()
            ..color = Color.alphaBlend(
              ink.withValues(alpha: .22),
              scheme.surfaceContainer,
            ),
        );
        para.paint(canvas, Offset(-para.width / 2, -para.height / 2));
        canvas.restore();
      }
    }

    canvas.restore();
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double dash,
    double gap,
  ) {
    final length = (b - a).distance;
    if (length == 0) return;
    final direction = (b - a) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      canvas.drawLine(
        a + direction * d,
        a + direction * math.min(d + dash, length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) => true;
}
