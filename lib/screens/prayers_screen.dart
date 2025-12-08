import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_button.dart';
import '../models/prayer.dart';

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
      PrayerButton(icon: Icons.mood_bad, title: 'Ansiedad', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.sentiment_dissatisfied, title: 'Tristeza', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.self_improvement, title: 'Paz interior', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.wb_sunny_outlined, title: 'Gratitud', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.volunteer_activism, title: 'Perdón', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.fitness_center, title: 'Fortaleza', onTap: () {}),
    ];
  }

  List<Widget> _intentionOptions(BuildContext context) {
    return [
      PrayerButton(icon: Icons.local_hospital, title: 'Salud', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.family_restroom, title: 'Familia', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.work_outline, title: 'Trabajo', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.security_outlined, title: 'Protección', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.favorite_outline, title: 'Pareja', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.child_friendly, title: 'Hijos', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.school_outlined, title: 'Sabiduría', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.savings_outlined, title: 'Prosperidad', onTap: () {}),
    ];
  }

  List<Widget> _traditionalOptions(BuildContext context) {
    return [
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Padre Nuestro', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Ave María', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Credo', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Espíritu Santo', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Sanación', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Consagración', onTap: () {}),
      const SizedBox(height: 10),
      PrayerButton(icon: Icons.menu_book_rounded, title: 'Gratitud', onTap: () {}),
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

