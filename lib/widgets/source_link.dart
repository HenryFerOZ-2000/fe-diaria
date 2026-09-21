import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSource(BuildContext context, String url) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
  } catch (_) {
    if (!context.mounted) return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo abrir la fuente. Comprueba tu conexión y vuelve a intentarlo.',
        ),
      ),
    );
  }
}
