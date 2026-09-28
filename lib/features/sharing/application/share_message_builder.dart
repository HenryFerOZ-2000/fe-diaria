import '../domain/share_content.dart';

abstract final class ShareMessageBuilder {
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ozcorp.verbum';

  static String build(ShareContent content) {
    final sections = <String>[
      content.title,
      if (content.reference case final reference? when reference.isNotEmpty)
        reference,
      content.body,
      'Descubre Verbum y comparte la Palabra:',
      playStoreUrl,
    ];
    return sections.join('\n\n');
  }
}
