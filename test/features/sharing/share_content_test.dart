import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/domain/share_card_format.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/domain/share_page.dart';

void main() {
  group('ShareCardFormat', () {
    test('exposes the exact export dimensions and labels', () {
      expect(ShareCardFormat.portrait.pixelSize, const Size(1080, 1350));
      expect(ShareCardFormat.square.pixelSize, const Size(1080, 1080));
      expect(ShareCardFormat.story.pixelSize, const Size(1080, 1920));
      expect(ShareCardFormat.portrait.label, '4:5');
      expect(ShareCardFormat.square.label, '1:1');
      expect(ShareCardFormat.story.label, '9:16');
    });
  });

  group('ShareContent', () {
    test('trims user-facing text and preserves religious metadata', () {
      const liturgicalColor = Color(0xFF6A1B9A);

      final catholic = ShareContent(
        title: '  Oración de la noche  ',
        body: '  Señor, danos descanso.  ',
        kind: ShareContentKind.prayer,
        reference: '  Salmo 4:8  ',
        tradition: ShareTradition.catholic,
        mood: ShareContentMood.liturgical,
        liturgicalColor: liturgicalColor,
        sourceLabel: '  Liturgia diaria  ',
        shareCaption: '  Una oración para descansar  ',
      );
      final evangelical = ShareContent(
        title: 'Reflexión',
        body: 'Confiamos en tu promesa.',
        kind: ShareContentKind.reflection,
        tradition: ShareTradition.evangelical,
      );

      expect(catholic.title, 'Oración de la noche');
      expect(catholic.body, 'Señor, danos descanso.');
      expect(catholic.reference, 'Salmo 4:8');
      expect(catholic.tradition, ShareTradition.catholic);
      expect(catholic.mood, ShareContentMood.liturgical);
      expect(catholic.liturgicalColor, liturgicalColor);
      expect(catholic.sourceLabel, 'Liturgia diaria');
      expect(catholic.shareCaption, 'Una oración para descansar');
      expect(evangelical.tradition, ShareTradition.evangelical);
      expect(evangelical.liturgicalColor, isNull);
    });

    test('has value equality across all fields', () {
      const color = Color(0xFFB71C1C);
      final first = ShareContent(
        title: 'Salmo del día',
        body: 'El Señor es mi pastor.',
        kind: ShareContentKind.psalm,
        reference: 'Salmo 23:1',
        tradition: ShareTradition.ecumenical,
        mood: ShareContentMood.hopeful,
        liturgicalColor: color,
        sourceLabel: 'Salmos',
        shareCaption: 'Comparte esperanza',
      );
      final same = ShareContent(
        title: 'Salmo del día',
        body: 'El Señor es mi pastor.',
        kind: ShareContentKind.psalm,
        reference: 'Salmo 23:1',
        tradition: ShareTradition.ecumenical,
        mood: ShareContentMood.hopeful,
        liturgicalColor: color,
        sourceLabel: 'Salmos',
        shareCaption: 'Comparte esperanza',
      );
      final different = ShareContent(
        title: 'Salmo del día',
        body: 'Nada me faltará.',
        kind: ShareContentKind.psalm,
        reference: 'Salmo 23:1',
        tradition: ShareTradition.ecumenical,
        mood: ShareContentMood.hopeful,
        liturgicalColor: color,
        sourceLabel: 'Salmos',
        shareCaption: 'Comparte esperanza',
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });

    test('rejects a body that is empty after trimming', () {
      expect(
        () => ShareContent(
          title: 'Sin contenido',
          body: '  \n  ',
          kind: ShareContentKind.reflection,
        ),
        throwsArgumentError,
      );
    });
  });

  test('SharePage has value equality', () {
    expect(
      const SharePage(body: 'Página', index: 1, total: 2),
      const SharePage(body: 'Página', index: 1, total: 2),
    );
    expect(
      const SharePage(body: 'Página', index: 1, total: 2),
      isNot(const SharePage(body: 'Página', index: 2, total: 2)),
    );
  });
}
