import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../domain/book_content.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/narrative_element.dart';
import '../../domain/workspace_tab.dart';
import '../../stores/project_workspace_store.dart';
import '../../stores/workspace_controller.dart';
import 'element_draft.dart';
import 'element_items_panel.dart';
import 'element_references_panel.dart';
import 'element_type_label.dart';
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
  late final ElementDraft _draft;
  NarrativeElement? _element;
  bool _dirty = false;

  String get _tabId => widget.tab.id;

  /// Known before the first save so images can be attached to a new element.
  late final String _draftId = _newId();

  String get _elementId => _element?.id ?? _draftId;

  @override
  void initState() {
    super.initState();
    _element = widget.tab.isDraftElement
        ? null
        : widget.store.elements
              .where((element) => element.id == widget.tab.refId)
              .firstOrNull;
    _draft = ElementDraft(
      element: _element,
      typeId:
          widget.controller.draftTypeFor(_tabId) ??
          ElementTypeCatalog.character,
    );
    widget.controller.setGuard(_tabId, _confirmLeave);
  }

  @override
  void dispose() {
    widget.controller.setGuard(_tabId, null);
    _draft.dispose();
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
    if (_draft.title.text.trim().isEmpty) {
      _snack('elements.title_required');
      return false;
    }
    final element = _draft.build(id: _elementId, base: _element);
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

  Future<void> _editSection([int? index]) async {
    final current = index == null ? null : _draft.sections[index];
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
    final section = NarrativeSection(
      id: current?.id ?? _newId(),
      title: result.$1,
      markdown: result.$2,
    );
    setState(() {
      if (index == null) {
        _draft.sections.add(section);
      } else {
        _draft.sections[index] = section;
      }
    });
    _markDirty();
  }

  Future<void> _editPhase([int? index]) async {
    final current = index == null ? null : _draft.phases[index];
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
    final phase = NarrativePhase(
      id: current?.id ?? _newId(),
      title: result.$1,
      description: result.$2,
    );
    setState(() {
      if (index == null) {
        _draft.phases.add(phase);
      } else {
        _draft.phases[index] = phase;
      }
    });
    _markDirty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = widget.store.elementTypes;
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
                      controller: _draft.title,
                      onChanged: (_) => _markDirty(),
                      label: 'elements.name'.tr(),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: PlotcraftDropdown<String>(
                      initialValue: types.any((t) => t.id == _draft.typeId)
                          ? _draft.typeId
                          : null,
                      items: [
                        for (final type in types)
                          DropdownMenuItem(
                            value: type.id,
                            child: Row(
                              children: [
                                Icon(
                                  type.icon.data,
                                  size: 16,
                                  color: type.color,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    type.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        if (id == null) return;
                        setState(() => _draft.typeId = id);
                        _markDirty();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PlotcraftTextField(
                controller: _draft.summary,
                onChanged: (_) => _markDirty(),
                minLines: 3,
                maxLines: 6,
                label: 'elements.summary'.tr(),
              ),
              const SizedBox(height: 24),
              ElementItemsPanel(
                title: 'elements.sections'.tr(),
                emptyText: 'elements.no_sections'.tr(),
                items: [
                  for (final section in _draft.sections)
                    ElementItem(title: section.title, body: section.markdown),
                ],
                onAdd: _editSection,
                onEdit: _editSection,
                onRemove: (index) {
                  setState(() => _draft.sections.removeAt(index));
                  _markDirty();
                },
              ),
              const SizedBox(height: 20),
              ElementItemsPanel(
                title: 'elements.phases'.tr(),
                emptyText: 'elements.no_phases'.tr(),
                items: [
                  for (final phase in _draft.phases)
                    ElementItem(title: phase.title, body: phase.description),
                ],
                onAdd: _editPhase,
                onEdit: _editPhase,
                onRemove: (index) {
                  setState(() => _draft.phases.removeAt(index));
                  _markDirty();
                },
              ),
              if (_element != null) ...[
                const SizedBox(height: 24),
                ElementReferencesPanel(
                  elementId: _element!.id,
                  book: widget.book,
                  onOpen: widget.onOpenReference,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
