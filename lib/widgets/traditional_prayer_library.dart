import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PrayerLibraryHero extends StatelessWidget {
  const PrayerLibraryHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.badge,
  });

  final String kicker;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF251D3D),
            Color.alphaBlend(
              accent.withValues(alpha: .55),
              const Color(0xFF39294B),
            ),
            const Color(0xFF674B3D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF261E45).withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Icon(
              icon,
              size: 132,
              color: Colors.white.withValues(alpha: .055),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: .34)),
                    ),
                    child: Icon(icon, color: const Color(0xFFF1D79C), size: 21),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .12),
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                kicker,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE6C57F),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.55,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: .76),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrayerLibraryCard extends StatefulWidget {
  const PrayerLibraryCard({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String eyebrow;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<PrayerLibraryCard> createState() => _PrayerLibraryCardState();
}

class _PrayerLibraryCardState extends State<PrayerLibraryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF292431) : const Color(0xFFFFFCF7);

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: AnimatedScale(
        scale: _pressed ? .982 : 1,
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
              padding: const EdgeInsets.fromLTRB(15, 15, 13, 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      widget.accent.withValues(alpha: dark ? .15 : .08),
                      surface,
                    ),
                    surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accent.withValues(alpha: dark ? .28 : .18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: dark ? .12 : .10),
                    blurRadius: _pressed ? 12 : 22,
                    offset: Offset(0, _pressed ? 5 : 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: -11,
                    top: -25,
                    child: Icon(
                      widget.icon,
                      size: 92,
                      color: widget.accent.withValues(alpha: .045),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.accent,
                              Color.lerp(
                                widget.accent,
                                const Color(0xFF261E45),
                                .46,
                              )!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: .22),
                              blurRadius: 11,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.eyebrow.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: widget.accent,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: scheme.onSurface,
                                fontSize: 17,
                                height: 1.14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: scheme.onSurfaceVariant,
                                fontSize: 10.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSlide(
                        offset: _pressed ? const Offset(.15, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: .10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: widget.accent,
                            size: 17,
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
    );
  }
}

class PrayerLibraryEmptyState extends StatelessWidget {
  const PrayerLibraryEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: scheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
