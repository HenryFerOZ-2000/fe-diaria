import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/main_card.dart';
import 'emotion_detail_screen.dart';
import '../theme/app_theme.dart';

/// Pantalla simple para seleccionar emoción - Diseñada para adultos mayores
class EmotionSelectionScreen extends StatefulWidget {
  const EmotionSelectionScreen({super.key});

  @override
  State<EmotionSelectionScreen> createState() => _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends State<EmotionSelectionScreen> {
  final _personalizationService = PersonalizationService();
  final AdsService _adsService = AdsService();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  bool _isLoading = false;

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

  // 8 emociones simplificadas
  final List<Map<String, dynamic>> _emotions = [
    {'id': 'ansioso', 'name': 'Ansioso', 'icon': Icons.psychology, 'color': Color(0xFFFF9800)},
    {'id': 'triste', 'name': 'Triste', 'icon': Icons.sentiment_very_dissatisfied, 'color': Color(0xFF2196F3)},
    {'id': 'cansado', 'name': 'Cansado', 'icon': Icons.bedtime, 'color': Color(0xFF9E9E9E)},
    {'id': 'preocupado', 'name': 'Preocupado', 'icon': Icons.warning, 'color': Color(0xFFFFC107)},
    {'id': 'agradecido', 'name': 'Agradecido', 'icon': Icons.favorite, 'color': Color(0xFF4CAF50)},
    {'id': 'feliz', 'name': 'Feliz', 'icon': Icons.sentiment_very_satisfied, 'color': Color(0xFFFFEB3B)},
    {'id': 'confundido', 'name': 'Confundido', 'icon': Icons.help, 'color': Color(0xFF9C27B0)},
    {'id': 'miedo', 'name': 'Con miedo', 'icon': Icons.visibility_off, 'color': Color(0xFFF44336)},
  ];

  Future<void> _selectEmotion(String emotion) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      // Guardar emoción
      await provider.setUserEmotion(emotion);
      
      // Recargar versículo y oración personalizados
      await provider.loadTodayVerse();
      await provider.loadTodayPrayers();

      if (!mounted) return;

      // Obtener nombre de la emoción
      final emotionData = _emotions.firstWhere((e) => e['id'] == emotion);
      final emotionName = emotionData['name'] as String;

      // Navegar a pantalla de detalle de emoción
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EmotionDetailScreen(
            emotion: emotion,
            emotionName: emotionName,
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error selecting emotion: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final userName = _personalizationService.getUserName();
    final displayName = userName.isNotEmpty ? userName : 'Amigo';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final theme = Theme.of(context);
    
    return AppScaffold(
      title: '¿Cómo te sientes hoy?',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo personalizado
                  Text(
                    '¿Cómo te sientes hoy, $displayName?',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: colorScheme.primary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Selecciona cómo te sientes y recibirás una oración y versículo especiales para ti',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Grid de emociones (botones grandes)
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _buildEmotionGrid(colorScheme, theme.textTheme),
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
          // Botón de regreso al inicio
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: CustomButton(
              text: 'Regresar al inicio',
              icon: Icons.home,
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionGrid(ColorScheme colorScheme, TextTheme textTheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.95,
      ),
      itemCount: _emotions.length,
      itemBuilder: (context, index) {
        final emotion = _emotions[index];
        return _buildEmotionButton(
          emotion: emotion,
          colorScheme: colorScheme,
          onTap: () => _selectEmotion(emotion['id'] as String),
          textTheme: textTheme,
        );
      },
    );
  }

  Widget _buildEmotionButton({
    required Map<String, dynamic> emotion,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    required TextTheme textTheme,
  }) {
    final emotionColor = emotion['color'] as Color;
    
    return MainCard(
      onTap: onTap,
      borderRadius: AppRadius.xxl,
      border: Border.all(
        color: emotionColor.withOpacity(0.2),
        width: 1.5,
      ),
      customShadows: [
        BoxShadow(
          color: emotionColor.withOpacity(0.12),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              emotion['icon'] as IconData,
              size: 40,
              color: emotionColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            emotion['name'] as String,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

