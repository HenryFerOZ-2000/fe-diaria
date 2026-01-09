import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_button.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import 'emotion_passage_read_screen.dart';
import 'intention_prayer_read_screen.dart';
import 'traditional_prayer_screen.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    if (_adsRemoved) return;
    
    _adsService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted && !_adsRemoved) {
          setState(() {
            _bannerAd = ad;
          });
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Failed to load banner ad: $error');
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_adsRemoved && _bannerAd == null) {
            _loadBannerAd();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      showBanner: !_adsRemoved,
      bannerAd: _bannerAd,
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

}

