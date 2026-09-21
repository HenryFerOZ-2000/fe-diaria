import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/traditional_prayers_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/traditional_prayer_library.dart';
import '../widgets/verbum_header_actions.dart';
import 'traditional_prayer_detail_screen.dart';

/// Biblioteca de oraciones pertenecientes a una categoría concreta.
class TraditionalPrayersListScreen extends StatefulWidget {
  final String religion;
  final String category;

  const TraditionalPrayersListScreen({
    super.key,
    required this.religion,
    required this.category,
  });

  @override
  State<TraditionalPrayersListScreen> createState() =>
      _TraditionalPrayersListScreenState();
}

class _TraditionalPrayersListScreenState
    extends State<TraditionalPrayersListScreen> {
  final TraditionalPrayersService _service = TraditionalPrayersService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  Map<String, dynamic> _prayers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayers();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) _loadBannerAd();
  }

  Future<void> _loadPrayers() async {
    try {
      await _service.loadPrayers();
      if (!mounted) return;
      setState(() {
        _prayers = _service.getPrayersByCategory(
          widget.religion,
          widget.category,
        );
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading prayers: $error');
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
    final presentation = _presentationFor(widget.category);
    final displayName = _service.getCategoryDisplayName(widget.category);

    return AppScaffold(
      showGuestNotice: false,
      showBanner: !_adsRemoved,
      bannerAd: _bannerAd,
      centerTitle: false,
      titleWidget: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          displayName,
          maxLines: 1,
          style: GoogleFonts.playfairDisplay(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: const [VerbumHeaderActions()],
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _prayers.isEmpty
          ? const PrayerLibraryEmptyState(
              title: 'Aún no hay oraciones aquí',
              message:
                  'Estamos preparando este espacio para acompañar mejor tu oración.',
            )
          : _PrayerList(
              prayers: _prayers,
              religion: widget.religion,
              category: widget.category,
              displayName: displayName,
              presentation: presentation,
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

class _PrayerList extends StatelessWidget {
  const _PrayerList({
    required this.prayers,
    required this.religion,
    required this.category,
    required this.displayName,
    required this.presentation,
  });

  final Map<String, dynamic> prayers;
  final String religion;
  final String category;
  final String displayName;
  final _CategoryPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final entries = prayers.entries.toList();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: PrayerLibraryHero(
              kicker: presentation.kicker,
              title: displayName,
              description: presentation.description,
              icon: presentation.icon,
              accent: presentation.accent,
              badge: '${entries.length} para acompañarte',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          sliver: SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final prayer = entry.value as Map<String, dynamic>;
              final title = prayer['titulo'] as String? ?? entry.key;
              final item = _itemPresentation(title, category);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == entries.length - 1 ? 0 : 12,
                ),
                child: PrayerLibraryCard(
                  title: title,
                  eyebrow: item.eyebrow,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  accent: item.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TraditionalPrayerDetailScreen(
                        religion: religion,
                        category: category,
                        prayerKey: entry.key,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

_CategoryPresentation _presentationFor(String category) {
  switch (category) {
    case 'biblicas':
      return const _CategoryPresentation(
        kicker: 'ORA CON LA PALABRA',
        description:
            'Pasajes y oraciones para leer despacio, guardar en el corazón y llevar al día.',
        icon: Icons.menu_book_rounded,
        accent: Color(0xFF77649A),
      );
    case 'promesas':
      return const _CategoryPresentation(
        kicker: 'PROMESAS PARA EL CAMINO',
        description:
            'Palabras de esperanza para recordar la fidelidad de Dios en cada momento.',
        icon: Icons.auto_awesome_rounded,
        accent: Color(0xFFB58A45),
      );
    case 'otras':
      return const _CategoryPresentation(
        kicker: 'ORACIONES PARA CADA MOMENTO',
        description:
            'Una colección sencilla para entregar a Dios lo que hoy llevas dentro.',
        icon: Icons.favorite_outline_rounded,
        accent: Color(0xFF5F8178),
      );
    case 'basicas':
      return const _CategoryPresentation(
        kicker: 'PALABRAS QUE NOS UNEN',
        description:
            'Oraciones esenciales de la tradición para volver a ellas cuando lo necesites.',
        icon: Icons.volunteer_activism_rounded,
        accent: Color(0xFF77649A),
      );
    case 'arcangeles':
      return const _CategoryPresentation(
        kicker: 'ORACIONES DE PROTECCIÓN',
        description:
            'Plegarias tradicionales para pedir compañía, cuidado y fortaleza.',
        icon: Icons.shield_outlined,
        accent: Color(0xFF536C91),
      );
    default:
      return const _CategoryPresentation(
        kicker: 'TU MOMENTO DE ORACIÓN',
        description:
            'Elige una oración, respira con calma y abre este momento a Dios.',
        icon: Icons.auto_stories_rounded,
        accent: Color(0xFF77649A),
      );
  }
}

_PrayerItemPresentation _itemPresentation(String title, String category) {
  final key = title.toLowerCase();
  if (key.contains('salmo')) {
    return const _PrayerItemPresentation(
      eyebrow: 'Salmo bíblico',
      subtitle: 'Lee y medita este pasaje de la Escritura',
      icon: Icons.menu_book_rounded,
      accent: Color(0xFF536C91),
    );
  }
  if (key.contains('padre nuestro')) {
    return const _PrayerItemPresentation(
      eyebrow: 'Oración bíblica',
      subtitle: 'La oración que Jesús enseñó a sus discípulos',
      icon: Icons.self_improvement_rounded,
      accent: Color(0xFF77649A),
    );
  }
  if (key.contains('agradecimiento')) {
    return const _PrayerItemPresentation(
      eyebrow: 'Para agradecer',
      subtitle: 'Reconoce con calma el bien recibido',
      icon: Icons.wb_sunny_outlined,
      accent: Color(0xFFB58A45),
    );
  }
  if (key.contains('dormir') || key.contains('noche')) {
    return const _PrayerItemPresentation(
      eyebrow: 'Para descansar',
      subtitle: 'Entrega el día y descansa en su cuidado',
      icon: Icons.nightlight_round,
      accent: Color(0xFF6B7398),
    );
  }
  if (key.contains('fortaleza') || key.contains('protección')) {
    return const _PrayerItemPresentation(
      eyebrow: 'Para confiar',
      subtitle: 'Encuentra ánimo y refugio para el camino',
      icon: Icons.shield_outlined,
      accent: Color(0xFF536C91),
    );
  }
  if (category == 'promesas') {
    return const _PrayerItemPresentation(
      eyebrow: 'Promesa bíblica',
      subtitle: 'Una palabra de esperanza para conservar',
      icon: Icons.auto_awesome_rounded,
      accent: Color(0xFFB58A45),
    );
  }
  return const _PrayerItemPresentation(
    eyebrow: 'Oración cristiana',
    subtitle: 'Haz una pausa y presenta este momento a Dios',
    icon: Icons.favorite_outline_rounded,
    accent: Color(0xFF5F8178),
  );
}

class _CategoryPresentation {
  const _CategoryPresentation({
    required this.kicker,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String kicker;
  final String description;
  final IconData icon;
  final Color accent;
}

class _PrayerItemPresentation {
  const _PrayerItemPresentation({
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
