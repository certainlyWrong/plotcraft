import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/book_content.dart';
import '../../domain/markdown_extensions.dart';
import '../../domain/narrative_element.dart';
import '../../domain/workspace_tab.dart';
import '../../stores/project_workspace_store.dart';
import '../../stores/workspace_controller.dart';
import 'title_body_dialog.dart';

/// Editor of one narrative element, shown in its own tab. A tab whose ID is a
/// draft creates a new element when saved.
class ElementEditor extends StatefulWidget {
  const ElementEditor({
    super.key,
    required this.tab,
    required this.store,
    required this.controller,
    required this.book,
    required this.onRemove,
    required this.onOpenReference,
  });

  final WorkspaceTab tab;
  final ProjectWorkspaceStore store;
  final WorkspaceController controller;
  final BookContent book;
  final ValueChanged<NarrativeElement> onRemove;
  final ValueChanged<String?> onOpenReference;

  @override
  State<ElementEditor> createState() => _ElementEditorState();
}

class _ElementEditorState extends State<ElementEditor> {
  final _title = TextEditingController();
  final _kind = TextEditingController();
  final _summary = TextEditingController();
  NarrativeElement? _element;
  List<NarrativeSection> _sections = [];
  List<NarrativePhase> _phases = [];
  bool _dirty = false;

  String get _tabId => widget.tab.id;

  @override
  void initState() {
    super.initState();
    _element = widget.tab.isDraftElement
        ? null
        : widget.store.elements
              .where((element) => element.id == widget.tab.refId)
              .firstOrNull;
    _title.text = _element?.title ?? '';
    _kind.text = _element?.kind ?? 'character';
    _summary.text = _element?.summary ?? '';
    _sections = [...?_element?.sections];
    _phases = [...?_element?.phases];
    widget.controller.setGuard(_tabId, _confirmLeave);
  }

  @override
  void dispose() {
    widget.controller.setGuard(_tabId, null);
    _title.dispose();
    _kind.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _markDirty() {
    setState(() => _dirty = true);
    widget.controller.setDirty(_tabId, true);
  }

  Future<bool> _confirmLeave() async {
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
      _snack('elements.title_required');
      return false;
    }
    final now = DateTime.now();
    final element = NarrativeElement(
      id: _element?.id ?? now.microsecondsSinceEpoch.toRadixString(36),
      kind: _kind.text.trim(),
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      sections: _sections,
      phases: _phases,
      createdAt: _element?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await widget.store.saveElement(element);
    } catch (_) {
      if (mounted) _snack('elements.save_error');
      return false;
    }
    widget.controller.setDirty(_tabId, false);
    if (widget.tab.isDraftElement) {
      // The editor is rebuilt for the saved element's tab.
      widget.controller.promoteDraft(_tabId, element.id);
    } else if (mounted) {
      setState(() {
        _element = element;
        _dirty = false;
      });
    }
    return true;
  }

  void _snack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(key.tr())));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  void _upsert<T>(List<T> items, T item, String Function(T) idOf) {
    final index = items.indexWhere((e) => idOf(e) == idOf(item));
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
  }

  Future<void> _editSection([NarrativeSection? current]) async {
    final result = await showTitleBodyDialog(
      context,
      heading: 'elements.section'.tr(),
      titleLabel: 'elements.section_title'.tr(),
      bodyLabel: 'elements.markdown_content'.tr(),
      title: current?.title ?? '',
      body: current?.markdown ?? '',
      width: 740,
      bodyHeight: 300,
    );
    if (result == null || !mounted) return;
    _upsert(
      _sections,
      NarrativeSection(
        id: current?.id ?? _newId(),
        title: result.$1,
        markdown: result.$2,
      ),
      (item) => item.id,
    );
    _markDirty();
  }

  Future<void> _editPhase([NarrativePhase? current]) async {
    final result = await showTitleBodyDialog(
      context,
      heading: 'elements.phase'.tr(),
      titleLabel: 'elements.phase_title'.tr(),
      bodyLabel: 'elements.phase_description'.tr(),
      title: current?.title ?? '',
      body: current?.description ?? '',
      width: 650,
      bodyHeight: 210,
    );
    if (result == null || !mounted) return;
    _upsert(
      _phases,
      NarrativePhase(
        id: current?.id ?? _newId(),
        title: result.$1,
        description: result.$2,
      ),
      (item) => item.id,
    );
    _markDirty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
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
                      _element?.title ?? 'elements.new'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_element != null)
                    PlotcraftIconButton(
                      icon: Feather.trash_2,
                      tooltip: 'elements.remove'.tr(),
                      onPressed: () => widget.onRemove(_element!),
                    ),
                  PlotcraftButton(
                    icon: Feather.save,
                    label: 'workspace.save_project'.tr(),
                    onPressed: widget.store.isElementSaving ? null : _save,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 280,
                    child: PlotcraftTextField(
                      controller: _title,
                      onChanged: (_) => _markDirty(),
                      label: 'elements.name'.tr(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlotcraftTextField(
                      controller: _kind,
                      onChanged: (_) => _markDirty(),
                      label: 'elements.kind'.tr(),
                      hint: 'elements.kind_hint'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PlotcraftTextField(
                controller: _summary,
                onChanged: (_) => _markDirty(),
                minLines: 3,
                maxLines: 6,
                label: 'elements.summary'.tr(),
              ),
              const SizedBox(height: 24),
              _groupHeading(
                context,
                'elements.sections'.tr(),
                () => _editSection(),
              ),
              if (_sections.isEmpty) _empty(context, 'elements.no_sections'),
              for (final section in _sections)
                _itemRow(
                  context,
                  section.title,
                  section.markdown,
                  () => _editSection(section),
                  () {
                    _sections.removeWhere((item) => item.id == section.id);
                    _markDirty();
                  },
                ),
              const SizedBox(height: 20),
              _groupHeading(
                context,
                'elements.phases'.tr(),
                () => _editPhase(),
              ),
              if (_phases.isEmpty) _empty(context, 'elements.no_phases'),
              for (final phase in _phases)
                _itemRow(
                  context,
                  phase.title,
                  phase.description,
                  () => _editPhase(phase),
                  () {
                    _phases.removeWhere((item) => item.id == phase.id);
                    _markDirty();
                  },
                ),
              if (_element != null) ...[
                const SizedBox(height: 24),
                Text(
                  'elements.references'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._references(context, _element!.id, scheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, String key) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      key.tr(),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

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

  List<Widget> _references(
    BuildContext context,
    String id,
    ColorScheme scheme,
  ) {
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
    return [
      for (final reference in references)
        ListTile(
          leading: const Icon(Feather.file_text, size: 17),
          title: Text(reference.$2),
          onTap: () => widget.onOpenReference(reference.$1),
        ),
    ];
  }
}
