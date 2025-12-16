import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/missions_controller.dart';
import 'reading_chat_screen.dart';
import '../services/share_service.dart';

class ReadingScreen extends StatefulWidget {
  final String title;
  final String content;
  final String? reference;
  final ImageProvider? backgroundImage;
  final double progress; // 0.0 - 1.0
  final VoidCallback onComplete;
  // Opcionales para navegación secuencial
  final String? currentMissionId;
  final List<Mission>? missions;
  final void Function(Mission mission)? onOpenMission;
  final void Function(String content, String? reference)? onOpenChat;
  final void Function(String content, String? reference)? onShare;

  const ReadingScreen({
    super.key,
    required this.title,
    required this.content,
    this.reference,
    this.backgroundImage,
    this.progress = 0.0,
    required this.onComplete,
    this.currentMissionId,
    this.missions,
    this.onOpenMission,
    this.onOpenChat,
    this.onShare,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> with SingleTickerProviderStateMixin {
  bool _fadeIn = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() => _fadeIn = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundImage;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (bg != null)
            Image(
              image: bg,
              fit: BoxFit.cover,
            )
          else
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white),
                        onPressed: () {
                        if (widget.onShare != null) {
                          widget.onShare!(widget.content, widget.reference);
                        } else {
                          ShareService.shareAsText(
                            text: widget.content,
                            reference: widget.reference ?? widget.title,
                            title: widget.title,
                          );
                        }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Progress today',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: widget.progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: _fadeIn ? 1.0 : 0.0,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.content,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.reference != null && widget.reference!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.reference!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFB74D),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                          onTap: () {
                            if (widget.onOpenChat != null) {
                              widget.onOpenChat!(widget.content, widget.reference);
                            }
                            // Fallback: abre el chat si no se provee callback.
                            else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReadingChatScreen(
                                    title: widget.title,
                                    content: widget.content,
                                    reference: widget.reference,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      _primaryNextButton(),
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

  Widget _glassButton({required IconData icon, String? label, required VoidCallback onTap}) {
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

  Widget _primaryNextButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Siguiente',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 22),
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    widget.onComplete();

    // Si no se pasan datos de navegación secuencial, solo cerrar.
    if (widget.missions == null ||
        widget.currentMissionId == null ||
        widget.onOpenMission == null) {
      Navigator.of(context).pop();
      return;
    }

    final idx = widget.missions!.indexWhere((m) => m.id == widget.currentMissionId);
    if (idx != -1 && idx + 1 < widget.missions!.length) {
      final next = widget.missions![idx + 1];
      Navigator.of(context).pop();
      widget.onOpenMission!(next);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has completado tus misiones de hoy')),
      );
      Navigator.of(context).pop();
    }
  }
}

