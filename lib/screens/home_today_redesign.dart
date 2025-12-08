import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/today_task_card.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';

/// Pantalla rediseñada de "Hoy" con el viaje del día
class HomeTodayRedesign extends StatefulWidget {
  const HomeTodayRedesign({super.key});

  @override
  State<HomeTodayRedesign> createState() => _HomeTodayRedesignState();
}

class _HomeTodayRedesignState extends State<HomeTodayRedesign> {
  // Estado de las tareas (por ahora se guarda localmente)
  bool _verseCompleted = false;
  bool _morningPrayerCompleted = false;
  bool _nightPrayerCompleted = false;
  bool _devotionalCompleted = false;
  int _streak = 7; // Racha actual

  @override
  void initState() {
    super.initState();
    _loadTaskStates();
    _loadStreak();
  }

  void _loadTaskStates() {
    // Cargar estados de las tareas desde StorageService
    final storage = StorageService();
    setState(() {
      _verseCompleted = storage.getTaskCompleted('verse') ?? false;
      _morningPrayerCompleted = storage.getTaskCompleted('morning_prayer') ?? false;
      _nightPrayerCompleted = storage.getTaskCompleted('night_prayer') ?? false;
      _devotionalCompleted = storage.getTaskCompleted('devotional') ?? false;
    });
  }

  void _loadStreak() {
    // Cargar racha desde StorageService
    final storage = StorageService();
    setState(() {
      _streak = storage.getStreak() ?? 7;
    });
  }

  void _completeTask(String taskId) {
    final storage = StorageService();
    storage.setTaskCompleted(taskId, true);
    
    setState(() {
      switch (taskId) {
        case 'verse':
          _verseCompleted = true;
          break;
        case 'morning_prayer':
          _morningPrayerCompleted = true;
          break;
        case 'night_prayer':
          _nightPrayerCompleted = true;
          break;
        case 'devotional':
          _devotionalCompleted = true;
          break;
      }
    });

    // Verificar si todas las tareas están completas
    if (_verseCompleted &&
        _morningPrayerCompleted &&
        _nightPrayerCompleted &&
        _devotionalCompleted) {
      // Incrementar racha si es el primer día completo
      final today = DateTime.now();
      final lastCompletedDate = storage.getLastCompletedDate();
      if (lastCompletedDate == null ||
          !_isSameDay(lastCompletedDate, today)) {
        setState(() {
          _streak++;
        });
        storage.setStreak(_streak);
        storage.setLastCompletedDate(today);
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  double _getProgress() {
    int completed = 0;
    if (_verseCompleted) completed++;
    if (_morningPrayerCompleted) completed++;
    if (_nightPrayerCompleted) completed++;
    if (_devotionalCompleted) completed++;
    return completed / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context);
    final progress = _getProgress();

    return AppScaffold(
      title: 'Hoy',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: "El viaje de Hoy"
            Text(
              'El viaje de Hoy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Racha y progreso
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.primaryDark,
                            size: 32,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Racha',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                '$_streak días',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primaryDark.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDark,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Tareas del día
            TodayTaskCard(
              title: 'Tu versículo',
              subtitle: provider.todayVerse?.text ?? 'Cargando versículo...',
              duration: '1 min',
              isCompleted: _verseCompleted,
              icon: Icons.book,
              onTap: () {
                if (!_verseCompleted) {
                  _completeTask('verse');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Versículo completado!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            TodayTaskCard(
              title: 'Oración del día',
              subtitle: provider.currentPrayer?.text ??
                  'Cargando oración...',
              duration: '2 min',
              isCompleted: provider.isMorningPrayerTime
                  ? _morningPrayerCompleted
                  : _nightPrayerCompleted,
              icon: provider.isMorningPrayerTime
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
              onTap: () {
                final taskId =
                    provider.isMorningPrayerTime ? 'morning_prayer' : 'night_prayer';
                if ((provider.isMorningPrayerTime
                        ? !_morningPrayerCompleted
                        : !_nightPrayerCompleted)) {
                  _completeTask(taskId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Oración completada!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            TodayTaskCard(
              title: 'Oración de la noche',
              subtitle: provider.todayEveningPrayer?.text ??
                  'Cargando oración...',
              duration: '2 min',
              isCompleted: _nightPrayerCompleted,
              icon: Icons.nightlight_round,
              onTap: () {
                if (!_nightPrayerCompleted) {
                  _completeTask('night_prayer');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Oración completada!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            TodayTaskCard(
              title: 'Devocional personalizado',
              subtitle: 'Reflexión diaria personalizada para ti',
              duration: '3 min',
              isCompleted: _devotionalCompleted,
              icon: Icons.auto_stories,
              onTap: () {
                if (!_devotionalCompleted) {
                  _completeTask('devotional');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Devocional completado!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

