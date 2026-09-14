import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? eyebrow;
  final String? subtitle;

  const PrayerButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.eyebrow,
    this.subtitle,
  });

  @override
  State<PrayerButton> createState() => _PrayerButtonState();
}

class _PrayerButtonState extends State<PrayerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _pressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = _paletteFor(widget.title, dark);
    final subtitle = widget.subtitle ?? _subtitleFor(widget.title);
    final eyebrow = widget.eyebrow ?? _eyebrowFor(widget.title);

    return FadeTransition(
      opacity: _entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(_entrance),
        child: AnimatedScale(
          scale: _pressed ? .975 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(17, 16, 14, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        palette.accent.withValues(alpha: dark ? .15 : .08),
                        scheme.surface,
                      ),
                      scheme.surface.withValues(alpha: dark ? .94 : .98),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: dark ? .24 : .16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.accent.withValues(
                        alpha: _pressed ? .08 : .13,
                      ),
                      blurRadius: _pressed ? 12 : 24,
                      offset: Offset(0, _pressed ? 5 : 11),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -16,
                      top: -30,
                      child: Icon(
                        widget.icon,
                        size: 104,
                        color: palette.accent.withValues(alpha: .045),
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 50,
                          height: 50,
                          transform: Matrix4.translationValues(
                            0,
                            _pressed ? -2 : 0,
                            0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [palette.accent, palette.deep],
                            ),
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(alpha: .25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.35,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSlide(
                          offset: _pressed ? const Offset(.16, 0) : Offset.zero,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: .1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _PrayerPalette _paletteFor(String title, bool dark) {
    final key = title.toLowerCase();
    if (key.contains('ansiedad') || key.contains('tristeza')) {
      return const _PrayerPalette(Color(0xFF77649A), Color(0xFF493878));
    }
    if (key.contains('paz') ||
        key.contains('salud') ||
        key.contains('sanaci')) {
      return const _PrayerPalette(Color(0xFF5F8178), Color(0xFF365A52));
    }
    if (key.contains('gratitud') || key.contains('prosperidad')) {
      return const _PrayerPalette(Color(0xFFB58A45), Color(0xFF7B5928));
    }
    if (key.contains('familia') ||
        key.contains('hijos') ||
        key.contains('pareja')) {
      return const _PrayerPalette(Color(0xFFA65F69), Color(0xFF713B4A));
    }
    if (key.contains('fortaleza') || key.contains('protecci')) {
      return const _PrayerPalette(Color(0xFF536C91), Color(0xFF334664));
    }
    if (key.contains('perd')) {
      return const _PrayerPalette(Color(0xFF9A7054), Color(0xFF684633));
    }
    return _PrayerPalette(
      dark ? const Color(0xFF9A88C8) : const Color(0xFF493878),
      const Color(0xFF261E45),
    );
  }

  String _eyebrowFor(String title) {
    const emotions = [
      'Ansiedad',
      'Tristeza',
      'Paz interior',
      'Gratitud',
      'Perdón',
      'Fortaleza',
    ];
    const intentions = [
      'Salud',
      'Familia',
      'Trabajo',
      'Protección',
      'Pareja',
      'Hijos',
      'Sabiduría',
      'Prosperidad',
    ];
    if (emotions.contains(title)) return 'Para tu corazón';
    if (intentions.contains(title)) return 'Ponlo en sus manos';
    return 'Nuestra tradición';
  }

  String _subtitleFor(String title) {
    const subtitles = <String, String>{
      'Ansiedad': 'Encuentra calma y descanso',
      'Tristeza': 'Consuelo para este momento',
      'Paz interior': 'Vuelve al centro de tu alma',
      'Gratitud': 'Reconoce el bien de este día',
      'Perdón': 'Suelta el peso y comienza de nuevo',
      'Fortaleza': 'Ánimo para seguir adelante',
      'Salud': 'Confía tu bienestar y el de los tuyos',
      'Familia': 'Abraza a quienes más amas',
      'Trabajo': 'Entrega tus esfuerzos y proyectos',
      'Protección': 'Camina bajo su cuidado',
      'Pareja': 'Cuida el amor que construyen',
      'Hijos': 'Pon su camino en buenas manos',
      'Sabiduría': 'Luz para decidir con serenidad',
      'Prosperidad': 'Agradece y administra con propósito',
      'Padre Nuestro': 'La oración que nos reúne',
      'Ave María': 'Una plegaria de confianza',
      'Credo': 'Las palabras que sostienen la fe',
      'Espíritu Santo': 'Invoca su luz y presencia',
      'Sanación': 'Una plegaria para restaurar',
      'Consagración': 'Entrega tu camino a Dios',
      'Oraciones bíblicas': 'Ora acompañado por la Palabra',
      'Promesas bíblicas': 'Recuerda aquello que permanece',
      'Otras oraciones cristianas': 'Encuentra palabras para cada momento',
    };
    return subtitles[title] ?? 'Una pausa para encontrarte con Dios';
  }
}

class _PrayerPalette {
  final Color accent;
  final Color deep;
  const _PrayerPalette(this.accent, this.deep);
}
