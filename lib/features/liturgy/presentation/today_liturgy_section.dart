import 'dart:async';

import 'package:flutter/material.dart';

import '../../../faith/faith_tradition.dart';
import '../../../faith/tradition_capabilities.dart';
import '../../../services/storage_service.dart';
import '../application/calendar_region_resolver.dart';
import '../application/liturgy_service.dart';
import '../data/asset_liturgy_repository.dart';
import '../domain/calendar_selection.dart';
import '../domain/liturgical_day.dart';
import 'liturgy_day_screen.dart';
import 'today_liturgy_card.dart';

class TodayLiturgySection extends StatelessWidget {
  const TodayLiturgySection({
    super.key,
    this.service,
    this.tradition,
    this.selection,
    this.scheduleRefresh = true,
  });

  final DailyLiturgyLoader? service;
  final FaithTradition? tradition;
  final CalendarSelection? selection;
  final bool scheduleRefresh;

  @override
  Widget build(BuildContext context) {
    if (service != null) {
      return _TodayLiturgyContent(
        service: service,
        tradition: tradition ?? FaithTradition.unset,
        selection: selection ?? const CalendarSelection.generalRoman(),
        scheduleRefresh: scheduleRefresh,
      );
    }

    final storage = StorageService();
    return ValueListenableBuilder(
      valueListenable: storage.faithPreferencesListenable(),
      builder: (context, _, __) {
        final currentTradition = faithTraditionFromStorageString(
          storage.getValidatedTraditionalPrayersReligion(),
        );
        final profile = CalendarRegionResolver(
          readStoredCountry: storage.getCatholicCalendarCountry,
        ).resolve(currentTradition);
        return _TodayLiturgyContent(
          key: ValueKey(
            '${currentTradition.name}:${profile.selection.countryCode ?? 'GENERAL'}',
          ),
          tradition: currentTradition,
          selection: profile.selection,
          scheduleRefresh: scheduleRefresh,
        );
      },
    );
  }
}

class _TodayLiturgyContent extends StatefulWidget {
  const _TodayLiturgyContent({
    super.key,
    this.service,
    required this.tradition,
    required this.selection,
    required this.scheduleRefresh,
  });

  final DailyLiturgyLoader? service;
  final FaithTradition tradition;
  final CalendarSelection selection;
  final bool scheduleRefresh;

  @override
  State<_TodayLiturgyContent> createState() => _TodayLiturgyContentState();
}

class _TodayLiturgyContentState extends State<_TodayLiturgyContent> {
  late final DailyLiturgyLoader _service;
  Timer? _refreshTimer;
  LiturgicalDay? _day;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ??
        LiturgyService(
          repository: AssetLiturgyRepository(),
          selection: widget.selection,
        );
    if (TraditionCapabilities.forTradition(widget.tradition).showDailyLiturgy) {
      _load();
      if (widget.scheduleRefresh) _scheduleNextMidnight();
    }
  }

  Future<void> _load() async {
    try {
      final day = await _service.today();
      if (mounted) setState(() => _day = day);
    } on Object catch (error) {
      debugPrint('[TodayLiturgySection] $error');
      if (mounted) setState(() => _day = null);
    }
  }

  void _scheduleNextMidnight() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_service.untilNextDay(), () async {
      await _load();
      if (mounted) _scheduleNextMidnight();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    if (!TraditionCapabilities.forTradition(
          widget.tradition,
        ).showDailyLiturgy ||
        day == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TodayLiturgyCard(
        day: day,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                LiturgyDayScreen(day: day, selection: widget.selection),
          ),
        ),
      ),
    );
  }
}
