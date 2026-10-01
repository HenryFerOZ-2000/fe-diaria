import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/app_provider.dart';
import '../services/personalization_service.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_scaffold.dart';
import 'emotion_detail_screen.dart';
import 'package:verbum/design_system/design_system.dart';

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
    {'id': 'ansioso', 'name': 'Ansioso', 'icon': VerbumIcons.brain},
    {'id': 'triste', 'name': 'Triste', 'icon': VerbumIcons.smileySad},
    {'id': 'cansado', 'name': 'Cansado', 'icon': VerbumIcons.moonStars},
    {'id': 'preocupado', 'name': 'Preocupado', 'icon': VerbumIcons.warning},
    {'id': 'agradecido', 'name': 'Agradecido', 'icon': VerbumIcons.heart},
    {'id': 'feliz', 'name': 'Feliz', 'icon': VerbumIcons.smiley},
    {'id': 'confundido', 'name': 'Confundido', 'icon': VerbumIcons.question},
    {'id': 'miedo', 'name': 'Con miedo', 'icon': VerbumIcons.eyeSlash},
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
          builder: (context) =>
              EmotionDetailScreen(emotion: emotion, emotionName: emotionName),
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
        const SnackBar(content: Text('Error al guardar. Intenta nuevamente.')),
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

    final p = context.palette;
    final type = context.type;
    final userName = _personalizationService.getUserName();
    final displayName = userName.isNotEmpty ? userName : 'Amigo';

    return AppScaffold(
      title: '¿Cómo te sientes hoy?',
      centerTitle: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VerbumSpace.gutter,
                VerbumSpace.xs,
                VerbumSpace.gutter,
                VerbumSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo personalizado
                  Semantics(
                    header: true,
                    child: Text(
                      '¿Cómo te sientes hoy, $displayName?',
                      style: type.display,
                    ),
                  ),
                  const SizedBox(height: VerbumSpace.xs),
                  Text(
                    'Selecciona cómo te sientes y recibirás una oración y versículo especiales para ti',
                    style: type.body,
                  ),
                  const SizedBox(height: VerbumSpace.xl),

                  // Cuadrícula de emociones
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(VerbumSpace.xxl),
                        child: CircularProgressIndicator(color: p.rubric),
                      ),
                    )
                  else
                    _buildEmotionGrid(),
                ],
              ),
            ),
          ),
          // Banner Ad fijo en la parte inferior
          if (!_adsRemoved)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: _bannerAd != null
                  ? _bannerAd!.size.height.toDouble()
                  : 50,
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.line)),
              ),
              child: _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.rubric,
                        ),
                      ),
                    ),
            ),
          // Botón de regreso al inicio
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              VerbumSpace.sm,
              VerbumSpace.gutter,
              VerbumSpace.md,
            ),
            child: VButton(
              label: 'Regresar al inicio',
              icon: VerbumIcons.house,
              iconLeading: true,
              expanded: true,
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionGrid() {
    return VTileGrid(
      children: [
        for (final emotion in _emotions)
          VCategoryTile(
            icon: emotion['icon'] as VerbumIcons,
            title: emotion['name'] as String,
            onTap: () => _selectEmotion(emotion['id'] as String),
          ),
      ],
    );
  }
}
