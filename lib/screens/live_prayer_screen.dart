import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/live_prayer_card.dart';

/// Pantalla de red social de oraciones en vivo
class LivePrayerScreen extends StatefulWidget {
  const LivePrayerScreen({super.key});

  @override
  State<LivePrayerScreen> createState() => _LivePrayerScreenState();
}

class _LivePrayerScreenState extends State<LivePrayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'En Vivo',
      body: Column(
        children: [
          // Pestañas
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Comunidad'),
              Tab(text: 'Mis Oraciones'),
              Tab(text: 'Eventos Mundiales'),
            ],
            labelColor: AppColors.primaryLight,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primaryLight,
          ),
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CommunityTab(),
                _MyPrayersTab(),
                _WorldEventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  // Datos de ejemplo - en el futuro vendrán de Firebase
  final List<Map<String, dynamic>> _prayers = [
    {
      'userName': 'María González',
      'userAvatar': '',
      'prayerText':
          'Por favor, oren por mi familia en este momento difícil. Necesitamos fuerza y paz.',
      'likes': 24,
      'comments': 8,
    },
    {
      'userName': 'Carlos Rodríguez',
      'userAvatar': '',
      'prayerText':
          'Doy gracias a Dios por todas las bendiciones recibidas. Que Él siga guiando nuestros pasos.',
      'likes': 45,
      'comments': 12,
    },
    {
      'userName': 'Ana Martínez',
      'userAvatar': '',
      'prayerText':
          'Oren por los enfermos y por quienes están pasando por momentos de angustia. Que encuentren consuelo.',
      'likes': 67,
      'comments': 15,
    },
    {
      'userName': 'Pedro Sánchez',
      'userAvatar': '',
      'prayerText':
          'Pido oración por mi trabajo y por las decisiones importantes que debo tomar esta semana.',
      'likes': 19,
      'comments': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _prayers.length,
      itemBuilder: (context, index) {
        final prayer = _prayers[index];
        return LivePrayerCard(
          userName: prayer['userName'],
          userAvatar: prayer['userAvatar'],
          prayerText: prayer['prayerText'],
          likes: prayer['likes'],
          comments: prayer['comments'],
          onJoinPrayer: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Te uniste a la oración de ${prayer['userName']}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          onLike: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Like agregado'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          onComment: () {
            // Navegar a pantalla de comentarios (por implementar)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funcionalidad de comentarios próximamente'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}

class _MyPrayersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tus oraciones aparecerán aquí',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Comparte tus peticiones con la comunidad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de crear oración próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear oración'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldEventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Eventos mundiales de oración',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Únete a oraciones globales y eventos especiales',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

