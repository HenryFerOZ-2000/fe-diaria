import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/bible/application/passage_text.dart';
import 'package:verbum/bible/application/reader_tone.dart';
import 'package:verbum/bible/domain/verse.dart';

void main() {
  Verse v(int n, String text) =>
      Verse(book: 'LUK', chapter: 9, verse: n, text: text);

  test('limpia marcas Strong, \\w y barras', () {
    expect(
      sanitizeVerseText('Jesús strong="G2424" le|dijo \\w*  «Sígueme»'),
      'Jesús le dijo «Sígueme»',
    );
    expect(sanitizeVerseText("Dios strong='H430'"), 'Dios');
  });

  test('referencia y cuerpo del pasaje en orden', () {
    final verses = [v(57, 'a'), v(58, 'b'), v(62, 'c')];
    final chosen = selectedInOrder(verses, {62, 57});
    expect(chosen.map((x) => x.verse), [57, 62]);
    expect(passageReference('Lucas', 9, chosen), 'Lucas 9:57-62');
    expect(passageReference('Lucas', 9, [v(62, 'c')]), 'Lucas 9:62');
    expect(passageReference('Lucas', 9, const []), 'Lucas 9');
    expect(passageBody(chosen), '57. a\n62. c');
  });

  test('tono de lectura desconocido vuelve a sistema', () {
    expect(ReaderTone.parse('warm'), ReaderTone.warm);
    expect(ReaderTone.parse('sepia'), ReaderTone.system);
    expect(ReaderTone.parse(null), ReaderTone.system);
  });

  test('suaviza las versales con que abre cada capítulo', () {
    expect(
      softenOpeningCaps('Y ACONTECIÓ en aquellos días'),
      'Y aconteció en aquellos días',
    );
    expect(
      softenOpeningCaps('HABIENDO muchos tentado'),
      'Habiendo muchos tentado',
    );
    expect(softenOpeningCaps('EN el principio'), 'En el principio');
    expect(
      softenOpeningCaps('¿POR qué se amotinan las gentes'),
      '¿Por qué se amotinan las gentes',
    );
    expect(softenOpeningCaps('Jehová es mi pastor'), 'Jehová es mi pastor');
  });
}
