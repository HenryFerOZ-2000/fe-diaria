import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../services/ads_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../services/ads_manager.dart';
import '../l10n/app_localizations.dart';
import 'emotion_selection_screen.dart';
import 'category_prayers_screen.dart';
import 'traditional_prayers_religion_selection_screen.dart';
import 'traditional_prayers_categories_screen.dart';

/// Pantalla principal con diseño religioso elegante
/// Incluye tabs para Versículo del Día y Oración del Día
class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  
  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _prayerTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _prayerFadeAnimation;
  AudioPlayer? _audioPlayer;
  Timer? _prayerTimeCheckTimer;
  Timer? _dailyRefreshTimer;
  bool _isMorningPrayer = true;
  bool _adsRemoved = false;

  @override
  void initState() {
    super.initState();
    // Inicializar TabController (usa un AnimationController internamente)
    final initialIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: initialIndex.clamp(0, 1),
    );
    // Inicializar AnimationController para animaciones de contenido
    _setupAnimations();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _checkPrayerTime();
    _setupDailyRefresh();
    // Verificar cada minuto si cambió la hora de oración
    _prayerTimeCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkPrayerTime();
    });
    
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadTodayVerse();
      provider.loadTodayPrayers();
      // Intentar mostrar interstitial suave (máx 2 por día), no en lectura
      if (_tabController.index == 0) {
        AdsManager().maybeShowDailyInterstitial(
          context: context,
          isSensitiveContext: false,
        );
      }
    });
  }
  
  void _setupDailyRefresh() {
    // Programar refresco automático a las 9:00 AM
    final now = DateTime.now();
    var nextRefresh = DateTime(now.year, now.month, now.day, 9, 0);
    
    // Si ya pasaron las 9 AM hoy, programar para mañana
    if (nextRefresh.isBefore(now)) {
      nextRefresh = nextRefresh.add(const Duration(days: 1));
    }
    
    final durationUntilRefresh = nextRefresh.difference(now);
    
    _dailyRefreshTimer = Timer(durationUntilRefresh, () {
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.refreshTodayVerse();
        provider.loadTodayPrayers();
        
        // Programar el siguiente refresco para mañana a las 9 AM
        _setupDailyRefresh();
      }
    });
  }

  void _setupAnimations() {
    // Crear AnimationController para animaciones de fade del versículo
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Crear AnimationController para transiciones de oración (mañana/noche)
    _prayerTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _prayerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _prayerTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Iniciar animaciones
    _animationController.forward();
    _prayerTransitionController.forward();
  }

  void _checkPrayerTime() {
    final now = DateTime.now();
    final hour = now.hour;
    // Oración de la mañana: 5:00 AM a 5:59 PM
    // Oración de la noche: 6:00 PM a 4:59 AM
    final newIsMorning = hour >= 5 && hour < 18;
    
    if (newIsMorning != _isMorningPrayer) {
      setState(() {
        _isMorningPrayer = newIsMorning;
        // Animar transición suave
        _prayerTransitionController.reset();
        _prayerTransitionController.forward();
      });
      
      // Recargar oraciones cuando cambia el tiempo
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.loadTodayPrayers();
      }
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
          debugPrint('Banner ad loaded successfully');
        } else {
          ad.dispose();
        }
      },
      onAdFailedToLoad: (error) {
        debugPrint('Failed to load banner ad: $error');
        // Reintentar después de 5 segundos
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
    _tabController.dispose();
    _animationController.dispose();
    _prayerTransitionController.dispose();
    _bannerAd?.dispose();
    _audioPlayer?.dispose();
    _prayerTimeCheckTimer?.cancel();
    _dailyRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Actualizar estado de anuncios removidos en cada build
    final storage = StorageService();
    final adsRemovedNow = storage.getAdsRemoved();
    if (adsRemovedNow && !_adsRemoved) {
      // Si se compró mientras esta vista estaba activa, liberar banner
      _bannerAd?.dispose();
      _bannerAd = null;
      _adsRemoved = true;
    } else if (!adsRemovedNow && _adsRemoved) {
      // Si se restauraron los anuncios, recargar banner
      _adsRemoved = false;
      _loadBannerAd();
    } else if (!adsRemovedNow && _bannerAd == null) {
      // Si no hay banner cargado y los anuncios no están removidos, cargar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_adsRemoved && _bannerAd == null) {
          _loadBannerAd();
        }
      });
    }
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF161522),
                    const Color(0xFF1E1B2E),
                    const Color(0xFF161522),
                  ]
                : [
                    const Color(0xFFF8FAFF),
                    const Color(0xFFE8F0FF),
                    const Color(0xFFF0F5FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno y elegante
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    // Icono decorativo con estilo moderno
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.2),
                            colorScheme.tertiary.withOpacity(0.15),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        localizations.appTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs modernos con diseño limpio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface.withOpacity(0.6)
                        : Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.book_rounded, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                localizations.homeTitle,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMorningPrayer ? Icons.wb_sunny : Icons.nightlight_round,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _isMorningPrayer 
                                    ? localizations.morningPrayer 
                                    : localizations.eveningPrayer,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Contenido de los tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVerseTab(context, isDark, localizations),
                    _buildPrayerTab(context, isDark, localizations),
                  ],
                ),
              ),
              // Banner Ad flotante - siempre visible en la parte inferior
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseTab(
      BuildContext context, bool isDark, AppLocalizations localizations) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final verse = provider.todayVerse;
        if (verse == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark
                      ? const Color(0xFFF5E6D3).withOpacity(0.5)
                      : const Color(0xFF2C1810).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.loadingError,
                  style: GoogleFonts.merriweather(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadTodayVerse();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.retry),
                ),
              ],
            ),
          );
        }

        final isFavorite = provider.isFavorite(verse);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Versículo del día - Flexible para ocupar espacio disponible
                  Expanded(
                    flex: 6,
                    child: _buildVerseCard(
                      context: context,
                      verse: verse,
                      isFavorite: isFavorite,
                      onFavoriteTap: () => provider.toggleFavorite(verse),
                      onShare: () => _showShareDialog(
                        text: verse.text,
                        reference: verse.reference,
                        context: context,
                        localizations: localizations,
                      ),
                      fontSize: provider.fontSize,
                      isDark: isDark,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botones en dos filas - distribución simétrica
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPrayerForYouButton(
                                  context, 
                                  Theme.of(context).colorScheme, 
                                  isCompact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCategoryPrayersButton(
                                  context, 
                                  Theme.of(context).colorScheme, 
                                  isCompact: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildTraditionalPrayersButton(
                            context, 
                            Theme.of(context).colorScheme, 
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTab(
      BuildContext context, bool isDark, AppLocalizations localizations) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final prayer = provider.currentPrayer;
        if (prayer == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: isDark
                      ? const Color(0xFFF5E6D3).withOpacity(0.5)
                      : const Color(0xFF2C1810).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.loadingError,
                  style: GoogleFonts.merriweather(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadTodayPrayers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(localizations.retry),
                ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _prayerFadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Oración del día - Flexible para ocupar espacio disponible
                  Expanded(
                    flex: 6,
                    child: _buildPrayerCard(
                      context: context,
                      prayer: prayer,
                      isMorning: _isMorningPrayer,
                      onShare: () => ShareService.shareAsText(
                        text: prayer.text,
                        reference: prayer.title,
                        title: prayer.title,
                      ),
                      fontSize: provider.fontSize,
                      isDark: isDark,
                      localizations: localizations,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botones en dos filas - distribución simétrica
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildPrayerForYouButton(
                                  context, 
                                  Theme.of(context).colorScheme, 
                                  isCompact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCategoryPrayersButton(
                                  context, 
                                  Theme.of(context).colorScheme, 
                                  isCompact: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildTraditionalPrayersButton(
                            context, 
                            Theme.of(context).colorScheme, 
                            isCompact: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerForYouButton(BuildContext context, ColorScheme colorScheme, {bool isCompact = false}) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EmotionSelectionScreen(),
            ),
          );
        },
        icon: Icon(Icons.favorite, size: isCompact ? 20 : 32),
        label: Text(
          isCompact ? '¿Cómo te sientes hoy?' : '¿Cómo te sientes hoy?\nOración para ti',
          style: GoogleFonts.inter(
            fontSize: isCompact ? 14 : 22,
            fontWeight: FontWeight.w600,
            height: isCompact ? 1.25 : 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: isCompact ? 2 : null,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: Colors.white,
          padding: isCompact 
              ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
              : const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildCategoryPrayersButton(BuildContext context, ColorScheme colorScheme, {bool isCompact = false}) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Mostrar interstitial al entrar a "Oraciones para…" (no bloquea navegación)
          AdsManager().tryShowCategoryEntryInterstitial();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CategoryPrayersScreen(),
            ),
          );
        },
        icon: Icon(Icons.menu_book_rounded, size: isCompact ? 20 : 32),
        label: Text(
          isCompact ? 'Oraciones para…' : 'Oraciones para…\n(Mi familia, mi salud, etc.)',
          style: GoogleFonts.inter(
            fontSize: isCompact ? 14 : 22,
            fontWeight: FontWeight.w600,
            height: isCompact ? 1.25 : 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: isCompact ? 2 : null,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: isCompact 
              ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
              : const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildTraditionalPrayersButton(BuildContext context, ColorScheme colorScheme, {bool isCompact = false}) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final religion = StorageService().getTraditionalPrayersReligion();
          if (religion.isEmpty) {
            // Si no hay religión seleccionada, mostrar pantalla de selección
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TraditionalPrayersReligionSelectionScreen(),
              ),
            );
          } else {
            // Si ya hay religión seleccionada, ir directo a categorías
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TraditionalPrayersCategoriesScreen(),
              ),
            );
          }
        },
        icon: Icon(Icons.church, size: isCompact ? 20 : 32),
        label: Text(
          'Oraciones tradicionales',
          style: GoogleFonts.inter(
            fontSize: isCompact ? 14 : 22,
            fontWeight: FontWeight.w600,
            height: isCompact ? 1.25 : 1.3,
          ),
          textAlign: TextAlign.center,
          maxLines: isCompact ? 2 : null,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Colors.white,
          padding: isCompact 
              ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
              : const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildVerseCard({
    required BuildContext context,
    required dynamic verse,
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
    required VoidCallback onShare,
    required double fontSize,
    required bool isDark,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Decoración de fondo sutil y moderna
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header moderno con icono y acciones - más compacto
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: isCompact ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    // Botón compartir con texto
                    _buildShareButton(
                      onTap: onShare,
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    _buildActionButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: onFavoriteTap,
                      isDark: isDark,
                      isFavorite: isFavorite,
                      isCompact: isCompact,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 24),
                // Texto del versículo con tipografía moderna - Flexible para scroll interno si es necesario
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      verse.text,
                      style: GoogleFonts.inter(
                        fontSize: (isCompact ? 17 : 18) * fontSize,
                        height: isCompact ? 1.6 : 1.7,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                      softWrap: true,
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 20),
                // Línea decorativa moderna
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.3),
                        colorScheme.tertiary.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 16),
                // Referencia con estilo elegante
                Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: colorScheme.secondary,
                      size: isCompact ? 18 : 20,
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Expanded(
                      child: Text(
                        verse.reference,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: (isCompact ? 16 : 18) * fontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({
    required BuildContext context,
    required dynamic prayer,
    required bool isMorning,
    required VoidCallback onShare,
    required double fontSize,
    required bool isDark,
    required AppLocalizations localizations,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    // Colores modernos según si es mañana o noche
    final accentColor = isMorning 
        ? const Color(0xFFFFB84D) // Dorado cálido para mañana
        : colorScheme.tertiary; // Azul cielo para noche

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración de fondo sutil y moderna
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                size: 140,
                color: accentColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header moderno con icono y título
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      ),
                      child: Icon(
                        isMorning ? Icons.wb_sunny : Icons.nightlight_round,
                        color: accentColor,
                        size: isCompact ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 12),
                    Expanded(
                      child: Text(
                        isMorning
                            ? localizations.morningPrayer
                            : localizations.eveningPrayer,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: (isCompact ? 18 : 22) * fontSize,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildShareButton(
                      onTap: onShare,
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 12 : 24),
                // Texto de la oración con tipografía moderna - Flexible para scroll interno si es necesario
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      prayer.text,
                      style: GoogleFonts.inter(
                        fontSize: (isCompact ? 17 : 17) * fontSize,
                        height: isCompact ? 1.6 : 1.7,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withOpacity(0.9),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.justify,
                      softWrap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required VoidCallback onTap,
    required bool isDark,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Compartir',
            style: GoogleFonts.inter(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isFavorite = false,
    bool isCompact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = isFavorite
        ? Colors.red
        : colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 7 : 10),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(isCompact ? 9 : 10),
            border: Border.all(
              color: buttonColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: buttonColor,
            size: isCompact ? 18 : 20,
          ),
        ),
      ),
    );
  }

  void _showShareDialog({
    required String text,
    required String reference,
    required BuildContext context,
    required AppLocalizations localizations,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.shareVerse,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(localizations.shareAsText),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareAsText(
                  text: text,
                  reference: reference,
                  title: localizations.homeTitle,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(localizations.shareAsImage),
              onTap: () {
                Navigator.pop(context);
                final provider = Provider.of<AppProvider>(context, listen: false);
                final colorScheme = Theme.of(context).colorScheme;
                ShareService.shareAsImage(
                  text: text,
                  reference: reference,
                  context: context,
                  title: localizations.homeTitle,
                  backgroundColor: provider.darkMode
                      ? colorScheme.surface
                      : colorScheme.surface,
                  textColor: provider.darkMode
                      ? colorScheme.onSurface
                      : colorScheme.onSurface,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
