import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';

/// Find and replace row shown under the toolbar.
class FindBar extends StatelessWidget {
  const FindBar({
    super.key,
    required this.find,
    required this.replace,
    required this.matchCount,
    required this.onFindNext,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
    required this.onQueryChanged,
  });

  final TextEditingController find;
  final TextEditingController replace;
  final int matchCount;
  final VoidCallback onFindNext;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: PlotcraftTextField(
              controller: find,
              compact: true,
              autofocus: true,
              hint: 'book.find'.tr(),
              onChanged: onQueryChanged,
              onSubmitted: (_) => onFindNext(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PlotcraftTextField(
              controller: replace,
              compact: true,
              hint: 'book.replace'.tr(),
              onSubmitted: (_) => onReplace(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              find.text.isEmpty
                  ? ''
                  : 'editor.matches'.tr(namedArgs: {'count': '$matchCount'}),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          PlotcraftIconButton(
            icon: Feather.arrow_down,
            tooltip: 'book.find_next'.tr(),
            onPressed: onFindNext,
          ),
          PlotcraftIconButton(
            icon: Feather.repeat,
            tooltip: 'book.replace_current'.tr(),
            onPressed: onReplace,
          ),
          PlotcraftIconButton(
            icon: Feather.layers,
            tooltip: 'editor.replace_all'.tr(),
            onPressed: onReplaceAll,
          ),
          PlotcraftIconButton(
            icon: Feather.x,
            tooltip: 'editor.close_find'.tr(),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
