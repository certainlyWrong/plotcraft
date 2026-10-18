import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plotcraft_core/features/project_workspace/domain/rich/rich_document.dart';

/// The embeds are written by hand (no Flutter in the domain layer); they must
/// stay identical to what the editor's own classes produce, because the
/// editor reads the same Delta back.
void main() {
  test('o embed customizado é idêntico ao do editor', () {
    final expected = BlockEmbed.custom(
      const CustomBlockEmbed('gallery-image', '{"id":"g1"}'),
    ).toJson();
    expect(RichDocument.customEmbed('gallery-image', {'id': 'g1'}), expected);
    expect(RichDocument.customEmbed('gallery-image', '{"id":"g1"}'), expected);
    expect(
      RichDocument.divider(),
      BlockEmbed.custom(const CustomBlockEmbed('divider', '1')).toJson(),
    );
  });

  test('lê o embed escrito pelo editor e rejeita o que não é embed', () {
    final fromEditor = BlockEmbed.custom(const CustomBlockEmbed('divider', '1'))
        .toJson();
    expect(RichDocument.readCustomEmbed(fromEditor), (
      type: 'divider',
      data: '1',
    ));
    expect(RichDocument.readCustomEmbed({'image': 'x'}), isNull);
    expect(RichDocument.readCustomEmbed({'custom': 'not json'}), isNull);
    expect(RichDocument.readCustomEmbed({'custom': '{"a":1}'}), isNull);
    expect(RichDocument.readCustomEmbed(null), isNull);
  });
}
