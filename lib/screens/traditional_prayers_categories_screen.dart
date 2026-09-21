import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/traditional_prayers_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/traditional_prayer_library.dart';
import '../widgets/verbum_header_actions.dart';
import 'traditional_prayers_list_screen.dart';
import 'traditional_prayers_religion_selection_screen.dart';

/// Biblioteca de categorías según la tradición elegida por la persona.
class TraditionalPrayersCategoriesScreen extends StatefulWidget {
  const TraditionalPrayersCategoriesScreen({super.key});

  @override
  State<TraditionalPrayersCategoriesScreen> createState() =>
      _TraditionalPrayersCategoriesScreenState();
}

class _TraditionalPrayersCategoriesScreenState
    extends State<TraditionalPrayersCategoriesScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  String _religion = '';
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) _loadBannerAd();
  }

  Future<void> _loadData() async {
    try {
      await _service.loadPrayers();
      final religion = StorageService()
          .getValidatedTraditionalPrayersReligion();
      if (religion.isEmpty) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const TraditionalPrayersReligionSelectionScreen(),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _religion = religion;
        _categories = _service.getCategories(religion);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading traditional prayers: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadBannerAd() {
    if (_adsRemoved) return;
    _adsService.loadBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (ad) {
        if (mounted && !_adsRemoved) {
          setState(() => _bannerAd = ad);
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
    _syncAdPreference();
    final traditionName = _traditionName(_religion);

    return AppScaffold(
      showGuestNotice: false,
      showBanner: !_adsRemoved,
      bannerAd: _bannerAd,
      centerTitle: false,
      titleWidget: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          'Oraciones tradicionales',
          maxLines: 1,
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: VerbumHeaderButton(
            icon: Icons.tune_rounded,
            tooltip: 'Cambiar tradición',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const TraditionalPrayersReligionSelectionScreen(),
                ),
              );
              if (mounted) _loadData();
            },
          ),
        ),
      ],
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _categories.isEmpty
          ? const PrayerLibraryEmptyState(
              title: 'No encontramos categorías',
              message:
                  'Puedes cambiar tu tradición o intentarlo nuevamente más tarde.',
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                PrayerLibraryHero(
                  kicker: 'TU BIBLIOTECA DE ORACIÓN',
                  title: 'Elige cómo quieres orar',
                  description:
                      'Explora palabras recibidas por la tradición y encuentra una oración para este momento.',
                  icon: Icons.auto_stories_rounded,
                  accent: const Color(0xFFB58A45),
                  badge: traditionName,
                ),
                const SizedBox(height: 24),
                for (var index = 0; index < _categories.length; index++) ...[
                  _categoryCard(context, _categories[index]),
                  if (index < _categories.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  Widget _categoryCard(BuildContext context, String category) {
    final presentation = _categoryPresentation(category);
    return PrayerLibraryCard(
      title: _service.getCategoryDisplayName(category),
      eyebrow: presentation.eyebrow,
      subtitle: presentation.subtitle,
      icon: presentation.icon,
      accent: presentation.accent,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TraditionalPrayersListScreen(
            religion: _religion,
            category: category,
          ),
        ),
      ),
    );
  }

  void _syncAdPreference() {
    final adsRemovedNow = StorageService().getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    } else if (!adsRemovedNow && _adsRemoved) {
      _adsRemoved = false;
      _loadBannerAd();
    } else if (!adsRemovedNow && _bannerAd == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adsRemoved && _bannerAd == null) _loadBannerAd();
      });
    }
  }
}

String _traditionName(String religion) {
  switch (religion) {
    case 'catolica':
      return 'Tradición católica';
    case 'cristiana':
      return 'Tradición evangélica';
    case 'general':
      return 'Cristiana general';
    default:
      return 'Tu tradición';
  }
}

_CategoryCardPresentation _categoryPresentation(String category) {
  switch (category) {
    case 'biblicas':
      return const _CategoryCardPresentation(
        eyebrow: 'Ora con la Palabra',
        subtitle: 'Padre Nuestro, salmos y oraciones inspiradas en la Biblia',
        icon: Icons.menu_book_rounded,
        accent: Color(0xFF77649A),
      );
    case 'promesas':
      return const _CategoryCardPresentation(
        eyebrow: 'Recuerda su fidelidad',
        subtitle: 'Promesas bíblicas para fortalecer la esperanza',
        icon: Icons.auto_awesome_rounded,
        accent: Color(0xFFB58A45),
      );
    case 'otras':
      return const _CategoryCardPresentation(
        eyebrow: 'Para cada momento',
        subtitle: 'Oraciones para entregar tu vida cotidiana a Dios',
        icon: Icons.favorite_outline_rounded,
        accent: Color(0xFF5F8178),
      );
    case 'basicas':
      return const _CategoryCardPresentation(
        eyebrow: 'Palabras esenciales',
        subtitle: 'Oraciones fundamentales de la tradición cristiana',
        icon: Icons.volunteer_activism_rounded,
        accent: Color(0xFF77649A),
      );
    case 'arcangeles':
      return const _CategoryCardPresentation(
        eyebrow: 'Pide protección',
        subtitle: 'Oraciones tradicionales a los arcángeles',
        icon: Icons.shield_outlined,
        accent: Color(0xFF536C91),
      );
    case 'del_dia':
      return const _CategoryCardPresentation(
        eyebrow: 'Acompaña tu jornada',
        subtitle: 'Oraciones para comenzar y terminar el día',
        icon: Icons.wb_sunny_outlined,
        accent: Color(0xFFB58A45),
      );
    default:
      return const _CategoryCardPresentation(
        eyebrow: 'Tu momento de oración',
        subtitle: 'Una colección para detenerte y encontrarte con Dios',
        icon: Icons.auto_stories_rounded,
        accent: Color(0xFF77649A),
      );
  }
}

class _CategoryCardPresentation {
  const _CategoryCardPresentation({
    required this.eyebrow,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String eyebrow;
  final String subtitle;
  final IconData icon;
  final Color accent;
}
