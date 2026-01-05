import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spiritual_stats.dart';
import '../models/achievement.dart';
import '../services/spiritual_stats_service.dart';

class SpiritualStatsScreen extends StatefulWidget {
  const SpiritualStatsScreen({super.key});

  @override
  State<SpiritualStatsScreen> createState() => _SpiritualStatsScreenState();
}

class _SpiritualStatsScreenState extends State<SpiritualStatsScreen> {
  final _service = SpiritualStatsService();
  SpiritualStats _stats = SpiritualStats.empty();
  bool _isLoading = true;

  // Definición de logros
  static final List<Achievement> _achievements = [
    Achievement(
      id: 'streak_7',
      title: 'Racha de 7 días',
      description: 'Mantén tu racha por 7 días consecutivos',
      type: AchievementType.streak,
      target: 7,
      icon: Icons.local_fire_department,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Racha de 30 días',
      description: 'Mantén tu racha por 30 días consecutivos',
      type: AchievementType.streak,
      target: 30,
      icon: Icons.local_fire_department,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Racha de 100 días',
      description: 'Mantén tu racha por 100 días consecutivos',
      type: AchievementType.streak,
      target: 100,
      icon: Icons.local_fire_department,
    ),
    Achievement(
      id: 'verses_10',
      title: '10 Versículos',
      description: 'Lee 10 versículos',
      type: AchievementType.verses,
      target: 10,
      icon: Icons.book,
    ),
    Achievement(
      id: 'verses_100',
      title: '100 Versículos',
      description: 'Lee 100 versículos',
      type: AchievementType.verses,
      target: 100,
      icon: Icons.book,
    ),
    Achievement(
      id: 'verses_500',
      title: '500 Versículos',
      description: 'Lee 500 versículos',
      type: AchievementType.verses,
      target: 500,
      icon: Icons.book,
    ),
    Achievement(
      id: 'prayers_10',
      title: '10 Oraciones',
      description: 'Completa 10 oraciones',
      type: AchievementType.prayers,
      target: 10,
      icon: Icons.favorite,
    ),
    Achievement(
      id: 'prayers_100',
      title: '100 Oraciones',
      description: 'Completa 100 oraciones',
      type: AchievementType.prayers,
      target: 100,
      icon: Icons.favorite,
    ),
    Achievement(
      id: 'posts_10',
      title: '10 Publicaciones',
      description: 'Crea 10 publicaciones',
      type: AchievementType.posts,
      target: 10,
      icon: Icons.chat_bubble,
    ),
    Achievement(
      id: 'posts_50',
      title: '50 Publicaciones',
      description: 'Crea 50 publicaciones',
      type: AchievementType.posts,
      target: 50,
      icon: Icons.chat_bubble,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Datos espirituales',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Métricas principales
                    Text(
                      'Métricas',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(),
                    const SizedBox(height: 32),
                    // Logros
                    Text(
                      'Logros',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAchievementsGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _StatsCard(
          title: 'Días activos',
          subtitle: 'Últimos 30 días',
          value: '${_stats.activeDaysLast30}',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        _StatsCard(
          title: 'Oraciones',
          subtitle: 'Completadas',
          value: '${_stats.prayersCompleted}',
          icon: Icons.favorite,
          color: Colors.red,
        ),
        _StatsCard(
          title: 'Versículos',
          subtitle: 'Leídos',
          value: '${_stats.versesRead}',
          icon: Icons.book,
          color: Colors.purple,
        ),
        _StatsCard(
          title: 'Publicaciones',
          subtitle: 'Creadas',
          value: '${_stats.postsCreated}',
          icon: Icons.chat_bubble,
          color: Colors.orange,
        ),
        _StatsCard(
          title: 'Racha actual',
          subtitle: 'Días consecutivos',
          value: '${_stats.currentStreak}',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
        ),
        _StatsCard(
          title: 'Mejor racha',
          subtitle: 'Récord personal',
          value: '${_stats.bestStreak}',
          icon: Icons.emoji_events,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildAchievementsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              '/achievement-detail',
              arguments: {
                'achievement': achievement,
                'stats': _stats,
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: _AchievementCard(
            achievement: achievement,
            stats: _stats,
          ),
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final SpiritualStats stats;

  const _AchievementCard({
    required this.achievement,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked(stats);
    final progress = achievement.getProgress(stats);
    final progressPercent = (progress / achievement.target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? Colors.amber[900]?.withOpacity(0.3) : Colors.amber[50])
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? Colors.amber
              : Colors.grey.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'achievement_icon_${achievement.id}',
            child: Icon(
              achievement.icon,
              size: 32,
              color: isUnlocked
                  ? Colors.amber[700]
                  : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.amber[900] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.amber[700]!,
              ),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Text(
              '$progress/${achievement.target}',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.amber[700],
            ),
          ],
        ],
      ),
    );
  }
}
