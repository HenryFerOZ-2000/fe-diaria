import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'cover_scroll_frame.dart';

/// Pestaña principal con portada: la portada hace scroll con el contenido,
/// la lista pasa por detrás de la barra flotante y, pasada la portada,
/// aparece una franja lavanda bajo la hora para que siga legible.
class CoverTabPage extends StatefulWidget {
  const CoverTabPage({super.key, required this.cover, required this.children});

  final Widget cover;
  final List<Widget> children;

  @override
  State<CoverTabPage> createState() => _CoverTabPageState();
}

class _CoverTabPageState extends State<CoverTabPage> {
  final _coverKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: CoverScrollFrame(
        coverKey: _coverKey,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            KeyedSubtree(key: _coverKey, child: widget.cover),
            ...widget.children,
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
