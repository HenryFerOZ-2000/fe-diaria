import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_button.dart';
import '../models/prayer.dart';
import 'emotion_passage_read_screen.dart';
import 'intention_prayer_read_screen.dart';
import 'traditional_prayer_screen.dart';

class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      titleWidget: Row(
        children: [
          Text(
            'Oraciones',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final saved = provider.savedPrayers;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, Icons.favorite_border, 'Tus oraciones'),
                const SizedBox(height: 10),
                if (saved.isEmpty)
                  Text(
                    'Aún no guardas oraciones. Guarda tus favoritas para abrirlas aquí rápidamente.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: saved
                        .map((p) => PrayerButton(
                              icon: Icons.menu_book_rounded,
                              title: p.title,
                              onTap: () {
                                _openPrayerDetail(context, p);
                              },
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 24),
                _sectionTitle(context, Icons.emoji_emotions_outlined, 'Oraciones por emoción'),
                const SizedBox(height: 10),
                ..._emotionOptions(context),
                const SizedBox(height: 24),
                _sectionTitle(context, Icons.healing_outlined, 'Oraciones por intención'),
                const SizedBox(height: 10),
                ..._intentionOptions(context),
                const SizedBox(height: 24),
                _sectionTitle(context, Icons.church_outlined, 'Oraciones tradicionales'),
                const SizedBox(height: 10),
                ..._traditionalOptions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  List<Widget> _emotionOptions(BuildContext context) {
    return [
      PrayerButton(
        icon: Icons.mood_bad,
        title: 'Ansiedad',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'ansiedad'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.sentiment_dissatisfied,
        title: 'Tristeza',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'tristeza'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.self_improvement,
        title: 'Paz interior',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'paz_interior'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.wb_sunny_outlined,
        title: 'Gratitud',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'gratitud'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.volunteer_activism,
        title: 'Perdón',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'perdon'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.fitness_center,
        title: 'Fortaleza',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const EmotionPassageReadScreen(emotionKey: 'fortaleza'),
          ),
        ),
      ),
    ];
  }

  List<Widget> _intentionOptions(BuildContext context) {
    return [
      PrayerButton(
        icon: Icons.local_hospital,
        title: 'Salud',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'salud'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.family_restroom,
        title: 'Familia',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'familia'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.work_outline,
        title: 'Trabajo',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'trabajo'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.security_outlined,
        title: 'Protección',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'proteccion'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.favorite_outline,
        title: 'Pareja',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'pareja'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.child_friendly,
        title: 'Hijos',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'hijos'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.school_outlined,
        title: 'Sabiduría',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'sabiduria'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.savings_outlined,
        title: 'Prosperidad',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IntentionPrayerReadScreen(categoryKey: 'prosperidad'),
          ),
        ),
      ),
    ];
  }

  List<Widget> _traditionalOptions(BuildContext context) {
    return [
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Padre Nuestro',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'padre_nuestro'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Ave María',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'ave_maria'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Credo',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'credo'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Espíritu Santo',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'espiritu_santo'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Sanación',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'sanacion'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Consagración',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'consagracion'),
          ),
        ),
      ),
      const SizedBox(height: 10),
      PrayerButton(
        icon: Icons.menu_book_rounded,
        title: 'Gratitud',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const TraditionalPrayerScreen(prayerId: 'gratitud_trad'),
          ),
        ),
      ),
    ];
  }

  void _openPrayerDetail(BuildContext context, Prayer prayer) {
    // TODO: Navegar a detalle real de oración o abrir modal/route existente.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                prayer.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                prayer.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

