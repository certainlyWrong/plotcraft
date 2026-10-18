import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../icons/suggested_icons.dart';
import '../theme/plotcraft_tokens.dart';
import 'plotcraft_button.dart';
import 'plotcraft_dialog.dart';
import 'plotcraft_text_field.dart';
import '../icons/icon_data.dart';

/// Opens the icon picker and resolves to the chosen icon, or null if the
/// dialog is dismissed.
Future<IconRef?> showIconPicker(BuildContext context, {IconRef? current}) =>
    showDialog<IconRef>(
      context: context,
      builder: (dialogContext) => PlotcraftDialog(
        title: 'ui.icon_picker_title'.tr(),
        maxWidth: 720,
        content: SizedBox(
          width: 720,
          height: 440,
          child: PlotcraftIconPicker(
            current: current,
            onSelected: (ref) => Navigator.pop(dialogContext, ref),
          ),
        ),
        actions: [
          PlotcraftButton(
            label: 'preferences.cancel'.tr(),
            variant: PlotcraftButtonVariant.text,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );

/// Searchable grid of every icon in the catalog, grouped by set.
class PlotcraftIconPicker extends StatefulWidget {
  const PlotcraftIconPicker({
    super.key,
    required this.onSelected,
    this.current,
  });

  final IconRef? current;
  final ValueChanged<IconRef> onSelected;

  @override
  State<PlotcraftIconPicker> createState() => _PlotcraftIconPickerState();
}

class _PlotcraftIconPickerState extends State<PlotcraftIconPicker> {
  /// Pseudo-set of the hand-picked icons, shown before the real sets.
  static const _suggested = '';

  final _search = TextEditingController();
  late String _set;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _set = current != null && current.exists ? current.set : _suggested;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _cell(IconRef ref, String name) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref == widget.current;
    return Tooltip(
      message: name.replaceAll('_', ' '),
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        borderRadius: BorderRadius.circular(PlotcraftRadii.control),
        onTap: () => widget.onSelected(ref),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(PlotcraftRadii.control),
          ),
          child: Icon(
            ref.data,
            size: 22,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 48,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
  );

  /// The suggested icons, in titled groups; the search matches an icon's name
  /// or its group's title.
  Widget _suggestedBody() {
    final theme = Theme.of(context);
    final words = _search.text
        .toLowerCase()
        .split(RegExp(r'[\s_\-]+'))
        .where((word) => word.isNotEmpty);
    final children = <Widget>[];
    for (final group in suggestedIconGroups) {
      final title = 'ui.icon_groups.${group.id}'.tr();
      final icons = [
        for (final ref in group.icons)
          if (words.every(
            (word) =>
                ref.name.replaceAll('_', ' ').contains(word) ||
                title.toLowerCase().contains(word),
          ))
            ref,
      ];
      if (icons.isEmpty) continue;
      children
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
        ..add(
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _gridDelegate,
            itemCount: icons.length,
            itemBuilder: (context, index) =>
                _cell(icons[index], icons[index].name),
          ),
        );
    }
    if (children.isEmpty) {
      return Center(child: Text('ui.icon_picker_empty'.tr()));
    }
    return ListView(children: children);
  }

  Widget _setBody() {
    final names = IconCatalog.search(_set, _search.text);
    if (names.isEmpty) {
      return Center(child: Text('ui.icon_picker_empty'.tr()));
    }
    return GridView.builder(
      gridDelegate: _gridDelegate,
      itemCount: names.length,
      itemBuilder: (context, index) =>
          _cell(IconRef(_set, names[index]), names[index]),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PlotcraftTextField(
        controller: _search,
        autofocus: true,
        compact: true,
        hint: 'ui.icon_picker_search'.tr(),
        prefixIcon: const Icon(Feather.search, size: 16),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: Text('ui.icon_suggested'.tr()),
            selected: _set == _suggested,
            onSelected: (_) => setState(() => _set = _suggested),
          ),
          for (final set in IconCatalog.sets)
            ChoiceChip(
              label: Text(IconCatalog.labelOf(set)),
              selected: set == _set,
              onSelected: (_) => setState(() => _set = set),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Expanded(child: _set == _suggested ? _suggestedBody() : _setBody()),
    ],
  );
}
