import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/gris/gris.dart';
import '../../../../core/ui/plotcraft_button.dart';

/// An empty shelf: rings turning slowly behind a few words. No box around it.
class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({
    super.key,
    required this.hasSearch,
    required this.onCreate,
    this.onSample,
    this.installingSample = false,
  });

  final bool hasSearch;
  final VoidCallback onCreate;

  /// Opens the bundled example; null hides the action.
  final VoidCallback? onSample;
  final bool installingSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 440,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const OrbitRings(size: 440),
          const Positioned(left: 0, top: 40, child: Constellation(width: 240)),
          Reveal(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasSearch ? Feather.search : Feather.feather,
                    color: context.tokens.ink,
                    size: 26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasSearch
                        ? 'home.empty_search_title'.tr()
                        : 'home.empty_title'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: PlotcraftFonts.serif,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasSearch
                        ? 'home.empty_search_description'.tr()
                        : 'home.empty_description'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  if (!hasSearch) ...[
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        PlotcraftButton(
                          onPressed: onCreate,
                          icon: Feather.plus,
                          label: 'home.first_project'.tr(),
                        ),
                        if (onSample != null)
                          PlotcraftButton(
                            onPressed: installingSample ? null : onSample,
                            icon: Feather.compass,
                            label: 'home.open_sample'.tr(),
                            variant: PlotcraftButtonVariant.text,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
