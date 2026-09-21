import 'package:flutter/material.dart';

import '../models/verse.dart';

class DailyVerseWidgetPreview extends StatelessWidget {
  const DailyVerseWidgetPreview({super.key, required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF211B29) : const Color(0xFFFFF8EE);
    final text = dark ? const Color(0xFFFFF8EE) : const Color(0xFF2C2332);
    final muted = dark ? const Color(0xFFC7BBC8) : const Color(0xFF746A72);
    final accent = dark ? const Color(0xFFE5BD7B) : const Color(0xFF8C5A37);

    return Semantics(
      container: true,
      label: 'Versículo del día, ${verse.reference}: ${verse.text}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          final padding = compact ? 16.0 : 20.0;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C2332).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'VERBUM · PALABRA DEL DÍA',
                          maxLines: 1,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                Text(
                  verse.text,
                  maxLines: compact ? 4 : 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontFamily: 'serif',
                    fontSize: compact ? 19 : 21,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        verse.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RV1909',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
