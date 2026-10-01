import 'package:flutter/material.dart';

import '../icons/verbum_icons.dart';
import '../theme/verbum_context.dart';
import 'v_icon.dart';

/// Portada de libro dibujada: lomo a la izquierda, rótulo arriba, título
/// grande abajo e icono de marca de agua. Proporción 2:3.
class VBookCover extends StatelessWidget {
  const VBookCover({
    super.key,
    required this.title,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    this.caption,
    this.width = 96,
  });

  final String title;
  final String? caption;
  final Color background;
  final Color foreground;
  final VerbumIcons icon;
  final VoidCallback onTap;
  final double width;

  /// Achica el título para que su palabra más ancha quepa entera: nunca
  /// se parte "Corintios" en dos líneas.
  double _titleSize(String title, TextStyle style) {
    final base = width * .17;
    final available = width * .73;
    var widest = 0.0;
    for (final word in title.split(' ')) {
      final painter = TextPainter(
        text: TextSpan(
          text: word,
          style: style.copyWith(fontSize: base),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest <= available ? base : base * available / widest * .98;
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final radius = BorderRadius.horizontal(
      left: Radius.circular(width * .06),
      right: Radius.circular(width * .14),
    );

    return Semantics(
      button: true,
      label: caption == null ? title : '$title, $caption',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Material(
            color: background,
            elevation: 5,
            shadowColor: context.palette.ink.withValues(alpha: .28),
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned(
                    right: -width * .18,
                    bottom: -width * .12,
                    child: VIcon(
                      icon,
                      weight: VIconWeight.duotone,
                      size: width * .78,
                      color: foreground.withValues(alpha: .2),
                    ),
                  ),
                  // Lomo: sombra y filete, como un libro encuadernado.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: width * .1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: .22),
                            Colors.black.withValues(alpha: .04),
                          ],
                        ),
                        border: Border(
                          right: BorderSide(
                            color: foreground.withValues(alpha: .25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      width * .17,
                      width * .12,
                      width * .1,
                      width * .12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caption != null)
                          Text(
                            caption!.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: type.rubric.copyWith(
                              color: foreground.withValues(alpha: .75),
                              fontSize: width * .075,
                              letterSpacing: 1,
                              height: 1.2,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          width: width * .22,
                          height: 2,
                          color: foreground.withValues(alpha: .5),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: type.heading.copyWith(
                            color: foreground,
                            fontSize: _titleSize(title, type.heading),
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
