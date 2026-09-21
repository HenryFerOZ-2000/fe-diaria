import 'package:flutter/material.dart';

import '../models/verse.dart';

class DailyVerseWidgetPreview extends StatelessWidget {
  const DailyVerseWidgetPreview({super.key, required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFFFF8EE) : const Color(0xFF2A2030);
    final muted = dark ? const Color(0xFFC7BBC8) : const Color(0xFF746A72);
    final primary = dark ? const Color(0xFFE4D3F4) : const Color(0xFF493878);
    final gold = dark ? const Color(0xFFE5BD7B) : const Color(0xFFB58A45);
    final gradient = dark
        ? const [Color(0xFF1B1623), Color(0xFF251D30), Color(0xFF332438)]
        : const [Color(0xFFFFFCF7), Color(0xFFF8F1E7), Color(0xFFF0E5D8)];

    return Semantics(
      container: true,
      label: 'Versículo del día, ${verse.reference}: ${verse.text}',
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 340;
            final padding = compact ? 16.0 : 20.0;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                  stops: const [0, .56, 1],
                ),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: gold.withValues(alpha: .28)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A2030).withValues(alpha: .14),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: compact ? -44 : -52,
                    top: compact ? -52 : -62,
                    child: IgnorePointer(
                      child: Container(
                        width: compact ? 126 : 156,
                        height: compact ? 126 : 156,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withValues(alpha: dark ? .10 : .07),
                            width: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PreviewHeader(
                        primary: primary,
                        gold: gold,
                        muted: muted,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '“',
                            style: TextStyle(
                              color: gold,
                              fontFamily: 'serif',
                              fontSize: compact ? 29 : 34,
                              height: .9,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              verse.text,
                              maxLines: compact ? 4 : 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: text,
                                fontFamily: 'serif',
                                fontSize: compact ? 18 : 21,
                                fontWeight: FontWeight.w600,
                                height: 1.34,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gold.withValues(alpha: .75),
                              primary.withValues(alpha: .08),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              verse.reference,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primary,
                                fontSize: compact ? 12 : 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            'RV1909',
                            style: TextStyle(
                              color: muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'Abrir',
                              style: TextStyle(
                                color: dark
                                    ? const Color(0xFF241A2B)
                                    : const Color(0xFFFFFCF7),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.primary,
    required this.gold,
    required this.muted,
    required this.compact,
  });

  final Color primary;
  final Color gold;
  final Color muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VerbumMark(color: gold, size: compact ? 31 : 35),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERBUM',
                maxLines: 1,
                style: TextStyle(
                  color: primary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'PALABRA DEL DÍA',
                maxLines: 1,
                style: TextStyle(
                  color: gold,
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .9,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: gold.withValues(alpha: .24)),
          ),
          child: Text(
            'HOY',
            style: TextStyle(
              color: muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerbumMark extends StatelessWidget {
  const _VerbumMark({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _VerbumMarkPainter(color)),
    );
  }
}

class _VerbumMarkPainter extends CustomPainter {
  const _VerbumMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .055;
    for (final factor in const [.46, .34, .22]) {
      canvas.drawCircle(center, size.width * factor, stroke);
    }

    final cross = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final verticalWidth = size.width * .085;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - verticalWidth / 2,
        size.height * .22,
        verticalWidth,
        size.height * .70,
      ),
      cross,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .27,
        size.height * .45,
        size.width * .46,
        verticalWidth,
      ),
      cross,
    );
  }

  @override
  bool shouldRepaint(covariant _VerbumMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
