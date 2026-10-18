import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:icons_flutter/icons_flutter.dart';

import '../../../../core/theme/plotcraft_tokens.dart';
import '../../../../core/ui/project_image.dart';
import '../../domain/rich/rich_document.dart';

/// Shows a gallery image by ID. [pathOf] gives its file on this computer, or
/// null when the image is not in the gallery (any more).
class GalleryImageEmbedBuilder extends EmbedBuilder {
  const GalleryImageEmbedBuilder({required this.pathOf});

  final String? Function(String id) pathOf;

  @override
  String get key => RichDocument.galleryImageType;

  @override
  String toPlainText(Embed node) => '[${'editor.image'.tr()}]';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = _data(embedContext.node.value.data);
    final id = data['id'] as String? ?? '';
    final path = pathOf(id);
    final width = (data['width'] as num?)?.toDouble();
    final scheme = Theme.of(context).colorScheme;
    final image = path == null
        ? _Missing(label: 'editor.image_missing'.tr())
        : ClipRRect(
            borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
            child: ProjectImage(
              path,
              fit: BoxFit.contain,
              cacheWidth: 1200,
              fallback: _Missing(label: 'editor.image_missing'.tr()),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: switch (data['align']) {
          'left' => Alignment.centerLeft,
          'right' => Alignment.centerRight,
          _ => Alignment.center,
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width ?? 560, maxHeight: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
            ),
            child: image,
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _data(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}

/// A horizontal rule between scenes.
class DividerEmbedBuilder extends EmbedBuilder {
  const DividerEmbedBuilder();

  @override
  String get key => RichDocument.dividerType;

  @override
  String toPlainText(Embed node) => '* * *';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(
      child: Text(
        '* * *',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 8,
        ),
      ),
    ),
  );
}

/// Images that came from outside the project (an old Markdown link). They
/// are not loaded from the network; the address is shown instead.
class ExternalImageEmbedBuilder extends EmbedBuilder {
  const ExternalImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final value = embedContext.node.value.data;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _Missing(label: '${'editor.external_image'.tr()}: $value'),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(PlotcraftRadii.panel),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Feather.image, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
