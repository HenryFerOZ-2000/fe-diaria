import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/ads_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/main_card.dart';
import '../theme/app_theme.dart';

/// Pantalla para guardar y ver intenciones del día
class DailyIntentionsScreen extends StatefulWidget {
  const DailyIntentionsScreen({super.key});

  @override
  State<DailyIntentionsScreen> createState() => _DailyIntentionsScreenState();
}

class _DailyIntentionsScreenState extends State<DailyIntentionsScreen> {
  final AdsService _adsService = AdsService();
  final TextEditingController _intentionController = TextEditingController();
  BannerAd? _bannerAd;
  bool _adsRemoved = false;
  List<String> _intentions = [];

  @override
  void initState() {
    super.initState();
    _adsRemoved = StorageService().getAdsRemoved();
    if (!_adsRemoved) {
      _loadBannerAd();
    }
    _loadIntentions();
  }

  void _loadIntentions() {
    final saved = StorageService().getDailyIntentions();
    setState(() => _intentions = saved);
  }

  void _saveIntention() {
    if (_intentionController.text.trim().isEmpty) return;
    
    final intention = _intentionController.text.trim();
    _intentions.add(intention);
    StorageService().saveDailyIntentions(_intentions);
    _intentionController.clear();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Intención guardada')),
    );
  }

  void _deleteIntention(int index) {
    _intentions.removeAt(index);
    StorageService().saveDailyIntentions(_intentions);
    setState(() {});
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
      onAdFailedToLoad: (error) => debugPrint('Failed to load banner ad: $error'),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Intenciones del Día',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MainCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escribe tu intención',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: _intentionController,
                          hint: 'Ej: Por la salud de mi familia...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomButton(
                          text: 'Guardar Intención',
                          icon: Icons.save,
                          onPressed: _saveIntention,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_intentions.isNotEmpty) ...[
                    Text(
                      'Mis Intenciones',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._intentions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final intention = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: MainCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  intention,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteIntention(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          if (!_adsRemoved)
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: _bannerAd != null ? _bannerAd!.size.height.toDouble() : 50,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : AppColors.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
                ),
              ),
              child: _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : const SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
            ),
        ],
      ),
    );
  }
}

