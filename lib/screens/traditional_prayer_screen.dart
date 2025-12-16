import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/traditional_prayer.dart';
import '../repositories/traditional_prayer_repository.dart';
import '../services/share_service.dart';
import 'reading_chat_screen.dart';

class TraditionalPrayerScreen extends StatefulWidget {
  final String prayerId;
  const TraditionalPrayerScreen({super.key, required this.prayerId});

  @override
  State<TraditionalPrayerScreen> createState() =>
      _TraditionalPrayerScreenState();
}

class _TraditionalPrayerScreenState extends State<TraditionalPrayerScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TraditionalPrayerRepository();

  bool _loading = true;
  bool _fadeIn = false;
  String? _error;
  TraditionalPrayer? _prayer;
  String? _text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _fadeIn = false;
    });
    try {
      final prayer = await _repo.findById(widget.prayerId);
      if (prayer == null) throw Exception('No se encontró la oración.');
      String finalText = prayer.text ?? '';
      if (prayer.type == 'bible_passage') {
        throw Exception(
            'Las oraciones tradicionales con pasajes bíblicos requieren la API. Por ahora, usa solo texto fijo.');
      }
      if (!mounted) return;
      setState(() {
        _prayer = prayer;
        _text = finalText;
        _loading = false;
      });
      Future.microtask(() {
        if (mounted) {
          setState(() => _fadeIn = true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openChat() {
    if (_prayer == null || _text == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingChatScreen(
          title: _prayer!.title,
          content: _text!,
          reference: null,
        ),
      ),
    );
  }

  void _share() {
    if (_prayer == null || _text == null) return;
    ShareService.shareAsText(
      text: _text!,
      reference: _prayer!.title,
      title: _prayer!.title,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                colors: [
                  Color(0xFF1E1C2A),
                  Color(0xFF2D2347),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : _prayer == null || _text == null
                        ? _ErrorState(
                            message: 'No se encontró contenido.',
                            onRetry: _load,
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
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
                                          _prayer!.title,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          _text!,
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
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _glassButton(
                                        icon: Icons.forum_outlined,
                                        label: 'Chat',
                                        onTap: _openChat,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: EdgeInsets.symmetric(horizontal: label != null ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ocurrió un problema',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
