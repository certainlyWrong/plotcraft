import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../ui/components/plotcraft_button.dart';
import '../../../../ui/components/plotcraft_dialog.dart';
import '../../../../ui/components/plotcraft_icon_button.dart';
import '../../../../ui/components/plotcraft_text_field.dart';
import '../../domain/book_content.dart';
import '../../domain/markdown_extensions.dart';
import '../../domain/narrative_element.dart';
import '../../stores/project_workspace_store.dart';

class NarrativeWorkspace extends StatefulWidget {
  const NarrativeWorkspace({
    super.key,
    required this.store,
    required this.book,
    required this.initialElementId,
    required this.onOpenReference,
  });

  final ProjectWorkspaceStore store;
  final BookContent book;
  final String? initialElementId;
  final ValueChanged<String?> onOpenReference;

  @override
  State<NarrativeWorkspace> createState() => NarrativeWorkspaceState();
}

class NarrativeWorkspaceState extends State<NarrativeWorkspace> {
  final _title = TextEditingController();
  final _kind = TextEditingController();
  final _summary = TextEditingController();
  NarrativeElement? _selected;
  List<NarrativeSection> _sections = [];
  List<NarrativePhase> _phases = [];
  bool _dirty = false;
  bool _new = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.store.elements
        .where((element) => element.id == widget.initialElementId)
        .firstOrNull;
    _load(selected ?? widget.store.elements.firstOrNull, notify: false);
  }

  @override
  void didUpdateWidget(covariant NarrativeWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialElementId != oldWidget.initialElementId &&
        widget.initialElementId != null) {
      final selected = widget.store.elements
          .where((element) => element.id == widget.initialElementId)
          .firstOrNull;
      if (selected != null) _load(selected, notify: false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _kind.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _load(NarrativeElement? element, {bool notify = true}) {
    _selected = element;
    _new = false;
    _title.text = element?.title ?? '';
    _kind.text = element?.kind ?? 'character';
    _summary.text = element?.summary ?? '';
    _sections = [...?element?.sections];
    _phases = [...?element?.phases];
    _dirty = false;
    if (notify && mounted) setState(() {});
  }

  Future<void> _create() async {
    if (!await confirmLeave() || !mounted) return;
    _load(null, notify: false);
    setState(() => _new = true);
  }

  Future<bool> confirmLeave() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => PlotcraftDialog(
        title: 'elements.unsaved_title'.tr(),
        content: Text('elements.unsaved_message'.tr()),
        actions: [
          PlotcraftButton(
            label: 'preferences.cancel'.tr(),
            variant: PlotcraftButtonVariant.text,
            onPressed: () => Navigator.pop(context, 'cancel'),
          ),
          PlotcraftButton(
            label: 'workspace.discard'.tr(),
            variant: PlotcraftButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, 'discard'),
          ),
          PlotcraftButton(
            label: 'workspace.save_project'.tr(),
            onPressed: () => Navigator.pop(context, 'save'),
          ),
        ],
      ),
    );
    if (choice == 'discard') return true;
    if (choice == 'save') return _save();
    return false;
  }

  Future<bool> _save() async {
    if (_title.text.trim().isEmpty || _kind.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('elements.title_required'.tr())));
      return false;
    }
    final now = DateTime.now();
    final element = NarrativeElement(
      id: _selected?.id ?? now.microsecondsSinceEpoch.toRadixString(36),
      kind: _kind.text.trim(),
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      sections: _sections,
      phases: _phases,
      createdAt: _selected?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await widget.store.saveElement(element);
      if (mounted) {
        setState(() {
          _selected = element;
          _new = false;
          _dirty = false;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('elements.save_error'.tr())));
      }
      return false;
    }
  }

  Future<void> _select(NarrativeElement element) async {
    if (!await confirmLeave() || !mounted) return;
    _load(element);
  }

  Future<void> _remove() async {
    final selected = _selected;
    if (selected == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'elements.remove_title'.tr(),
      message: 'elements.remove_message'.tr(),
      confirmLabel: 'elements.remove'.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.removeElement(selected.id);
      if (mounted) _load(widget.store.elements.firstOrNull);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('elements.remove_error'.tr())));
      }
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void _upsert<T>(List<T> items, T item, String Function(T) idOf) {
    final index = items.indexWhere((existing) => idOf(existing) == idOf(item));
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _dirty = true;
  }

  Future<void> _editSection([NarrativeSection? current]) async {
    final result = await _editTitleBody(
      heading: 'elements.section'.tr(),
      titleLabel: 'elements.section_title'.tr(),
      bodyLabel: 'elements.markdown_content'.tr(),
      title: current?.title ?? '',
      body: current?.markdown ?? '',
      width: 740,
      bodyHeight: 300,
    );
    if (result == null || !mounted) return;
    setState(
      () => _upsert(
        _sections,
        NarrativeSection(
          id: current?.id ?? _newId(),
          title: result.$1,
          markdown: result.$2,
        ),
        (item) => item.id,
      ),
    );
  }

  Future<void> _editPhase([NarrativePhase? current]) async {
    final result = await _editTitleBody(
      heading: 'elements.phase'.tr(),
      titleLabel: 'elements.phase_title'.tr(),
      bodyLabel: 'elements.phase_description'.tr(),
      title: current?.title ?? '',
      body: current?.description ?? '',
      width: 650,
      bodyHeight: 210,
    );
    if (result == null || !mounted) return;
    setState(
      () => _upsert(
        _phases,
        NarrativePhase(
          id: current?.id ?? _newId(),
          title: result.$1,
          description: result.$2,
        ),
        (item) => item.id,
      ),
    );
  }

  /// Dialog shared by sections and phases: a required title and a long text.
  Future<(String, String)?> _editTitleBody({
    required String heading,
    required String titleLabel,
    required String bodyLabel,
    required String title,
    required String body,
    required double width,
    required double bodyHeight,
  }) async {
    final titleController = TextEditingController(text: title);
    final bodyController = TextEditingController(text: body);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => PlotcraftDialog(
        title: heading,
        maxWidth: width,
        content: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlotcraftTextField(
                controller: titleController,
                label: titleLabel,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: bodyHeight,
                child: PlotcraftTextField(
                  controller: bodyController,
                  label: bodyLabel,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          PlotcraftButton(
            label: 'preferences.cancel'.tr(),
            variant: PlotcraftButtonVariant.text,
            onPressed: () => Navigator.pop(context),
          ),
          PlotcraftButton(
            label: 'workspace.save_project'.tr(),
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(context, (
                titleController.text.trim(),
                bodyController.text,
              ));
            },
          ),
        ],
      ),
    );
    titleController.dispose();
    bodyController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final list = _elementList(context);
      final detail = _detail(context);
      return constraints.maxWidth >= 800
          ? Row(
              children: [
                SizedBox(width: 260, child: list),
                Expanded(child: detail),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 180, child: list),
                Expanded(child: detail),
              ],
            );
    },
  );

  Widget _elementList(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'elements.title'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PlotcraftIconButton(
                  icon: Feather.plus,
                  tooltip: 'elements.new'.tr(),
                  onPressed: _create,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.store.elements.length,
              itemBuilder: (context, index) {
                final element = widget.store.elements[index];
                final selected = element.id == _selected?.id && !_new;
                return ListTile(
                  selected: selected,
                  dense: true,
                  leading: Icon(
                    element.kind == 'character'
                        ? Feather.user
                        : Feather.bookmark,
                    size: 17,
                  ),
                  title: Text(
                    element.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    element.kind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _select(element),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context) {
    if (_selected == null && !_new) {
      return Center(child: Text('elements.empty'.tr()));
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 46),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _new ? 'elements.new'.tr() : _selected!.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_selected != null)
                    PlotcraftIconButton(
                      icon: Feather.trash_2,
                      tooltip: 'elements.remove'.tr(),
                      onPressed: _remove,
                    ),
                  PlotcraftButton(
                    icon: Feather.save,
                    label: 'workspace.save_project'.tr(),
                    onPressed: widget.store.isElementSaving ? null : _save,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 280,
                    child: PlotcraftTextField(
                      controller: _title,
                      onChanged: (_) => setState(() => _dirty = true),
                      label: 'elements.name'.tr(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlotcraftTextField(
                      controller: _kind,
                      onChanged: (_) => setState(() => _dirty = true),
                      label: 'elements.kind'.tr(),
                      hint: 'elements.kind_hint'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PlotcraftTextField(
                controller: _summary,
                onChanged: (_) => setState(() => _dirty = true),
                minLines: 3,
                maxLines: 6,
                label: 'elements.summary'.tr(),
              ),
              const SizedBox(height: 28),
              _groupHeading(
                context,
                'elements.sections'.tr(),
                () => _editSection(),
              ),
              if (_sections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'elements.no_sections'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final section in _sections)
                _itemRow(
                  context,
                  section.title,
                  section.markdown,
                  () => _editSection(section),
                  () => setState(() {
                    _sections.removeWhere((item) => item.id == section.id);
                    _dirty = true;
                  }),
                ),
              const SizedBox(height: 24),
              _groupHeading(
                context,
                'elements.phases'.tr(),
                () => _editPhase(),
              ),
              if (_phases.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'elements.no_phases'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final phase in _phases)
                _itemRow(
                  context,
                  phase.title,
                  phase.description,
                  () => _editPhase(phase),
                  () => setState(() {
                    _phases.removeWhere((item) => item.id == phase.id);
                    _dirty = true;
                  }),
                ),
              if (_selected != null) ...[
                const SizedBox(height: 28),
                Text(
                  'elements.references'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._references(context, _selected!.id),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupHeading(BuildContext context, String title, VoidCallback add) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          PlotcraftButton(
            icon: Feather.plus,
            label: 'elements.add'.tr(),
            variant: PlotcraftButtonVariant.text,
            onPressed: add,
          ),
        ],
      );

  Widget _itemRow(
    BuildContext context,
    String title,
    String body,
    VoidCallback edit,
    VoidCallback remove,
  ) => Card(
    child: ListTile(
      title: Text(title),
      subtitle: body.trim().isEmpty
          ? null
          : Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: edit,
      trailing: PlotcraftIconButton(
        icon: Feather.x,
        tooltip: 'elements.remove'.tr(),
        onPressed: remove,
        size: 17,
      ),
    ),
  );

  List<Widget> _references(BuildContext context, String id) {
    final book = widget.book;
    final references = book.chaptersEnabled
        ? book.chapters
              .where(
                (chapter) => NarrativeLinkExtension.references(
                  book.chapterTexts[chapter.id] ?? '',
                  id,
                ),
              )
              .map((chapter) => (chapter.id, chapter.title))
              .toList()
        : NarrativeLinkExtension.references(book.singleText, id)
        ? <(String?, String)>[(null, 'workspace.manuscript'.tr())]
        : <(String?, String)>[];
    if (references.isEmpty) return [Text('elements.no_references'.tr())];
    return references
        .map(
          (reference) => ListTile(
            leading: const Icon(Feather.file_text, size: 17),
            title: Text(reference.$2),
            onTap: () => widget.onOpenReference(reference.$1),
          ),
        )
        .toList();
  }
}
