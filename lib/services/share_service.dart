import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

/// Comparte versículos y oraciones como texto o imagen.
///
/// Enlaces de tiendas: ver bloque de constantes al inicio de [ShareService].
class ShareService {
  // ---------------------------------------------------------------------------
  // Enlaces de descarga (producción) — editar solo aquí.
  // ---------------------------------------------------------------------------
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ozcorp.verbum';

  /// **Reemplazar** cuando Verbum tenga ficha publicada en App Store.
  /// Ejemplo: `https://apps.apple.com/app/idXXXXXXXX`
  static const String verbumAppStoreUrl =
      'https://apps.apple.com/us/search?term=Verbum';

  static const String _shareSubject = 'Verbum';

  /// Pie compacto: nombre + URLs en líneas separadas (mejor para tocar en WhatsApp/Telegram).
  static String _footerStoreLinks() {
    return 'Verbum\n$_playStoreUrl\n$verbumAppStoreUrl';
  }

  /// Título y referencia sin repetir la misma línea dos veces.
  static String _headerLines({String? title, required String reference}) {
    final t = title?.trim() ?? '';
    final r = reference.trim();
    if (t.isEmpty) return r;
    if (r.isEmpty) return t;
    if (t == r) return t;
    return '$t\n$r';
  }

  /// Mensaje completo para compartir (texto o leyenda junto a imagen).
  static String buildShareMessage({
    required String text,
    required String reference,
    String? title,
  }) {
    final body = text.trim();
    final header = _headerLines(title: title, reference: reference);
    final core = header.isEmpty
        ? body
        : body.isEmpty
        ? header
        : '$header\n\n$body';
    if (core.isEmpty) return _footerStoreLinks();
    return '$core\n\n${_footerStoreLinks()}';
  }

  /// Comparte como texto.
  static Future<void> shareAsText({
    required String text,
    required String reference,
    String? title,
  }) async {
    try {
      await Share.share(
        buildShareMessage(text: text, reference: reference, title: title),
        subject: _shareSubject,
      );
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  /// Comparte como imagen (misma leyenda que el texto, con enlaces).
  static Future<void> shareAsImage({
    required String text,
    required String reference,
    required BuildContext context,
    String? title,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    try {
      final imageBytes = await _createVerseImage(
        text: text,
        reference: reference,
        title: title ?? 'Verbum',
        context: context,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/verse_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: buildShareMessage(text: text, reference: reference, title: title),
        subject: _shareSubject,
      );

      Future.delayed(const Duration(minutes: 5), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error sharing image: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        await shareAsText(text: text, reference: reference, title: title);
      } catch (textError) {
        debugPrint('Error sharing as text: $textError');
        rethrow;
      }
    }
  }

  static Future<Uint8List> _createVerseImage({
    required String text,
    required String reference,
    required String title,
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    const imageWidth = 1080.0;
    const imageHeight = 1920.0;
    const padding = 80.0;

    final bgColor =
        backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF5F5F5));
    final txtColor =
        textColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(imageWidth, imageHeight);

    final backgroundPaint = Paint()..color = bgColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final decorationPaint = Paint()
      ..color = txtColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.1),
      Offset(size.width / 2, size.height * 0.9),
      decorationPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height / 2),
      Offset(size.width * 0.9, size.height / 2),
      decorationPaint,
    );

    final titleTextPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: txtColor.withValues(alpha: 0.8),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    titleTextPainter.layout(maxWidth: size.width - (padding * 2));
    titleTextPainter.paint(
      canvas,
      Offset((size.width - titleTextPainter.width) / 2, padding * 2),
    );

    final verseTextPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.merriweather(
          fontSize: 42,
          height: 1.8,
          fontWeight: FontWeight.w400,
          color: txtColor,
          letterSpacing: 0.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    verseTextPainter.layout(maxWidth: size.width - (padding * 2));
    verseTextPainter.paint(
      canvas,
      Offset(
        (size.width - verseTextPainter.width) / 2,
        padding * 2 + titleTextPainter.height + padding,
      ),
    );

    final linePaint = Paint()
      ..color = txtColor.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    final lineY =
        padding * 2 +
        titleTextPainter.height +
        padding +
        verseTextPainter.height +
        padding * 1.5;
    canvas.drawLine(
      Offset(padding, lineY),
      Offset(size.width - padding, lineY),
      linePaint,
    );

    final referenceTextPainter = TextPainter(
      text: TextSpan(
        text: reference,
        style: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: txtColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    referenceTextPainter.layout(maxWidth: size.width - (padding * 2));
    referenceTextPainter.paint(
      canvas,
      Offset((size.width - referenceTextPainter.width) / 2, lineY + padding),
    );

    try {
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        imageWidth.toInt(),
        imageHeight.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error creating image: $e');
      rethrow;
    }
  }
}
