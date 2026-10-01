import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../application/today_schedule.dart';
import 'cover_photos.dart';

/// Portada de "Hoy": un paisaje sereno con la Palabra del día como
/// protagonista, al estilo de la portada de una revista.
/// Solo compone; el estado vive en la pantalla.
///
/// Sobre la foto los tonos son fijos (Tinta e Índigo de la paleta), igual
/// en modo claro y oscuro.
const _tinta = Color(0xFF22245A);
const _indigo = Color(0xFF3A3C8E);

class TodayCover extends StatelessWidget {
  const TodayCover({
    super.key,
    required this.now,
    this.night = false,
    required this.streakDays,
    required this.onProfile,
    required this.onStreak,
    this.userName,
    this.verseText,
    this.verseReference,
    this.onRead,
    this.onShare,
  });

  final DateTime now;

  /// Velo más profundo para la noche.
  final bool night;
  final int streakDays;
  final VoidCallback onProfile;
  final VoidCallback onStreak;
  final String? userName;
  final String? verseText;
  final String? verseReference;
  final VoidCallback? onRead;
  final VoidCallback? onShare;

  /// Cuanto más largo el versículo, más pequeña la letra.
  static double _verseSize(String text) => text.length <= 90
      ? 37
      : text.length <= 160
      ? 31
      : 26;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final verse = verseText?.trim() ?? '';
    final name = firstName(userName);
    final greeting = greetingFor(now, name: userName);
    final comma = greeting.indexOf(',');
    final minHeight = (MediaQuery.sizeOf(context).height * .72).clamp(
      540.0,
      720.0,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ClipRRect(
        // Corte limpio: la foto termina en esquinas redondeadas.
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(VerbumRadius.sheet),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(coverPhoto.asset, fit: BoxFit.cover),
              ),
            ),
            // Velo: legible arriba (saludo) y abajo (versículo); la foto
            // respira en el centro y se funde con el lavanda de la página.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _tinta.withValues(alpha: night ? .8 : .45),
                      _indigo.withValues(alpha: night ? .55 : .05),
                      _tinta.withValues(alpha: night ? .62 : .35),
                      _tinta.withValues(alpha: night ? .9 : .82),
                    ],
                    stops: const [0, .28, .55, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  10,
                  VerbumSpace.gutter,
                  92,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VGlassButton(
                          icon: VerbumIcons.user,
                          tooltip: 'Mi perfil',
                          onPressed: onProfile,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _StreakChip(
                              days: streakDays,
                              onTap: onStreak,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      longSpanishDate(now).toUpperCase(),
                      style: type.rubric.copyWith(
                        color: Colors.white.withValues(alpha: .9),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: name == null
                                  ? greeting
                                  : greeting.substring(0, comma + 1),
                            ),
                            if (name != null)
                              TextSpan(
                                text: ' $name',
                                style: TextStyle(color: p.butter),
                              ),
                          ],
                        ),
                        style: type.heading.copyWith(
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    SizedBox(height: verse.isEmpty ? 0 : 96),
                    if (verse.isNotEmpty) ...[
                      Text(
                        'PALABRA DE HOY',
                        style: type.rubric.copyWith(
                          color: p.butter,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '«$verse»',
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                        style: VerbumFonts.serif(
                          color: Colors.white,
                          fontSize: _verseSize(verse),
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                      if (verseReference != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          verseReference!,
                          style: type.bodyStrong.copyWith(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onRead != null)
                            _Pill(
                              label: 'Leer y meditar',
                              icon: VerbumIcons.bookOpen,
                              solid: true,
                              onTap: onRead!,
                            ),
                          if (onShare != null)
                            _Pill(
                              label: 'Compartir',
                              icon: VerbumIcons.shareNetwork,
                              onTap: onShare!,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, required this.onTap});

  final int days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = '$days ${days == 1 ? 'día' : 'días'}';
    final radius = BorderRadius.circular(VerbumRadius.control);
    return Semantics(
      button: true,
      label: 'Constancia: $label',
      excludeSemantics: true,
      child: Material(
        color: p.butter,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VIcon(
                  VerbumIcons.flame,
                  size: 17,
                  weight: VIconWeight.fill,
                  color: p.onButter,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.bodyStrong.copyWith(color: p.onButter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.solid = false,
  });

  final String label;
  final VerbumIcons icon;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? _indigo : Colors.white;
    final radius = BorderRadius.circular(99);
    return Material(
      color: solid ? Colors.white : Colors.white.withValues(alpha: .18),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VIcon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: context.type.bodyStrong.copyWith(
                    color: fg,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
