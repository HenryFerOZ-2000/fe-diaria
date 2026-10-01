import 'dart:async';
import 'package:flutter/material.dart';
import '../models/spiritual_stats.dart';
import '../models/achievement.dart';
import '../services/spiritual_stats_service.dart';
import 'package:verbum/design_system/design_system.dart';

class SpiritualStatsScreen extends StatefulWidget {
  const SpiritualStatsScreen({super.key});

  @override
  State<SpiritualStatsScreen> createState() => _SpiritualStatsScreenState();
}

class _SpiritualStatsScreenState extends State<SpiritualStatsScreen> {
  final _service = SpiritualStatsService();
  SpiritualStats _stats = SpiritualStats.empty();
  bool _isLoading = true;
  StreamSubscription<SpiritualStats>? _statsSubscription;

  @override
  void initState() {
    super.initState();

    // Cargar inicialmente primero
    _loadStats();

    // Suscribirse a actualizaciones en tiempo real
    _statsSubscription = _service.statsStream().listen(
      (stats) {
        debugPrint(
          '[SpiritualStatsScreen] 📊 Stream update: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}',
        );
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
          debugPrint(
            '[SpiritualStatsScreen] ✅ UI updated with currentStreak=${_stats.currentStreak}',
          );
        }
      },
      onError: (e) {
        debugPrint('[SpiritualStatsScreen] ❌ Error in stats stream: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getStats();
      debugPrint(
        '[SpiritualStatsScreen] 📥 Initial load: currentStreak=${stats.currentStreak}, bestStreak=${stats.bestStreak}',
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
        debugPrint('[SpiritualStatsScreen] ✅ Initial stats loaded, UI updated');
      }
    } catch (e) {
      debugPrint('[SpiritualStatsScreen] ❌ Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos espirituales', style: context.type.heading),
      ),
      body: _isLoading
          ? const Center(child: VEmptyState(loading: true, title: 'Cargando…'))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  VerbumSpace.gutter,
                  0,
                  VerbumSpace.gutter,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  const VSectionHeader(
                    'Lo que has vivido',
                    eyebrow: 'Métricas',
                    padding: EdgeInsets.fromLTRB(2, 16, 2, 12),
                  ),
                  VTileGrid(
                    children: [
                      VStatTile(
                        value: '${_stats.activeDaysLast30}',
                        label: 'Días activos · 30 días',
                        icon: VerbumIcons.calendarBlank,
                        iconColor: p.accent,
                      ),
                      VStatTile(
                        value: '${_stats.prayersCompleted}',
                        label: 'Oraciones completadas',
                        icon: VerbumIcons.handsPraying,
                        iconColor: p.rubric,
                      ),
                      VStatTile(
                        value: '${_stats.versesRead}',
                        label: 'Versículos leídos',
                        icon: VerbumIcons.bookOpenText,
                      ),
                      VStatTile(
                        value: '${_stats.postsCreated}',
                        label: 'Publicaciones',
                        icon: VerbumIcons.chatsCircle,
                        iconColor: p.accent,
                      ),
                      VStatTile(
                        value: '${_stats.currentStreak}',
                        label: 'Constancia actual',
                        icon: VerbumIcons.flame,
                        iconColor: p.rubric,
                      ),
                      VStatTile(
                        value: '${_stats.bestStreak}',
                        label: 'Mejor constancia',
                        icon: VerbumIcons.trophy,
                      ),
                    ],
                  ),
                  const VSectionHeader(
                    'Hitos del camino',
                    eyebrow: 'Logros',
                    padding: EdgeInsets.fromLTRB(2, 28, 2, 12),
                  ),
                  VTileGrid(
                    minTileWidth: 104,
                    children: [
                      for (final achievement in achievementCatalog)
                        _AchievementTile(
                          achievement: achievement,
                          stats: _stats,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/achievement-detail',
                            arguments: {
                              'achievement': achievement,
                              'stats': _stats,
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.stats,
    required this.onTap,
  });

  final Achievement achievement;
  final SpiritualStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final type = context.type;
    final unlocked = achievement.isUnlocked(stats);
    final progress = achievement.getProgress(stats);
    return VSurfaceCard(
      tone: unlocked ? VSurfaceTone.accent : VSurfaceTone.paper,
      borderColor: unlocked ? p.gold : null,
      radius: VerbumRadius.tile,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      onTap: onTap,
      semanticLabel: unlocked
          ? '${achievement.title}, logrado'
          : '${achievement.title}, $progress de ${achievement.target}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Hero(
              tag: 'achievement_icon_${achievement.id}',
              child: VIcon(
                achievement.icon,
                weight: unlocked ? VIconWeight.fill : VIconWeight.duotone,
                size: 30,
                color: unlocked ? p.gold : p.inkSubtle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: type.caption.copyWith(
                color: unlocked ? p.ink : p.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (unlocked)
              VIcon(
                VerbumIcons.sealCheck,
                weight: VIconWeight.fill,
                size: 16,
                color: p.gold,
              )
            else ...[
              VProgressBar(value: progress / achievement.target, height: 3),
              const SizedBox(height: 4),
              Text(
                '$progress/${achievement.target}',
                style: type.caption.copyWith(fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
