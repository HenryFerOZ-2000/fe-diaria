import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';

/// Marco para pantallas con portada a sangre que hace scroll.
///
/// Mientras la portada oscura está bajo la hora, la barra de estado va en
/// claro y sin fondo. En cuanto la portada sale por arriba (se mide su alto
/// real con [coverKey]), aparece una franja lavanda sólida con un filete
/// fino y la barra pasa a texto oscuro.
class CoverScrollFrame extends StatefulWidget {
  const CoverScrollFrame({
    super.key,
    required this.coverKey,
    required this.child,
  });

  /// Clave puesta en la portada para medirla.
  final GlobalKey coverKey;

  /// El contenido desplazable (la portada va dentro, como primer hijo).
  final Widget child;

  @override
  State<CoverScrollFrame> createState() => _CoverScrollFrameState();
}

class _CoverScrollFrameState extends State<CoverScrollFrame> {
  bool _pastCover = false;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    final coverHeight = widget.coverKey.currentContext?.size?.height ?? 360;
    final top = MediaQuery.paddingOf(context).top;
    final past = n.metrics.pixels > coverHeight - top - 8;
    if (past != _pastCover) setState(() => _pastCover = past);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_pastCover ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _pastCover ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                // Franja sólida con filete fino: sin difuminados.
                child: Container(
                  height: top,
                  decoration: BoxDecoration(
                    color: p.background,
                    border: Border(bottom: BorderSide(color: p.lineSoft)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
