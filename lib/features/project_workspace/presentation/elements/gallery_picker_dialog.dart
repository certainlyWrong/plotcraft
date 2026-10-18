import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/plotcraft_button.dart';
import '../../../../core/ui/plotcraft_dialog.dart';
import '../../../../core/ui/project_image.dart';
import '../../domain/gallery_item.dart';

/// Lets the person pick images from the project gallery. Resolves to the IDs
/// of the chosen images (those already used start selected), or null if
/// cancelled.
Future<List<String>?> showGalleryPicker(
  BuildContext context, {
  required List<GalleryItem> items,
  List<String> selected = const [],
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _GalleryPicker(items: items, selected: selected),
);

class _GalleryPicker extends StatefulWidget {
  const _GalleryPicker({required this.items, required this.selected});

  final List<GalleryItem> items;
  final List<String> selected;

  @override
  State<_GalleryPicker> createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<_GalleryPicker> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = widget.items.where((item) => item.exists).toList();
    return PlotcraftDialog(
      title: 'elements.pick_gallery_title'.tr(),
      maxWidth: 640,
      content: SizedBox(
        width: 640,
        height: available.length > 10 ? 380 : 260,
        child: available.isEmpty
            ? Center(child: Text('elements.gallery_empty_pick'.tr()))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 130,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: available.length,
                itemBuilder: (context, index) {
                  final item = available[index];
                  final chosen = _selected.contains(item.id);
                  return InkWell(
                    onTap: () => setState(
                      () => chosen
                          ? _selected.remove(item.id)
                          : _selected.add(item.id),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PlotcraftRadii.control,
                          ),
                          child: ProjectImage(item.path, cacheWidth: 300),
                        ),
                        if (chosen)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                PlotcraftRadii.control,
                              ),
                              border: Border.all(
                                color: scheme.primary,
                                width: 3,
                              ),
                              color: scheme.primary.withValues(alpha: .18),
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: 11,
                                  backgroundColor: scheme.primary,
                                  child: Icon(
                                    Feather.check,
                                    size: 14,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'ui.selected_count'.tr(
                namedArgs: {'count': '${_selected.length}'},
              ),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        PlotcraftButton(
          label: 'preferences.cancel'.tr(),
          variant: PlotcraftButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        PlotcraftButton(
          label: 'ui.save'.tr(),
          onPressed: () => Navigator.pop(context, _selected.toList()),
        ),
      ],
    );
  }
}
