import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';

/// Pestaña principal con portada: la portada hace scroll con el contenido,
/// la lista pasa por detrás de la barra flotante y, pasada la portada,
/// aparece una franja lavanda bajo la hora para que siga legible.
class CoverTabPage extends StatefulWidget {
  const CoverTabPage({
    super.key,
    required this.cover,
    required this.children,
    this.scrimAfter = 300,
  });

  final Widget cover;
  final List<Widget> children;

  /// Desplazamiento a partir del cual se muestra la franja.
  final double scrimAfter;

  @override
  State<CoverTabPage> createState() => _CoverTabPageState();
}

class _CoverTabPageState extends State<CoverTabPage> {
  bool _pastCover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final padding = MediaQuery.paddingOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_pastCover ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          children: [
            NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                final past = n.metrics.pixels > widget.scrimAfter;
                if (past != _pastCover) setState(() => _pastCover = past);
                return false;
              },
              child: ListView(
                padding: EdgeInsets.only(bottom: padding.bottom + 24),
                physics: const BouncingScrollPhysics(),
                children: [widget.cover, ...widget.children],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _pastCover ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: padding.top,
                    color: p.background.withValues(alpha: .96),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila superior de las portadas: configuración a la izquierda y perfil a
/// la derecha.
class CoverTopActions extends StatelessWidget {
  const CoverTopActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VGlassButton(
          icon: VerbumIcons.slidersHorizontal,
          tooltip: 'Configuración',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
        const Spacer(),
        VGlassButton(
          icon: VerbumIcons.user,
          tooltip: 'Mi perfil',
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
        ),
      ],
    );
  }
}
