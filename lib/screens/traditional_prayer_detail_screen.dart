import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/traditional_prayers_service.dart';
import '../services/share_service.dart';
import '../widgets/prayer_reading_experience.dart';

/// Pantalla de detalle de una oración tradicional
class TraditionalPrayerDetailScreen extends StatefulWidget {
  final String religion;
  final String category;
  final String prayerKey;

  const TraditionalPrayerDetailScreen({
    super.key,
    required this.religion,
    required this.category,
    required this.prayerKey,
  });

  @override
  State<TraditionalPrayerDetailScreen> createState() =>
      _TraditionalPrayerDetailScreenState();
}

class _TraditionalPrayerDetailScreenState
    extends State<TraditionalPrayerDetailScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  Map<String, dynamic>? _prayer;
  bool _isLoading = true;
  bool _fadeIn = false;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    try {
      await _service.loadPrayers();
      if (!mounted) return;
      setState(() {
        _prayer = _service.getPrayer(
          widget.religion,
          widget.category,
          widget.prayerKey,
        );
        _isLoading = false;
        _fadeIn = true;
      });
    } catch (e) {
      debugPrint('Error loading prayer: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() => super.dispose();

  void _share() {
    if (_prayer == null) return;
    final title = _prayer!['titulo'] as String? ?? widget.prayerKey;
    final text = _prayer!['texto'] as String? ?? '';
    ShareService.shareAsText(text: text, reference: title, title: title);
  }

  @override
  Widget build(BuildContext context) {
    return PrayerReadingExperience(
      loading: _isLoading,
      error: !_isLoading && _prayer == null
          ? 'No se encontró esta oración.'
          : null,
      category: widget.category,
      title: _prayer?['titulo'] as String? ?? widget.prayerKey,
      text: _prayer?['texto'] as String?,
      accent: const Color(0xFF8D7BC2),
      onBack: () => Navigator.pop(context),
      onRetry: _loadPrayer,
      onShare: _share,
    );
  }

  // ignore: unused_element
  Widget _buildLegacy(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1C2A), Color(0xFF2D2347)],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _prayer == null
                ? _ErrorState(
                    message: 'No se encontró contenido.',
                    onRetry: _loadPrayer,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.share_outlined,
                                color: Colors.white,
                              ),
                              onPressed: _share,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          opacity: _fadeIn ? 1.0 : 0.0,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _prayer!['titulo'] as String? ??
                                      widget.prayerKey,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _prayer!['texto'] as String? ?? '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
