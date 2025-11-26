import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_prayers_service.dart';
import '../services/share_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CategoryPrayersScreen extends StatefulWidget {
  const CategoryPrayersScreen({super.key});

  @override
  State<CategoryPrayersScreen> createState() => _CategoryPrayersScreenState();
}

class _CategoryPrayersScreenState extends State<CategoryPrayersScreen> {
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

    final service = CategoryPrayersService();
    final categories = service.categories;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Oraciones para…',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(colorScheme),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final key = categories.keys.elementAt(index);
                          final title = categories[key]!;
                          return _buildCategoryButton(
                            context: context,
                            colorScheme: colorScheme,
                            title: title,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CategoryPrayerDetailScreen(categoryKey: key),
                                ),
                              );
                            },
                          );
                        },
                      ),
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
                        : Colors.white,
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
              // Botón de regreso al inicio
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/home');
                    },
                    icon: const Icon(Icons.home, size: 24),
                    label: Text(
                      'Regresar al inicio',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Text(
      'Elige una categoría',
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required VoidCallback onTap,
  }) {
    // Obtener icono según la categoría
    IconData? categoryIcon = _getCategoryIcon(title);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoryIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData? _getCategoryIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('familia')) return Icons.family_restroom_rounded;
    if (titleLower.contains('salud')) return Icons.favorite_rounded;
    if (titleLower.contains('trabajo')) return Icons.work_rounded;
    if (titleLower.contains('finanzas')) return Icons.account_balance_wallet_rounded;
    if (titleLower.contains('hogar')) return Icons.home_rounded;
    if (titleLower.contains('protección') || titleLower.contains('proteccion')) return Icons.shield_rounded;
    if (titleLower.contains('descanso')) return Icons.bedtime_rounded;
    if (titleLower.contains('mente') || titleLower.contains('paz')) return Icons.self_improvement_rounded;
    if (titleLower.contains('ánimo') || titleLower.contains('animo')) return Icons.emoji_emotions_rounded;
    if (titleLower.contains('agradecimiento')) return Icons.celebration_rounded;
    return null;
  }
}

class CategoryPrayerDetailScreen extends StatefulWidget {
  final String categoryKey;
  const CategoryPrayerDetailScreen({super.key, required this.categoryKey});

  @override
  State<CategoryPrayerDetailScreen> createState() => _CategoryPrayerDetailScreenState();
}

class _CategoryPrayerDetailScreenState extends State<CategoryPrayerDetailScreen> {
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
    final service = CategoryPrayersService();
    final title = service.categories[widget.categoryKey] ?? 'Categoría';
    final prayerText = service.getPrayerForCategory(widget.categoryKey);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrayerCard(
                      context: context,
                      title: title,
                      prayerText: prayerText,
                    ),
                    const SizedBox(height: 90), // espacio para no tapar con banner flotante
                  ],
                ),
              ),
            ),
          ),
          // Banner Ad fijo en la parte inferior
          if (!_adsRemoved)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: _bannerAd != null ? _bannerAd!.size.height.toDouble() : 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
            ),
          // Botón de regreso al inicio
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/home');
                },
                icon: const Icon(Icons.home, size: 24),
                label: Text(
                  'Regresar al inicio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({required BuildContext context, required String title, required String prayerText}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            prayerText,
            style: GoogleFonts.inter(
              fontSize: 20,
              height: 1.9,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ShareService.shareAsText(
                  text: prayerText,
                  reference: title,
                  title: title,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Compartir',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
