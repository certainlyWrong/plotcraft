import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_icon_button.dart';
import '../../../../core/ui/plotcraft_text_field.dart';

class ProjectTopBar extends StatelessWidget {
  const ProjectTopBar({
    super.key,
    required this.title,
    required this.controller,
    required this.onSearch,
    required this.onPreferences,
  });

  final String title;
  final TextEditingController? controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (controller != null)
            SizedBox(
              width: 260,
              height: 32,
              child: PlotcraftTextField(
                controller: controller!,
                onChanged: onSearch,
                hint: 'home.search'.tr(),
                prefixIcon: const Icon(Feather.search, size: 16),
                compact: true,
              ),
            ),
          const SizedBox(width: 8),
          PlotcraftIconButton(
            icon: Feather.settings,
            tooltip: 'preferences.title'.tr(),
            onPressed: onPreferences,
            size: 18,
          ),
        ],
      ),
    );
  }
}
