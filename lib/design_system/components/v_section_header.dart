import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Encabezado de sección: título en serif y metadato o acción a la derecha.
class VSectionHeader extends StatelessWidget {
  const VSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.onTrailingTap,
    this.eyebrow,
    this.padding = const EdgeInsets.fromLTRB(2, 20, 2, 10),
  });

  final String title;

  /// Rúbrica breve sobre el título ("TU HUELLA").
  final String? eyebrow;

  /// Texto corto a la derecha ("1 de 3", "Ver todo").
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final meta = trailing == null
        ? null
        : Text(
            trailing!,
            style: type.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: onTrailingTap != null ? context.palette.rubric : null,
            ),
          );
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(
                      eyebrow!.toUpperCase(),
                      style: type.rubric.copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(title, style: type.heading),
                ],
              ),
            ),
          ),
          if (meta != null)
            onTrailingTap == null
                ? meta
                : InkWell(
                    onTap: onTrailingTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: meta,
                    ),
                  ),
        ],
      ),
    );
  }
}
