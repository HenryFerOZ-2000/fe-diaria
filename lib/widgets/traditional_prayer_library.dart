import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verbum/design_system/design_system.dart';

/// Cabecera de la biblioteca de oraciones: superficie invertida (periwinkle
/// de día, índigo elevado de noche) con rúbrica, título y descripción.
class PrayerLibraryHero extends StatelessWidget {
  const PrayerLibraryHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.badge,
  });

  final String kicker;
  final String title;
  final String description;
  final VerbumIcons icon;

  /// Se conserva por compatibilidad; la cabecera usa los tonos invertidos.
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final fg = p.onInverse;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: p.inverse,
        borderRadius: BorderRadius.circular(VerbumRadius.card),
        boxShadow: VerbumShadows.soft(p),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -26,
            top: -30,
            child: ExcludeSemantics(
              child: VIcon(
                icon,
                weight: VIconWeight.duotone,
                size: 132,
                color: fg.withValues(alpha: .1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(VerbumRadius.control),
                    ),
                    child: Center(
                      child: VIcon(
                        icon,
                        weight: VIconWeight.duotone,
                        color: fg,
                        size: 22,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: type.caption.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                kicker,
                style: type.rubric.copyWith(
                  color: p.butter,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: Text(title, style: type.title.copyWith(color: fg)),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: type.body.copyWith(color: fg.withValues(alpha: .88)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de la biblioteca: tarjeta de papel con icono tintado, rúbrica,
/// título y descripción breve.
class PrayerLibraryCard extends StatelessWidget {
  const PrayerLibraryCard({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final VerbumIcons icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;

    return VSurfaceCard(
      radius: VerbumRadius.tile + 2,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      semanticLabel: '$title. $subtitle',
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(VerbumRadius.control),
              ),
              child: Center(
                child: VIcon(
                  icon,
                  weight: VIconWeight.duotone,
                  color: accent,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: type.rubric.copyWith(color: accent)),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.heading.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            VIcon(VerbumIcons.caretRight, color: p.inkSubtle, size: 16),
          ],
        ),
      ),
    );
  }
}

class PrayerLibraryEmptyState extends StatelessWidget {
  const PrayerLibraryEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: VEmptyState(
        icon: VerbumIcons.bookOpen,
        title: title,
        message: message,
      ),
    );
  }
}

/// Tonos de acento de la biblioteca, resueltos desde la paleta para que
/// funcionen en modo claro y oscuro.
enum PrayerLibraryTone {
  indigo,
  periwinkle,
  sage;

  Color resolve(VerbumPalette p) => switch (this) {
    PrayerLibraryTone.indigo => p.rubric,
    PrayerLibraryTone.periwinkle => p.gold,
    PrayerLibraryTone.sage => p.sageInk,
  };
}
