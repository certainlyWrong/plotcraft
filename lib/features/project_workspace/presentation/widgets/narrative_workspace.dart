import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

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
      builder: (context) => AlertDialog(
        title: Text('elements.unsaved_title'.tr()),
        content: Text('elements.unsaved_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text('preferences.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text('workspace.discard'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text('workspace.save_project'.tr()),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('elements.remove_title'.tr()),
        content: Text('elements.remove_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('preferences.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('elements.remove'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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

  Future<void> _editSection([NarrativeSection? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final markdown = TextEditingController(text: current?.markdown ?? '');
    final result = await showDialog<NarrativeSection>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'elements.section'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: 'elements.section_title'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: TextField(
                    controller: markdown,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: 'elements.markdown_content'.tr(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('preferences.cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (title.text.trim().isEmpty) return;
                        Navigator.pop(
                          context,
                          NarrativeSection(
                            id:
                                current?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toRadixString(36),
                            title: title.text.trim(),
                            markdown: markdown.text,
                          ),
                        );
                      },
                      child: Text('workspace.save_project'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    title.dispose();
    markdown.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final index = _sections.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _sections.add(result);
      } else {
        _sections[index] = result;
      }
      _dirty = true;
    });
  }

  Future<void> _editPhase([NarrativePhase? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final description = TextEditingController(text: current?.description ?? '');
    final result = await showDialog<NarrativePhase>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'elements.phase'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: 'elements.phase_title'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: TextField(
                    controller: description,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: 'elements.phase_description'.tr(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('preferences.cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (title.text.trim().isEmpty) return;
                        Navigator.pop(
                          context,
                          NarrativePhase(
                            id:
                                current?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toRadixString(36),
                            title: title.text.trim(),
                            description: description.text,
                          ),
                        );
                      },
                      child: Text('workspace.save_project'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final index = _phases.indexWhere((item) => item.id == result.id);
      if (index < 0) {
        _phases.add(result);
      } else {
        _phases[index] = result;
      }
      _dirty = true;
    });
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
                IconButton(
                  tooltip: 'elements.new'.tr(),
                  onPressed: _create,
                  icon: const Icon(Feather.plus),
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
                    IconButton(
                      tooltip: 'elements.remove'.tr(),
                      onPressed: _remove,
                      icon: const Icon(Feather.trash_2),
                    ),
                  FilledButton.icon(
                    onPressed: widget.store.isElementSaving ? null : _save,
                    icon: const Icon(Feather.save, size: 16),
                    label: Text('workspace.save_project'.tr()),
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
                    child: TextField(
                      controller: _title,
                      onChanged: (_) => setState(() => _dirty = true),
                      decoration: InputDecoration(
                        labelText: 'elements.name'.tr(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _kind,
                      onChanged: (_) => setState(() => _dirty = true),
                      decoration: InputDecoration(
                        labelText: 'elements.kind'.tr(),
                        hintText: 'elements.kind_hint'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _summary,
                onChanged: (_) => setState(() => _dirty = true),
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(labelText: 'elements.summary'.tr()),
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
          TextButton.icon(
            onPressed: add,
            icon: const Icon(Feather.plus, size: 16),
            label: Text('elements.add'.tr()),
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
      trailing: IconButton(
        tooltip: 'elements.remove'.tr(),
        onPressed: remove,
        icon: const Icon(Feather.x, size: 17),
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
