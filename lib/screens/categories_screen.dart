import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import 'traditional_prayers_religion_selection_screen.dart';
import 'category_prayers_screen.dart';
import 'emotion_selection_screen.dart';
import 'novena_screen.dart';
import 'devotionals_screen.dart';
import 'psalms_screen.dart';
import 'saints_screen.dart';
import 'night_prayers_screen.dart';
import 'prayers_by_intention_screen.dart';
import 'daily_intentions_screen.dart';
import 'rosary_guide_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/section_title.dart';
import '../widgets/category_card.dart';
import '../theme/app_theme.dart';

/// Pantalla principal de Categorías con acceso a todos los módulos
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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
    // Actualizar estado de anuncios removidos
    final storage = StorageService();
    final adsRemovedNow = storage.getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    } else if (!adsRemovedNow && _adsRemoved) {
      _adsRemoved = false;
      _loadBannerAd();
    } else if (!adsRemovedNow && _bannerAd == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adsRemoved && _bannerAd == null) {
          _loadBannerAd();
        }
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppScaffold(
      title: 'Categorías',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: 'Explora nuestras categorías',
                    subtitle: 'Encuentra oraciones, devocionales y recursos espirituales',
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Grid de categorías con diseño moderno
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.95,
                    children: [
                      CategoryCard(
                        title: 'Devocionales diarios',
                        description: 'Reflexiones diarias con versículos',
                        icon: Icons.book_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DevotionalsScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Salmos por categoría',
                        description: 'Salmos de protección, agradecimiento y consuelo',
                        icon: Icons.library_books_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PsalmsScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Oraciones tradicionales',
                        description: 'Oraciones clásicas de la tradición cristiana',
                        icon: Icons.menu_book_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TraditionalPrayersReligionSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Oración para…',
                        description: 'Oraciones para situaciones específicas',
                        icon: Icons.favorite_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CategoryPrayersScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Cómo te sientes hoy',
                        description: 'Oraciones personalizadas según tu emoción',
                        icon: Icons.emoji_emotions_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EmotionSelectionScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Oraciones para dormir',
                        description: 'Oraciones de paz y descanso nocturno',
                        icon: Icons.bedtime_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NightPrayersScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Peticiones especiales',
                        description: 'Oraciones por salud, trabajo, familia y más',
                        icon: Icons.healing_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PrayersByIntentionScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Intenciones del día',
                        description: 'Guarda y reza por tus intenciones personales',
                        icon: Icons.edit_note_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DailyIntentionsScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Guía del Rosario',
                        description: 'Aprende a rezar el rosario paso a paso',
                        icon: Icons.church_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RosaryGuideScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Santos del día',
                        description: 'Conoce a los santos y sus oraciones',
                        icon: Icons.auto_stories_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SaintsScreen(),
                            ),
                          );
                        },
                      ),
                      CategoryCard(
                        title: 'Novena',
                        description: 'Novena de Navidad día a día',
                        icon: Icons.calendar_view_day_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NovenaScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Padding adicional al final para evitar overflow
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          // Banner Ad fijo en la parte inferior
          if (!_adsRemoved)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: _bannerAd != null ? _bannerAd!.size.height.toDouble() : 50,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface
                    : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

}

