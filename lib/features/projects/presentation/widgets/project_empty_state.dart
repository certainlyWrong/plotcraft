import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../ui/components/plotcraft_button.dart';
import '../../../../theme/plotcraft_tokens.dart';

class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({
    super.key,
    required this.hasSearch,
    required this.onCreate,
  });

  final bool hasSearch;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(PlotcraftRadii.surface),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Feather.search : Feather.book_open,
              color: theme.colorScheme.primary,
              size: 29,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasSearch
                ? 'home.empty_search_title'.tr()
                : 'home.empty_title'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'home.empty_search_description'.tr()
                : 'home.empty_description'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 22),
            PlotcraftButton(
              onPressed: onCreate,
              icon: Feather.plus,
              label: 'home.first_project'.tr(),
              variant: PlotcraftButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
