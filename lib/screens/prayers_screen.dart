import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';
import 'prayer_detail_screen.dart';

/// Pantalla de categorías de oraciones
class PrayersScreen extends StatelessWidget {
  const PrayersScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Oración de la mañana',
      'description': 'Oraciones para comenzar el día',
      'icon': Icons.wb_sunny,
      'route': 'morning',
    },
    {
      'title': 'Oración de la noche',
      'description': 'Oraciones para descansar en paz',
      'icon': Icons.nightlight_round,
      'route': 'night',
    },
    {
      'title': 'Por salud',
      'description': 'Oraciones por la salud física y mental',
      'icon': Icons.favorite,
      'route': 'health',
    },
    {
      'title': 'Por familia',
      'description': 'Oraciones por la familia y seres queridos',
      'icon': Icons.family_restroom,
      'route': 'family',
    },
    {
      'title': 'Por trabajo',
      'description': 'Oraciones por el trabajo y la prosperidad',
      'icon': Icons.work,
      'route': 'work',
    },
    {
      'title': 'Por ansiedad',
      'description': 'Oraciones para calmar la ansiedad y el estrés',
      'icon': Icons.psychology,
      'route': 'anxiety',
    },
    {
      'title': 'Por protección',
      'description': 'Oraciones de protección y seguridad',
      'icon': Icons.shield,
      'route': 'protection',
    },
    {
      'title': 'Por agradecimiento',
      'description': 'Oraciones de gratitud y agradecimiento',
      'icon': Icons.celebration,
      'route': 'thanksgiving',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Oraciones',
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryCard(
            title: category['title'],
            description: category['description'],
            icon: category['icon'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrayerDetailScreen(
                    categoryTitle: category['title'],
                    categoryRoute: category['route'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

