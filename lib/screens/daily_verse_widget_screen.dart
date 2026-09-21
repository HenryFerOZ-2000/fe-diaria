import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/verse.dart';
import '../services/verse_service.dart';
import '../services/widget_service.dart';
import '../widgets/daily_verse_widget_preview.dart';

class DailyVerseWidgetScreen extends StatefulWidget {
  DailyVerseWidgetScreen({
    super.key,
    WidgetService? widgetService,
    Future<Verse> Function()? loadVerse,
    this.localizations,
  }) : widgetService = widgetService ?? WidgetService(),
       loadVerse = loadVerse ?? VerseService().getTodayVerse;

  final WidgetService widgetService;
  final Future<Verse> Function() loadVerse;
  final AppLocalizations? localizations;

  @override
  State<DailyVerseWidgetScreen> createState() => _DailyVerseWidgetScreenState();
}

class _DailyVerseWidgetScreenState extends State<DailyVerseWidgetScreen>
    with WidgetsBindingObserver {
  late final Future<Verse> _verse;
  bool _hasWidget = false;
  bool _checking = true;
  bool _requesting = false;
  bool _showManualInstructions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verse = widget.loadVerse();
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final hasWidget = await widget.widgetService.hasWidgets();
    if (!mounted) return;
    setState(() {
      _hasWidget = hasWidget;
      _checking = false;
    });
  }

  Future<void> _requestWidget() async {
    final strings = widget.localizations ?? AppLocalizations.of(context);
    setState(() {
      _requesting = true;
      _showManualInstructions = false;
    });
    final result = await widget.widgetService.requestPinWidget();
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _showManualInstructions = result == WidgetPinRequestResult.unsupported;
    });
    switch (result) {
      case WidgetPinRequestResult.requested:
        _showMessage(strings.widgetRequestSent);
      case WidgetPinRequestResult.failed:
        _showMessage(strings.widgetPinFailed);
      case WidgetPinRequestResult.unsupported:
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.localizations ?? AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.widgetScreenTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              strings.widgetScreenDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<Verse>(
              future: _verse,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DailyVerseWidgetPreview(verse: snapshot.data!);
                }
                if (snapshot.hasError) {
                  return _InfoCard(
                    icon: Icons.menu_book_rounded,
                    title: strings.widgetPreviewUnavailable,
                    body: strings.widgetPreviewUnavailableDescription,
                  );
                }
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            const SizedBox(height: 22),
            Semantics(
              button: true,
              label: _hasWidget ? strings.widgetAdded : strings.widgetAddToHome,
              child: FilledButton.icon(
                onPressed: _hasWidget || _requesting || _checking
                    ? null
                    : _requestWidget,
                icon: _requesting || _checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _hasWidget
                            ? Icons.check_circle_rounded
                            : Icons.add_to_home_screen_rounded,
                      ),
                label: Text(
                  _hasWidget ? strings.widgetAdded : strings.widgetAddToHome,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            if (_showManualInstructions) ...[
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.touch_app_rounded,
                title: strings.widgetManualTitle,
                body: strings.widgetManualHome,
              ),
            ],
            const SizedBox(height: 28),
            _InfoCard(
              icon: Icons.lock_outline_rounded,
              title: strings.widgetLockScreenTitle,
              body: strings.widgetLockScreenCompatibility,
              steps: [
                strings.widgetLockScreenStep1,
                strings.widgetLockScreenStep2,
                strings.widgetLockScreenStep3,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.steps = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[index])),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
