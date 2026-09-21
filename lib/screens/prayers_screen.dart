import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_button.dart';
import '../widgets/verbum_header_actions.dart';
import '../services/storage_service.dart';
import '../faith/faith_tradition.dart';
import '../faith/tradition_capabilities.dart';
import 'emotion_passage_read_screen.dart';
import 'intention_prayer_read_screen.dart';
import 'traditional_prayer_screen.dart';
import 'traditional_prayers_list_screen.dart';
import 'content_sources_screen.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  FaithTradition _currentTradition() {
    return faithTraditionFromStorageString(
      StorageService().getValidatedTraditionalPrayersReligion(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tradition = _currentTradition();

    return AppScaffold(
      showBanner: false,
      centerTitle: false,
      titleWidget: Text(
        'Oraciones',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      actions: const [VerbumHeaderActions()],
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _prayerHero(context, tradition),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.library_books_outlined),
                  title: const Text('Tradiciones y fuentes'),
                  subtitle: const Text('Conoce el origen de lo que lees'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContentSourcesScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _sectionTitle(
                  context,
                  Icons.emoji_emotions_outlined,
                  'Oraciones por emoción',
                ),
                const SizedBox(height: 10),
                ..._emotionOptions(context),
                const SizedBox(height: 24),
                _sectionTitle(
                  context,
                  Icons.healing_outlined,
                  'Oraciones por intención',
                ),
                const SizedBox(height: 10),
                ..._intentionOptions(context),
                const SizedBox(height: 24),
                _sectionTitle(
                  context,
                  tradition == FaithTradition.evangelical ||
                          tradition == FaithTradition.general
                      ? Icons.menu_book_outlined
                      : Icons.church_outlined,
                  TraditionUiStrings.prayersTraditionalSectionTitle(tradition),
                ),
                const SizedBox(height: 10),
                ..._traditionalOptions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _prayerHero(BuildContext context, FaithTradition tradition) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF281F45), Color(0xFF51407D), Color(0xFF79614A)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -18,
            child: Icon(
              Icons.auto_awesome,
              size: 112,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UN MOMENTO PARA TI',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD8B875),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Respira. Dios\nestá aquí.',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tradition == FaithTradition.evangelical ||
                        tradition == FaithTradition.general
                    ? 'Encuentra una oración nacida de la Palabra.'
                    : 'Encuentra palabras para lo que hoy lleva tu corazón.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: .74),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Icon(icon, size: 20, color: colorScheme.primary),
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
    final tradition = _currentTradition();
    if (tradition == FaithTradition.evangelical ||
        tradition == FaithTradition.general) {
      return [
        PrayerButton(
          icon: Icons.menu_book_rounded,
          title: 'Oraciones bíblicas',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TraditionalPrayersListScreen(
                religion: 'cristiana',
                category: 'biblicas',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PrayerButton(
          icon: Icons.auto_stories_rounded,
          title: 'Promesas bíblicas',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TraditionalPrayersListScreen(
                religion: 'cristiana',
                category: 'promesas',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        PrayerButton(
          icon: Icons.favorite_outline_rounded,
          title: 'Otras oraciones cristianas',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TraditionalPrayersListScreen(
                religion: 'cristiana',
                category: 'otras',
              ),
            ),
          ),
        ),
      ];
    }

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
            builder: (_) => const TraditionalPrayerScreen(prayerId: 'credo'),
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
            builder: (_) => const TraditionalPrayerScreen(prayerId: 'sanacion'),
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
    ];
  }
}
