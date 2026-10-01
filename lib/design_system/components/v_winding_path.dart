import 'package:flutter/material.dart';

import '../photos/verbum_photos.dart';
import '../theme/verbum_context.dart';
import 'v_photo_frame.dart';

/// Un paso del sendero: foto, título y una insignia de estado.
class VWindingStep {
  const VWindingStep({
    required this.photo,
    required this.title,
    required this.semanticLabel,
    this.badge,
    this.onTap,
  });

  final VerbumPhotos photo;
  final String title;

  /// Lo que se anuncia: "Día 2, Confía, hoy".
  final String semanticLabel;

  /// "Hecho", "Hoy", "Mañana"…
  final Widget? badge;

  /// Nulo = bloqueado.
  final VoidCallback? onTap;
}

/// Pasos unidos por un sendero punteado que serpentea: las fotos alternan
/// izquierda y derecha, y la curva las enlaza.
class VWindingPath extends StatelessWidget {
  const VWindingPath({super.key, required this.steps, this.nodeSize = 76});

  final List<VWindingStep> steps;
  final double nodeSize;

  @override
  Widget build(BuildContext context) {
    // La fila crece con el texto ampliado.
    final rowHeight =
        nodeSize + MediaQuery.textScalerOf(context).scale(48).clamp(48, 120);
    return CustomPaint(
      painter: _WindingPainter(
        count: steps.length,
        rowHeight: rowHeight,
        nodeSize: nodeSize,
        color: context.palette.gold,
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            SizedBox(
              height: rowHeight,
              child: _StepRow(
                step: steps[i],
                right: i.isOdd,
                nodeSize: nodeSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.right,
    required this.nodeSize,
  });

  final VWindingStep step;
  final bool right;
  final double nodeSize;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final locked = step.onTap == null;
    final photo = Opacity(
      opacity: locked ? 0.55 : 1,
      child: VPhotoFrame(step.photo, width: nodeSize, aspectRatio: 1),
    );
    final text = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            textAlign: right ? TextAlign.end : TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: type.bodyStrong.copyWith(
              color: locked ? context.palette.inkMuted : null,
            ),
          ),
          if (step.badge != null) ...[const SizedBox(height: 6), step.badge!],
        ],
      ),
    );

    return Semantics(
      button: !locked,
      enabled: !locked,
      label: step.semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: step.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: right
              ? [
                  const SizedBox(width: 48),
                  text,
                  const SizedBox(width: 14),
                  photo,
                ]
              : [
                  photo,
                  const SizedBox(width: 14),
                  text,
                  const SizedBox(width: 48),
                ],
        ),
      ),
    );
  }
}

class _WindingPainter extends CustomPainter {
  const _WindingPainter({
    required this.count,
    required this.rowHeight,
    required this.nodeSize,
    required this.color,
  });

  final int count;
  final double rowHeight;
  final double nodeSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset center(int i) => Offset(
      i.isOdd ? size.width - nodeSize / 2 : nodeSize / 2,
      i * rowHeight + rowHeight / 2,
    );

    for (var i = 0; i < count - 1; i++) {
      final a = center(i);
      final b = center(i + 1);
      // Curva en S: sale por debajo de una foto y entra por arriba de la
      // siguiente, cruzando entre las filas sin pisar el texto.
      final start = Offset(a.dx, a.dy + nodeSize / 2 + 4);
      final end = Offset(b.dx, b.dy - nodeSize / 2 - 4);
      final bend = (end.dy - start.dy) * 0.9;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx,
          start.dy + bend,
          end.dx,
          end.dy - bend,
          end.dx,
          end.dy,
        );
      for (final metric in path.computeMetrics()) {
        for (var d = 6.0; d < metric.length - 4; d += 10) {
          canvas.drawPath(metric.extractPath(d, d + 5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WindingPainter old) =>
      old.count != count ||
      old.rowHeight != rowHeight ||
      old.nodeSize != nodeSize ||
      old.color != color;
}
