import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../ui/components/plotcraft_text_field.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final narrow = constraints.maxWidth < 460;
        return Container(
          height: 66,
          padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 34),
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
                Flexible(
                  fit: FlexFit.loose,
                  flex: 2,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: narrow
                          ? 128
                          : compact
                          ? 176
                          : 260,
                    ),
                    child: SizedBox(
                      height: 42,
                      child: PlotcraftTextField(
                        controller: controller!,
                        onChanged: onSearch,
                        hint: 'home.search'.tr(),
                        prefixIcon: const Icon(Feather.search, size: 19),
                        compact: true,
                      ),
                    ),
                  ),
                ),
              SizedBox(width: compact ? 4 : 14),
              IconButton(
                tooltip: 'preferences.title'.tr(),
                onPressed: onPreferences,
                icon: const Icon(Feather.settings, size: 21),
              ),
            ],
          ),
        );
      },
    );
  }
}
