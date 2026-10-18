import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/ui/plotcraft_button.dart';
import '../../stores/workspace_controller.dart';

/// Shows a bar above a tab's content when its file was changed outside
/// Plotcraft while it had unsaved edits, and lets the person pick a version.
class ExternalChangeFrame extends StatelessWidget {
  const ExternalChangeFrame({
    super.key,
    required this.controller,
    required this.tabId,
    required this.child,
  });

  final WorkspaceController controller;
  final String tabId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (context) {
      final conflict = controller.externalConflicts.contains(tabId);
      if (!conflict) return child;
      final scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Feather.alert_triangle,
                    size: 16,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'workspace.external_changed'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                  PlotcraftButton(
                    label: 'workspace.external_load'.tr(),
                    variant: PlotcraftButtonVariant.secondary,
                    onPressed: () => controller.resolveExternalConflict(
                      tabId,
                      keepMine: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlotcraftButton(
                    label: 'workspace.external_keep'.tr(),
                    onPressed: () => controller.resolveExternalConflict(
                      tabId,
                      keepMine: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );
    },
  );
}
