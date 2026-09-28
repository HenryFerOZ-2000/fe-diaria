import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/sharing/domain/share_content.dart';
import 'package:verbum/features/sharing/domain/share_visual_style.dart';

void main() {
  test('night mood takes precedence over prayer kind', () {
    expect(
      ShareStyleResolver.resolve(
        ShareContent(
          title: 'Oración de la noche',
          body: 'Señor, danos descanso.',
          kind: ShareContentKind.prayer,
          mood: ShareContentMood.night,
        ),
      ),
      ShareVisualStyle.contemplativeNight,
    );
  });

  test('uses living tradition for liturgical, prayer, and psalm content', () {
    final contents = [
      ShareContent(
        title: 'Tiempo litúrgico',
        body: 'Celebramos juntos.',
        kind: ShareContentKind.verse,
        mood: ShareContentMood.liturgical,
      ),
      ShareContent(
        title: 'Oración',
        body: 'Escucha nuestra oración.',
        kind: ShareContentKind.prayer,
      ),
      ShareContent(
        title: 'Salmo',
        body: 'Aclama al Señor.',
        kind: ShareContentKind.psalm,
      ),
    ];

    for (final content in contents) {
      expect(
        ShareStyleResolver.resolve(content),
        ShareVisualStyle.livingTradition,
      );
    }
  });

  test('uses liturgical color only when one is provided', () {
    final catholicWithoutColor = ShareContent(
      title: 'Versículo católico',
      body: 'Permanezcan en mi amor.',
      kind: ShareContentKind.verse,
      tradition: ShareTradition.catholic,
    );
    final evangelicalWithoutColor = ShareContent(
      title: 'Versículo evangélico',
      body: 'Alégrense en la esperanza.',
      kind: ShareContentKind.verse,
      tradition: ShareTradition.evangelical,
    );
    final contentWithColor = ShareContent(
      title: 'Versículo litúrgico',
      body: 'La Palabra se hizo carne.',
      kind: ShareContentKind.verse,
      liturgicalColor: const Color(0xFF2E7D32),
    );

    expect(
      ShareStyleResolver.resolve(catholicWithoutColor),
      ShareVisualStyle.sereneLight,
    );
    expect(
      ShareStyleResolver.resolve(evangelicalWithoutColor),
      ShareVisualStyle.sereneLight,
    );
    expect(
      ShareStyleResolver.resolve(contentWithColor),
      ShareVisualStyle.livingTradition,
    );
  });

  test('uses serene light for ordinary hopeful content', () {
    final content = ShareContent(
      title: 'Esperanza',
      body: 'Todo lo puedo en Cristo.',
      kind: ShareContentKind.verse,
      mood: ShareContentMood.hopeful,
    );

    expect(ShareStyleResolver.resolve(content), ShareVisualStyle.sereneLight);
  });
}
