import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/daily_content_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'traditional_prayers_categories_screen.dart';

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
      icon: Icons.church_outlined,
      accent: Color(0xFF77649A),
    ),
    _TraditionOption(
      id: 'cristiana',
      title: 'Tradición evangélica',
      description:
          'Oraciones y reflexiones centradas en la Palabra y la vida en comunidad.',
      icon: Icons.menu_book_rounded,
      accent: Color(0xFFB58A45),
    ),
    _TraditionOption(
      id: 'general',
      title: 'Cristiana general',
      description:
          'Contenido cristiano común para explorar sin elegir una denominación.',
      icon: Icons.auto_awesome_outlined,
      accent: Color(0xFF5F8178),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final firstRun = widget.requireSelection;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.2, -.78),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 20, 0),
                child: Row(
                  children: [
                    if (!firstRun)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: .10),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: .18),
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: scheme.primary,
                          size: 21,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verbum',
                        style: GoogleFonts.playfairDisplay(
                          color: scheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (firstRun) _StepBadge(label: 'PASO 1 DE 2', dark: dark),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstRun ? 'HAZLO TUYO' : 'TU PREFERENCIA',
                        style: GoogleFonts.inter(
                          color: scheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        firstRun
                            ? 'Haz de Verbum un\nespacio más tuyo'
                            : 'Elige cómo quieres\nvivir Verbum',
                        style: GoogleFonts.playfairDisplay(
                          color: scheme.onSurface,
                          fontSize: 34,
                          height: 1.05,
                          letterSpacing: -.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        'Esto adapta algunas oraciones, reflexiones y experiencias. No limita lo que puedes explorar.',
                        style: GoogleFonts.inter(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._options.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TraditionCard(
                            option: option,
                            selected: _selected == option.id,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selected = option.id);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Podrás cambiar esta elección cuando quieras desde Ajustes.',
                              style: GoogleFonts.inter(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                decoration: BoxDecoration(
                  color:
                      (dark ? const Color(0xFF17141F) : const Color(0xFFFBF8F1))
                          .withValues(alpha: .94),
                  border: Border(
                    top: BorderSide(
                      color: scheme.outline.withValues(alpha: .16),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _selected == null || _saving ? null : _continue,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(_saving ? 'Guardando...' : 'Continuar'),
                  ),
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
  final IconData icon;
  final Color accent;

  const _TraditionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

class _TraditionCard extends StatelessWidget {
  final _TraditionOption option;
  final bool selected;
  final VoidCallback onTap;

  const _TraditionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF282330) : const Color(0xFFFFFCF7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(option.accent.withValues(alpha: .10), surface)
            : surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: selected
              ? option.accent
              : scheme.outline.withValues(alpha: .20),
          width: selected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? option.accent.withValues(alpha: .16)
                : Colors.black.withValues(alpha: dark ? .12 : .035),
            blurRadius: selected ? 22 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: option.accent.withValues(
                      alpha: selected ? .18 : .10,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(option.icon, color: option.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: GoogleFonts.inter(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: GoogleFonts.inter(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: selected ? option.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? option.accent
                          : scheme.outline.withValues(alpha: .55),
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final String label;
  final bool dark;

  const _StepBadge({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: dark ? .20 : .09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.primary.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: dark ? scheme.primaryContainer : scheme.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}
