import 'package:flutter/material.dart';

import '../theme/verbum_context.dart';

/// Une una lista de pasos con un sendero punteado vertical que corre por
/// detrás, a [x] del borde izquierdo (el centro del indicador de cada paso).
class VDashedPath extends StatelessWidget {
  const VDashedPath({
    super.key,
    required this.children,
    this.x = 30,
    this.gap = 10,
  });

  final List<Widget> children;
  final double x;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLine(x: x, color: context.palette.inkSubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine({required this.x, required this.color});

  final double x;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = 24.0; y < size.height - 24; y += 9) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.x != x || old.color != color;
}
