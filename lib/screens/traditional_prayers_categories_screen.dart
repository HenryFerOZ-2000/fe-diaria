import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/traditional_prayers_service.dart';
import '../services/storage_service.dart';
import '../services/ads_service.dart';
import 'traditional_prayers_list_screen.dart';
import 'traditional_prayers_religion_selection_screen.dart';

/// Pantalla que muestra las categorías de oraciones según la religión seleccionada
class TraditionalPrayersCategoriesScreen extends StatefulWidget {
  const TraditionalPrayersCategoriesScreen({super.key});

  @override
  State<TraditionalPrayersCategoriesScreen> createState() => _TraditionalPrayersCategoriesScreenState();
}

class _TraditionalPrayersCategoriesScreenState extends State<TraditionalPrayersCategoriesScreen> {
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
    if (!_adsRemoved) {
      _loadBannerAd();
    }
  }

  Future<void> _loadData() async {
    try {
      await _service.loadPrayers();
      final religion = StorageService().getTraditionalPrayersReligion();
      if (religion.isEmpty) {
        // Si no hay religión seleccionada, volver a la pantalla de selección
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const TraditionalPrayersReligionSelectionScreen(),
            ),
          );
        }
        return;
      }
      setState(() {
        _religion = religion;
        _categories = _service.getCategories(religion);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading traditional prayers: $e');
      setState(() {
        _isLoading = false;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Oraciones Tradicionales',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TraditionalPrayersReligionSelectionScreen(),
                ),
              );
              // Recargar datos después de cambiar religión
              if (mounted) {
                _loadData();
              }
            },
            tooltip: 'Cambiar religión',
          ),
        ],
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron categorías',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Categorías',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
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
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    return _buildCategoryButton(
                                      context: context,
                                      colorScheme: colorScheme,
                                      category: category,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => TraditionalPrayersListScreen(
                                              religion: _religion,
                                              category: category,
                                            ),
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

  Widget _buildCategoryButton({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String category,
    required VoidCallback onTap,
  }) {
    final displayName = _service.getCategoryDisplayName(category);
    // Obtener icono según la categoría
    IconData? categoryIcon = _getCategoryIcon(category);
    
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
                displayName,
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

  IconData? _getCategoryIcon(String category) {
    switch (category) {
      case 'basicas':
        return Icons.favorite_rounded;
      case 'arcangeles':
        return Icons.auto_awesome_rounded;
      case 'del_dia':
        return Icons.calendar_today_rounded;
      case 'biblicas':
        return Icons.menu_book_rounded;
      case 'promesas':
        return Icons.verified_rounded;
      case 'otras':
        return Icons.library_books_rounded;
      default:
        return null;
    }
  }
}

