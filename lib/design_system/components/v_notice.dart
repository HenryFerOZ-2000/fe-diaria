import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import '../tokens/verbum_radius.dart';
import 'v_icon.dart';

enum VNoticeTone { info, error }

/// Aviso breve dentro de un formulario o tarjeta.
class VNotice extends StatelessWidget {
  const VNotice(this.message, {super.key, this.tone = VNoticeTone.info});

  final String message;
  final VNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final error = tone == VNoticeTone.error;
    final fg = error ? scheme.onErrorContainer : p.inkMuted;
    return Semantics(
      liveRegion: error,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : p.surfaceMuted,
          borderRadius: BorderRadius.circular(VerbumRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIcon(
              error ? VerbumIcons.warningCircle : VerbumIcons.info,
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.type.body.copyWith(color: fg, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
