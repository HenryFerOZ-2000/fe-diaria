import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/application/share_message_builder.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';

void main() {
  test('builds a complete caption with only the official store URL', () {
    final content = ShareContent(
      title: 'Versículo del día',
      body: 'Todo lo puedo en Cristo que me fortalece.',
      kind: ShareContentKind.verse,
      reference: 'Filipenses 4:13',
    );

    final message = ShareMessageBuilder.build(content);

    expect(message, contains('Versículo del día'));
    expect(message, contains('Filipenses 4:13'));
    expect(message, contains('Todo lo puedo en Cristo que me fortalece.'));
    expect(message, contains('Verbum'));
    expect(message, contains(ShareMessageBuilder.playStoreUrl));
    expect(
      message,
      contains(
        'https://play.google.com/store/apps/details?id=com.ozcorp.verbum',
      ),
    );
    expect(message, isNot(contains('apps.apple.com')));
  });

  test('omits a reference section when content has no reference', () {
    final content = ShareContent(
      title: 'Reflexión',
      body: 'La esperanza se renueva cada mañana.',
      kind: ShareContentKind.reflection,
    );

    final message = ShareMessageBuilder.build(content);

    expect(message, contains('Reflexión'));
    expect(message, contains('La esperanza se renueva cada mañana.'));
    expect(message, isNot(contains('null')));
    expect(message, isNot(contains('apps.apple.com')));
  });
}
