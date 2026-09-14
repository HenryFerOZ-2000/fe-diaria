import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RachaCelebrationDialog extends StatefulWidget {
  final int totalDays;

  const RachaCelebrationDialog({super.key, required this.totalDays});

  @override
  State<RachaCelebrationDialog> createState() => _RachaCelebrationDialogState();
}

class _RachaCelebrationDialogState extends State<RachaCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool get _isMilestone =>
      const [3, 7, 14, 30, 50, 100, 365].contains(widget.totalDays);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .72, curve: Curves.easeOut),
    );
    _scale = Tween<double>(
      begin: .88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _controller.forward();
    });
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openJourney() {
    final navigator = Navigator.of(context);
    navigator.pop();
    Future.microtask(() => navigator.pushNamed('/streak'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF251F2D) : const Color(0xFFFFFCF7);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: scheme.outline.withValues(alpha: .14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .35 : .18),
                  blurRadius: 38,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -62,
                  top: -72,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE3AF59).withValues(alpha: .22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFFE1B467,
                              ).withValues(alpha: .12),
                              border: Border.all(
                                color: const Color(
                                  0xFFE1B467,
                                ).withValues(alpha: .30),
                              ),
                            ),
                          ),
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF1C77E), Color(0xFFC98243)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE0A857,
                                  ).withValues(alpha: .28),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFF2A2030),
                              size: 34,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: const Color(0xFFD29A45),
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isMilestone
                            ? 'UN HITO EN TU CAMINO'
                            : 'TU DÍA ESTÁ A SALVO',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB27A34),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMilestone
                            ? '${widget.totalDays} días de constancia'
                            : 'Un día más caminando con Dios',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: scheme.onSurface,
                          fontSize: 27,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isMilestone
                            ? 'Cada uno de estos días comenzó con una pequeña decisión: hacer espacio para Dios.'
                            : 'Hoy hiciste espacio para detenerte, escuchar y volver a lo esencial.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Continuar mi camino'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _openJourney,
                        child: const Text('Ver mi recorrido'),
                      ),
                    ],
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
