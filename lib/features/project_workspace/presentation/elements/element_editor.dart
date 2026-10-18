import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_chip_input.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/plotcraft_dropdown.dart';
import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';
import '../../../../core/icons/icon_ref.dart';
import '../../domain/book_content.dart';
import '../../domain/element_image.dart';
import '../../domain/element_relation.dart';
import '../../domain/element_type.dart';
import '../../domain/element_type_catalog.dart';
import '../../domain/narrative_anchor.dart';
import '../../domain/narrative_element.dart';
import '../../domain/workspace_tab.dart';
import '../../stores/project_workspace_store.dart';
import '../../stores/workspace_controller.dart';
import 'element_appearance_dialog.dart';
import 'element_draft.dart';
import 'element_images_panel.dart';
import 'element_fields_panel.dart';
import 'element_items_panel.dart';
import 'element_phase_dialog.dart';
import 'gallery_picker_dialog.dart';
import '../../domain/rich/mention_scan.dart';
import 'element_references_panel.dart';
import 'element_relations_panel.dart';
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
    required this.onOpenElement,
  });

  final WorkspaceTab tab;
  final ProjectWorkspaceStore store;
  final WorkspaceController controller;
  final BookContent book;
  final ValueChanged<NarrativeElement> onRemove;
  final void Function(String? chapterId, TextRange range) onOpenReference;
  final ValueChanged<String> onOpenElement;

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
    _scanOccurrences();
  }

  /// Where the element appears in the book. Scanning reads every chapter, so
  /// it runs when the book or the element changes, not on every keystroke.
  List<MentionOccurrence> _occurrences = const [];

  void _scanOccurrences() {
    final element = _element;
    _occurrences = element == null
        ? const []
        : scanElementMentions(
            widget.book,
            element,
            'workspace.manuscript'.tr(),
          );
  }

  @override
  void didUpdateWidget(covariant ElementEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) _scanOccurrences();
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
    // Relations to elements that no longer exist are dropped on save.
    final existing = {for (final e in widget.store.elements) e.id, _elementId};
    final built = _draft.build(id: _elementId, base: _element);
    final element = built.copyWith(
      relations: RelationIndex.prune(built, existing),
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
        _scanOccurrences();
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
    final type = ElementTypeCatalog.resolve(
      _draft.typeId,
      widget.store.elementTypes,
    );
    final phase = await showElementPhaseDialog(
      context,
      current: current,
      newId: _newId(),
      chapters: widget.book.chaptersEnabled ? widget.book.chapters : const [],
      fields: type?.fields ?? const [],
      images: _draft.images,
      resolvePath: _imagePath,
    );
    if (phase == null || !mounted) return;
    setState(() {
      if (index == null) {
        _draft.phases.add(phase);
      } else {
        _draft.phases[index] = phase;
      }
    });
    _markDirty();
  }

  /// Where a phase starts, as text for the list ("Chapter 2", a custom label).
  String? _anchorLabel(NarrativeAnchor anchor) => switch (anchor.kind) {
    NarrativeAnchorKind.none => null,
    NarrativeAnchorKind.manual => anchor.value,
    NarrativeAnchorKind.chapter =>
      widget.book.chapters
          .where((chapter) => chapter.id == anchor.value)
          .firstOrNull
          ?.title,
  };

  /// Whether the name and aliases are marked in the text, and which terms the
  /// writer asked to stop marking.
  Widget _mentionSettings(BuildContext context) {
    final policy = _draft.mentionPolicy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.mentions_section'.tr(),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('elements.auto_mentions'.tr()),
          value: policy.auto,
          onChanged: (on) {
            setState(() => _draft.mentionPolicy = policy.copyWith(auto: on));
            _markDirty();
          },
        ),
        if (policy.auto && policy.ignoredTerms.isNotEmpty)
          PlotcraftChipInput(
            label: 'elements.ignored_terms'.tr(),
            hint: 'elements.ignored_terms_hint'.tr(),
            values: policy.ignoredTerms,
            onChanged: (terms) {
              setState(
                () =>
                    _draft.mentionPolicy = policy.copyWith(ignoredTerms: terms),
              );
              _markDirty();
            },
          ),
      ],
    );
  }

  String? _imagePath(ElementImage image) {
    if (!image.isGallery) return widget.store.attachmentPath(image.value);
    final item = widget.store.galleryItems
        .where((item) => item.id == image.value)
        .firstOrNull;
    return item != null && item.exists ? item.path : null;
  }

  Future<void> _addFromGallery() async {
    final current = [
      for (final image in _draft.images)
        if (image.isGallery) image.value,
    ];
    final chosen = await showGalleryPicker(
      context,
      items: widget.store.galleryItems.toList(),
      selected: current,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      // Keep the order of images already in use and the ones from the
      // computer; append the newly chosen gallery images.
      _draft.images = [
        for (final image in _draft.images)
          if (!image.isGallery || chosen.contains(image.value)) image,
        for (final id in chosen)
          if (!current.contains(id)) ElementImage.gallery(id),
      ];
    });
    _markDirty();
  }

  Future<void> _addFromComputer() async {
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'workspace.image_files'.tr(),
            extensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
          ),
        ],
      );
      if (files.isEmpty) return;
      final added = <ElementImage>[];
      for (final file in files) {
        added.add(await widget.store.attachElementImage(_elementId, file.path));
      }
      if (!mounted) return;
      setState(() => _draft.images = [..._draft.images, ...added]);
      _markDirty();
    } catch (_) {
      _snack('elements.attach_error');
    }
  }

  Widget _appearanceButton(ElementType? type) {
    final icon = _draft.icon ?? type?.icon ?? IconRef.fallback;
    final color =
        _draft.color ?? type?.color ?? Theme.of(context).colorScheme.outline;
    return Tooltip(
      message: 'elements.appearance'.tr(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final result = await showElementAppearanceDialog(
            context,
            current: ElementAppearance(icon: _draft.icon, color: _draft.color),
            typeIcon: type?.icon ?? IconRef.fallback,
            typeColor: color,
          );
          if (result == null || !mounted) return;
          setState(() {
            _draft.icon = result.icon;
            _draft.color = result.color;
          });
          _markDirty();
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            shape: BoxShape.circle,
          ),
          child: Icon(icon.data, size: 24, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = widget.store.elementTypes;
    final type = ElementTypeCatalog.resolve(_draft.typeId, types);
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _appearanceButton(type),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Wrap(
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
                            initialValue:
                                types.any((t) => t.id == _draft.typeId)
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
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PlotcraftChipInput(
                      label: 'elements.aliases'.tr(),
                      hint: 'elements.aliases_hint'.tr(),
                      values: _draft.aliases,
                      onChanged: (values) {
                        setState(() => _draft.aliases = values);
                        _markDirty();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PlotcraftChipInput(
                      label: 'elements.tags'.tr(),
                      hint: 'elements.tags_hint'.tr(),
                      values: _draft.tags,
                      onChanged: (values) {
                        setState(() => _draft.tags = values);
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
              if (type != null && type.fields.isNotEmpty) ...[
                const SizedBox(height: 24),
                ElementFieldsPanel(
                  key: ValueKey(_draft.typeId),
                  type: type,
                  values: _draft.fieldValues,
                  otherElements: [
                    for (final other in widget.store.elements)
                      if (other.id != _elementId) other,
                  ],
                  onChanged: (id, value) {
                    _draft.fieldValues[id] = value;
                    _markDirty();
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElementImagesPanel(
                images: _draft.images,
                resolvePath: _imagePath,
                onAddFromGallery: _addFromGallery,
                onAddFromComputer: _addFromComputer,
                onRemove: (index) {
                  setState(() => _draft.images.removeAt(index));
                  _markDirty();
                },
                onMakeCover: (index) {
                  setState(() {
                    final image = _draft.images.removeAt(index);
                    _draft.images.insert(0, image);
                  });
                  _markDirty();
                },
              ),
              const SizedBox(height: 24),
              ElementRelationsPanel(
                relations: _draft.relations,
                candidates: [
                  for (final other in widget.store.elements)
                    if (other.id != _elementId) other,
                ],
                incoming: [
                  for (final view in RelationIndex(
                    widget.store.elements.toList(),
                  ).of(_elementId))
                    if (view.incoming) view,
                ],
                newId: _newId,
                onChanged: (relations) {
                  setState(() => _draft.relations = relations);
                  _markDirty();
                },
                onOpenElement: widget.onOpenElement,
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
                    ElementItem(
                      title: phase.title,
                      body: phase.description,
                      badge: _anchorLabel(phase.anchor),
                    ),
                ],
                onAdd: _editPhase,
                onEdit: _editPhase,
                onRemove: (index) {
                  setState(() => _draft.phases.removeAt(index));
                  _markDirty();
                },
              ),
              const SizedBox(height: 24),
              _mentionSettings(context),
              if (_element != null) ...[
                const SizedBox(height: 24),
                ElementReferencesPanel(
                  occurrences: _occurrences,
                  onOpen: (o) => widget.onOpenReference(
                    o.chapterId,
                    TextRange(start: o.start, end: o.end),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
