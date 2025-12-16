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
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _show = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE9E9E9),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _show ? 1.0 : 0.95,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _show ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 500),
                          scale: _scale.value,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _opacity.value,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFFA726),
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _opacity,
                      child: Column(
                        children: [
                          Text(
                            '¡${widget.totalDays} días de racha!',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFF222222),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Sigue así, estás haciendo un gran trabajo!',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF555555),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'CONTINUAR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

