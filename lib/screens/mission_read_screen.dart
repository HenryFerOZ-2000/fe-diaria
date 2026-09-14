import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';

class MissionReadScreen extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onCompleted;

  const MissionReadScreen({
    super.key,
    required this.title,
    required this.content,
    required this.onCompleted,
  });

  @override
  State<MissionReadScreen> createState() => _MissionReadScreenState();
}

class _MissionReadScreenState extends State<MissionReadScreen> {
  Timer? _timer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!_completed) {
        _completed = true;
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrayerReadingExperience(
      loading: false,
      category: 'Misión de hoy',
      title: widget.title,
      text: widget.content,
      accent: const Color(0xFF77649A),
      onBack: () => Navigator.pop(context),
      onShare: () => ShareService.shareAsText(
        text: widget.content,
        reference: widget.title,
        title: widget.title,
      ),
      onNext: () {
        if (!_completed) {
          widget.onCompleted();
          _completed = true;
        }
        Navigator.pop(context);
      },
    );
  }

  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.98),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.tertiary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.content,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.65,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ShareService.shareAsText(
                          text: widget.content,
                          reference: widget.title,
                          title: widget.title,
                        );
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Compartir'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!_completed) {
                          widget.onCompleted();
                          _completed = true;
                        }
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Cerrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
    );
  }
}
