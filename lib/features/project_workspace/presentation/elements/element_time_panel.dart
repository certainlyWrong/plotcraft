import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/plotcraft_text_field.dart';

import 'package:plotcraft_core/features/project_workspace/domain/story_time.dart';

/// "When does this happen in the story?": a label written the way the story
/// tells it, and an optional number that only orders things on the timeline.
class ElementTimePanel extends StatefulWidget {
  const ElementTimePanel({
    super.key,
    required this.time,
    required this.onChanged,
  });

  final StoryTime? time;
  final ValueChanged<StoryTime?> onChanged;

  @override
  State<ElementTimePanel> createState() => _ElementTimePanelState();
}

class _ElementTimePanelState extends State<ElementTimePanel> {
  late final _label = TextEditingController(text: widget.time?.label ?? '');
  late final _position = TextEditingController(
    text: StoryTime.formatPosition(widget.time?.position),
  );

  @override
  void dispose() {
    _label.dispose();
    _position.dispose();
    super.dispose();
  }

  void _changed() {
    final position = double.tryParse(
      _position.text.trim().replaceAll(',', '.'),
    );
    final time = StoryTime(label: _label.text, position: position);
    widget.onChanged(time.isEmpty ? null : time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'elements.time'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'elements.time_hint'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: PlotcraftTextField(
                controller: _label,
                label: 'elements.time_label'.tr(),
                hint: 'elements.time_label_hint'.tr(),
                onChanged: (_) => _changed(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: PlotcraftTextField(
                controller: _position,
                label: 'elements.time_position'.tr(),
                helperText: 'elements.time_position_hint'.tr(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[.,]?\d*')),
                ],
                onChanged: (_) => _changed(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
