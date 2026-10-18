import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../icons/icon_ref.dart';
import '../theme/plotcraft_tokens.dart';
import 'plotcraft_button.dart';
import 'plotcraft_dialog.dart';
import 'plotcraft_text_field.dart';

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
  final _search = TextEditingController();
  late String _set;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _set = current != null && current.exists
        ? current.set
        : IconCatalog.sets.first;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final names = IconCatalog.search(_set, _search.text);
    return Column(
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
            for (final set in IconCatalog.sets)
              ChoiceChip(
                label: Text(IconCatalog.labelOf(set)),
                selected: set == _set,
                onSelected: (_) => setState(() => _set = set),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: names.isEmpty
              ? Center(child: Text('ui.icon_picker_empty'.tr()))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 48,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    final ref = IconRef(_set, names[index]);
                    final selected = ref == widget.current;
                    return Tooltip(
                      message: names[index].replaceAll('_', ' '),
                      waitDuration: const Duration(milliseconds: 300),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          PlotcraftRadii.control,
                        ),
                        onTap: () => widget.onSelected(ref),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected ? scheme.primaryContainer : null,
                            borderRadius: BorderRadius.circular(
                              PlotcraftRadii.control,
                            ),
                          ),
                          child: Icon(
                            ref.data,
                            size: 22,
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
