import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/daily_content_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'traditional_prayers_categories_screen.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/onboarding/presentation/onboarding_chrome.dart';

Future<void> _syncAfterTraditionChange(BuildContext context) async {
  PrayerService().resetInMemoryDailyPrayers();
  DailyContentService().clearCache();
  if (!context.mounted) return;
  try {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loadTodayPrayers();
    await provider.loadTodayFamilyPrayer();
  } catch (e) {
    debugPrint('syncAfterTraditionChange: $e');
  }
}

class TraditionalPrayersReligionSelectionScreen extends StatefulWidget {
  final bool requireSelection;
  final String? nextRouteOnSelect;

  const TraditionalPrayersReligionSelectionScreen({
    super.key,
    this.requireSelection = false,
    this.nextRouteOnSelect,
  });

  @override
  State<TraditionalPrayersReligionSelectionScreen> createState() =>
      _TraditionalPrayersReligionSelectionScreenState();
}

class _TraditionalPrayersReligionSelectionScreenState
    extends State<TraditionalPrayersReligionSelectionScreen> {
  String? _selected;
  bool _saving = false;

  static const _options = [
    _TraditionOption(
      id: 'catolica',
      title: 'Tradición católica',
      description:
          'Oraciones tradicionales, rosario, santos y reflexiones católicas.',
      icon: VerbumIcons.church,
    ),
    _TraditionOption(
      id: 'cristiana',
      title: 'Evangélica / protestante',
      description:
          'Oraciones y reflexiones centradas en la Palabra y la vida en comunidad.',
      icon: VerbumIcons.bookOpenText,
    ),
    _TraditionOption(
      id: 'general',
      title: 'Cristiana general',
      description:
          'Contenido cristiano común para explorar sin elegir una denominación.',
      icon: VerbumIcons.cross,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final saved = StorageService().getValidatedTraditionalPrayersReligion();
    if (saved.isNotEmpty) _selected = saved;
  }

  Future<void> _continue() async {
    final selection = _selected;
    if (selection == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.selectionClick();
    try {
      await StorageService().setTraditionalPrayersReligion(selection);
      if (!mounted) return;
      await _syncAfterTraditionChange(context);
      if (!mounted) return;

      if (widget.nextRouteOnSelect != null) {
        Navigator.of(context).pushReplacementNamed(widget.nextRouteOnSelect!);
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const TraditionalPrayersCategoriesScreen(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstRun = widget.requireSelection;
    final type = context.type;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.2, -.78),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                child: OnboardingHeader(
                  step: firstRun ? 'Paso 1 de 2' : null,
                  onBack: firstRun
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                  children: [
                    VRubricLabel(firstRun ? 'Hazlo tuyo' : 'Tu preferencia'),
                    const SizedBox(height: 8),
                    Text(
                      firstRun
                          ? 'Haz de Verbum un espacio más tuyo'
                          : 'Elige cómo quieres vivir Verbum',
                      style: type.display.copyWith(fontSize: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Esto adapta algunas oraciones, reflexiones y experiencias. No limita lo que puedes explorar.',
                      style: type.body.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 24),
                    for (final option in _options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VRadioCard(
                          icon: option.icon,
                          title: option.title,
                          description: option.description,
                          selected: _selected == option.id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = option.id);
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    const VNotice(
                      'Podrás cambiar esta elección cuando quieras desde Ajustes.',
                    ),
                  ],
                ),
              ),
              OnboardingBottomBar(
                child: VButton(
                  label: _saving ? 'Guardando…' : 'Continuar',
                  icon: VerbumIcons.arrowRight,
                  expanded: true,
                  loading: _saving,
                  onPressed: _selected == null ? null : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraditionOption {
  final String id;
  final String title;
  final String description;
  final VerbumIcons icon;

  const _TraditionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
