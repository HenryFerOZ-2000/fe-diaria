import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

/// Servicio para compartir versículos como texto o imagen
class ShareService {
  /// Comparte un versículo como texto
  static Future<void> shareAsText({
    required String text,
    required String reference,
    String? title,
  }) async {
    try {
      final shareText = title != null
          ? '$text\n\n$reference\n\n- $title'
          : '$text\n\n$reference';
      
      await Share.share(
        shareText,
        subject: title ?? 'Verbum',
      );
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  /// Comparte un versículo como imagen
  static Future<void> shareAsImage({
    required String text,
    required String reference,
    required BuildContext context,
    String? title,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    try {
      // Crear la imagen del versículo
      final imageBytes = await _createVerseImage(
        text: text,
        reference: reference,
        title: title ?? 'Verbum',
        context: context,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );

      // Guardar temporalmente la imagen
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/verse_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // Compartir la imagen
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$text\n\n$reference',
        subject: title ?? 'Verbum',
      );

      // Limpiar después de un tiempo
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
      // Si falla compartir como imagen, compartir como texto
      try {
        await shareAsText(text: text, reference: reference, title: title);
      } catch (textError) {
        debugPrint('Error sharing as text: $textError');
        rethrow;
      }
    }
  }

  /// Crea una imagen del versículo
  static Future<Uint8List> _createVerseImage({
    required String text,
    required String reference,
    required String title,
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    // Configuración de la imagen
    const imageWidth = 1080.0;
    const imageHeight = 1920.0;
    const padding = 80.0;

    // Colores
    final bgColor = backgroundColor ?? 
        (Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1A1A1A) 
            : const Color(0xFFF5F5F5));
    final txtColor = textColor ?? 
        (Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black87);

    // Crear el recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(imageWidth, imageHeight);

    // Dibujar fondo
    final backgroundPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Dibujar decoración de fondo (cruz sutil)
    final decorationPaint = Paint()
      ..color = txtColor.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Cruz decorativa
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

    // Título
    final titleTextPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: txtColor.withOpacity(0.8),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    titleTextPainter.layout(maxWidth: size.width - (padding * 2));
    titleTextPainter.paint(
      canvas,
      Offset(
        (size.width - titleTextPainter.width) / 2,
        padding * 2,
      ),
    );

    // Texto del versículo
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

    // Línea decorativa
    final linePaint = Paint()
      ..color = txtColor.withOpacity(0.3)
      ..strokeWidth = 2;
    final lineY = padding * 2 + titleTextPainter.height + padding + 
        verseTextPainter.height + padding * 1.5;
    canvas.drawLine(
      Offset(padding, lineY),
      Offset(size.width - padding, lineY),
      linePaint,
    );

    // Referencia
    final referenceTextPainter = TextPainter(
      text: TextSpan(
        text: reference,
        style: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: txtColor.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    referenceTextPainter.layout(maxWidth: size.width - (padding * 2));
    referenceTextPainter.paint(
      canvas,
      Offset(
        (size.width - referenceTextPainter.width) / 2,
        lineY + padding,
      ),
    );

    // Convertir a imagen
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