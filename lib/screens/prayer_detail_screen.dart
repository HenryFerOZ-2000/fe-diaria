import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/prayer_card.dart';

/// Pantalla de detalle de oraciones por categoría
class PrayerDetailScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryRoute;

  const PrayerDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryRoute,
  });

  // Oraciones de ejemplo por categoría
  List<Map<String, dynamic>> _getPrayersForCategory() {
    switch (categoryRoute) {
      case 'morning':
        return [
          {
            'title': 'Oración de la Mañana',
            'text':
                'Señor, te doy gracias por este nuevo día. Bendice mis pasos y guía mis decisiones. Que tu luz ilumine mi camino y que tu amor llene mi corazón. Amén.',
          },
          {
            'title': 'Oración Matutina',
            'text':
                'Buenos días, Señor. Gracias por el descanso de la noche y por la oportunidad de un nuevo día. Te pido que me acompañes en todas mis actividades de hoy.',
          },
        ];
      case 'night':
        return [
          {
            'title': 'Oración de la Noche',
            'text':
                'Señor, al finalizar este día, te doy gracias por todas las bendiciones recibidas. Perdona mis errores y dame paz para descansar. Cuida de mí y de mis seres queridos esta noche. Amén.',
          },
        ];
      case 'health':
        return [
          {
            'title': 'Oración por la Salud',
            'text':
                'Señor, te pido por la salud de mi cuerpo y mi mente. Fortalece mi sistema inmunológico y dame la sabiduría para cuidar de mi salud. Bendice también a los médicos y enfermeros que cuidan de nosotros.',
          },
        ];
      case 'family':
        return [
          {
            'title': 'Oración por la Familia',
            'text':
                'Dios, bendice a mi familia. Unenos en amor y comprensión. Protege a cada uno de sus miembros y guíanos en el camino del bien. Que nuestro hogar sea un lugar de paz y alegría.',
          },
        ];
      case 'work':
        return [
          {
            'title': 'Oración por el Trabajo',
            'text':
                'Señor, bendice mi trabajo y mis esfuerzos. Dame la sabiduría y la fuerza para cumplir con mis responsabilidades. Que mi trabajo sea una bendición para otros y para mí.',
          },
        ];
      case 'anxiety':
        return [
          {
            'title': 'Oración contra la Ansiedad',
            'text':
                'Señor, en este momento de ansiedad, te pido paz. Calma mi corazón inquieto y dame la confianza de que estás conmigo. Ayúdame a confiar en tu plan perfecto.',
          },
        ];
      case 'protection':
        return [
          {
            'title': 'Oración de Protección',
            'text':
                'Señor, protégenos de todo mal. Cubre con tu manto sagrado a mi familia y a mí. Que tu ángel de la guarda nos acompañe siempre y nos libre de todo peligro.',
          },
        ];
      case 'thanksgiving':
        return [
          {
            'title': 'Oración de Agradecimiento',
            'text':
                'Dios, te doy gracias por todas tus bendiciones. Por la vida, la salud, la familia y todas las oportunidades que me has dado. Que mi corazón siempre esté lleno de gratitud.',
          },
        ];
      default:
        return [
          {
            'title': 'Oración',
            'text':
                'Señor, escucha mi petición y guía mi corazón según tu voluntad. Amén.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayers = _getPrayersForCategory();

    return AppScaffold(
      title: categoryTitle,
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: prayers.length,
        itemBuilder: (context, index) {
          final prayer = prayers[index];
          return PrayerCard(
            title: prayer['title'],
            text: prayer['text'],
            icon: Icons.favorite,
            onShare: () {
              // Funcionalidad de compartir
            },
          );
        },
      ),
    );
  }
}

