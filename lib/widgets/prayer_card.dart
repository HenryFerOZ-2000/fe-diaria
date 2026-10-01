import 'package:flutter/material.dart';
import '../faith/content_provenance.dart';
import 'prayer_reading_experience.dart';
import 'package:verbum/design_system/design_system.dart';

/// Tarjeta reutilizable para mostrar oraciones sobre papel.
class PrayerCard extends StatelessWidget {
  final String title;
  final String text;
  final String? reference;
  final VerbumIcons? icon;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final Color? accentColor;
  final bool openReaderOnTap;
  final ContentProvenance provenance;

  const PrayerCard({
    super.key,
    required this.title,
    required this.text,
    this.reference,
    this.icon,
    this.onShare,
    this.onFavorite,
    this.isFavorite = false,
    this.accentColor,
    this.openReaderOnTap = true,
    this.provenance = ContentProvenance.unverified,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final accent = accentColor ?? p.rubric;

    return VSurfaceCard(
      onTap: openReaderOnTap
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PrayerTextReadingScreen(
                  title: title,
                  text: text,
                  reference: reference,
                  provenance: provenance,
                ),
              ),
            )
          : null,
      padding: const EdgeInsets.all(VerbumSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(VerbumSpace.sm),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(VerbumRadius.control),
                  ),
                  child: VIcon(
                    icon!,
                    weight: VIconWeight.duotone,
                    color: accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: VerbumSpace.sm),
              ],
              Expanded(child: Text(title, style: type.heading)),
              if (onShare != null)
                VIconButton(
                  icon: VerbumIcons.shareNetwork,
                  semanticLabel: 'Compartir',
                  variant: VIconButtonVariant.ghost,
                  color: p.rubric,
                  onPressed: onShare,
                ),
              if (onFavorite != null)
                VIconButton(
                  icon: VerbumIcons.heart,
                  weight: isFavorite ? VIconWeight.fill : VIconWeight.regular,
                  semanticLabel: isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                  variant: VIconButtonVariant.ghost,
                  color: p.rubric,
                  onPressed: onFavorite,
                ),
            ],
          ),
          const SizedBox(height: VerbumSpace.md),
          Text(
            text,
            maxLines: openReaderOnTap ? 4 : null,
            overflow: openReaderOnTap ? TextOverflow.ellipsis : null,
            style: type.scripture,
          ),
          if (openReaderOnTap) ...[
            const SizedBox(height: VerbumSpace.sm),
            Row(
              children: [
                Text('Abrir modo oración', style: type.rubric),
                const Spacer(),
                VIcon(VerbumIcons.arrowUpRight, size: 18, color: p.rubric),
              ],
            ),
          ],
          if (reference != null) ...[
            const SizedBox(height: VerbumSpace.sm),
            VMetaChip(label: reference!, icon: VerbumIcons.quotes),
          ],
        ],
      ),
    );
  }
}
