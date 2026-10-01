import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';
import 'liturgical_palette.dart';
import 'liturgy_source_sheet.dart';
import 'package:verbum/design_system/design_system.dart';

class LiturgyDayScreen extends StatelessWidget {
  const LiturgyDayScreen({
    super.key,
    required this.day,
    required this.selection,
  });

  final LiturgicalDay day;
  final CalendarSelection selection;

  /// Foto de portada según el tiempo litúrgico.
  static VerbumPhotos _photoFor(LiturgicalSeason season) => switch (season) {
    LiturgicalSeason.advent => VerbumPhotos.candle,
    LiturgicalSeason.christmas => VerbumPhotos.marianWindow,
    LiturgicalSeason.lent => VerbumPhotos.handsTogether,
    LiturgicalSeason.triduum => VerbumPhotos.candle,
    LiturgicalSeason.easter => VerbumPhotos.genesisLight,
    LiturgicalSeason.ordinaryTime => VerbumPhotos.stainedGlass,
  };

  void _showSource(BuildContext context) =>
      showLiturgySourceSheet(context, day: day, selection: selection);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final color = day.primary.colors.firstOrNull;
    final colorLabel = color == null
        ? 'Sin color indicado'
        : LiturgicalPalette.label(color);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: p.background,
        body: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            _Cover(
              photo: _photoFor(day.season),
              date: _dateLabel(day.date),
              title: day.primary.name,
              rank: _rankLabel(day.primary.rank),
              color: color,
              colorLabel: colorLabel,
              onInfo: () => _showSource(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                0,
                VerbumSpace.gutter,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VSectionHeader(
                    'Sobre este día',
                    padding: EdgeInsets.fromLTRB(2, 22, 2, 12),
                  ),
                  VTileGrid(
                    children: [
                      _Fact(
                        icon: VerbumIcons.calendarDots,
                        label: 'Tiempo',
                        value: _seasonLabel(day.season),
                      ),
                      _Fact(
                        icon: VerbumIcons.crown,
                        label: 'Rango',
                        value: _rankLabel(day.primary.rank),
                      ),
                      _Fact(
                        icon: VerbumIcons.palette,
                        label: 'Color',
                        value: colorLabel,
                        swatch: color == null
                            ? null
                            : LiturgicalPalette.swatch(color),
                      ),
                      if (day.sundayCycle != null)
                        _Fact(
                          icon: VerbumIcons.arrowsClockwise,
                          label: 'Ciclo dominical',
                          value: day.sundayCycle!,
                        ),
                      if (day.weekdayCycle != null)
                        _Fact(
                          icon: VerbumIcons.arrowsClockwise,
                          label: 'Ciclo ferial',
                          value: day.weekdayCycle!,
                        ),
                      if (day.psalterWeek != null)
                        _Fact(
                          icon: VerbumIcons.musicNote,
                          label: 'Salterio',
                          value: 'Semana ${day.psalterWeek}',
                        ),
                    ],
                  ),
                  if (day.optional.isNotEmpty) ...[
                    const VSectionHeader(
                      'Memorias opcionales',
                      padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
                    ),
                    VListGroup(
                      children: [
                        for (final celebration in day.optional)
                          VListRow(
                            leading: VerbumIcons.sparkle,
                            title: celebration.name,
                            subtitle: _rankLabel(celebration.rank),
                          ),
                      ],
                    ),
                  ],
                  const VSectionHeader(
                    'Para orar hoy',
                    padding: EdgeInsets.fromLTRB(2, 26, 2, 12),
                  ),
                  VSurfaceCard(
                    radius: VerbumRadius.card,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.butter,
                            borderRadius: BorderRadius.circular(
                              VerbumRadius.control,
                            ),
                          ),
                          child: VIcon(
                            VerbumIcons.handsPraying,
                            color: p.onButter,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Oración devocional sugerida para hoy',
                                style: type.heading.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tómate un momento para presentar este día a '
                                'Dios con tus propias palabras.',
                                style: type.body.copyWith(color: p.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  VListGroup(
                    children: [
                      VListRow(
                        leading: VerbumIcons.info,
                        title: 'Fuente y alcance del calendario',
                        onTap: () => _showSource(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  static String _seasonLabel(LiturgicalSeason season) => switch (season) {
    LiturgicalSeason.advent => 'Adviento',
    LiturgicalSeason.christmas => 'Navidad',
    LiturgicalSeason.ordinaryTime => 'Tiempo Ordinario',
    LiturgicalSeason.lent => 'Cuaresma',
    LiturgicalSeason.triduum => 'Triduo Pascual',
    LiturgicalSeason.easter => 'Pascua',
  };

  static String _rankLabel(LiturgicalRank rank) => switch (rank) {
    LiturgicalRank.solemnity => 'Solemnidad',
    LiturgicalRank.sunday => 'Domingo',
    LiturgicalRank.feast => 'Fiesta',
    LiturgicalRank.memorial => 'Memoria',
    LiturgicalRank.optionalMemorial => 'Memoria opcional',
    LiturgicalRank.weekday => 'Feria',
  };
}

/// Portada: foto del tiempo litúrgico con velo, la fecha, el nombre de la
/// celebración y chips de rango y color.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.photo,
    required this.date,
    required this.title,
    required this.rank,
    required this.color,
    required this.colorLabel,
    required this.onInfo,
  });

  final VerbumPhotos photo;
  final String date;
  final String title;
  final String rank;
  final LiturgicalColor? color;
  final String colorLabel;
  final VoidCallback onInfo;

  // Sobre la foto los tonos son fijos (Tinta de la paleta).
  static const _tinta = Color(0xFF22245A);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (MediaQuery.sizeOf(context).height * .5).clamp(380, 520),
      ),
      child: ClipRRect(
        // Corte limpio: la foto termina en esquinas redondeadas.
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(VerbumRadius.sheet),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(photo.asset, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _tinta.withValues(alpha: .55),
                      _tinta.withValues(alpha: .15),
                      _tinta.withValues(alpha: .8),
                    ],
                    stops: const [0, .32, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  8,
                  VerbumSpace.gutter,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const VBackButton(onColor: true),
                        const Spacer(),
                        Tooltip(
                          message: 'Fuente y alcance',
                          child: Material(
                            color: Colors.white.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(
                              VerbumRadius.control,
                            ),
                            child: InkWell(
                              onTap: onInfo,
                              borderRadius: BorderRadius.circular(
                                VerbumRadius.control,
                              ),
                              child: const SizedBox.square(
                                dimension: 44,
                                child: Center(
                                  child: VIcon(
                                    VerbumIcons.info,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                    Text(
                      'HOY EN LA IGLESIA · ${date.toUpperCase()}',
                      style: type.rubric.copyWith(
                        color: p.butter,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: type.display.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GlassChip(label: rank),
                        _GlassChip(
                          label: colorLabel,
                          dot: color == null
                              ? null
                              : LiturgicalPalette.swatch(color!),
                        ),
                      ],
                    ),
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

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label, this.dot});

  final String label;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              style: context.type.bodyStrong.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un dato del día en su tarjeta: icono, etiqueta y valor.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.swatch,
  });

  final VerbumIcons icon;
  final String label;
  final String value;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    return VSurfaceCard(
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: VIcon(icon, size: 18, color: p.rubric),
              ),
              const Spacer(),
              if (swatch != null)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.line, width: 1.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: type.caption),
          Text(value, style: type.bodyStrong),
        ],
      ),
    );
  }
}
