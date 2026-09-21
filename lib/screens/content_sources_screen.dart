import 'package:flutter/material.dart';
import '../widgets/source_link.dart';

class ContentSourcesScreen extends StatelessWidget {
  const ContentSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nuestra biblioteca y sus fuentes')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section(
          context,
          'Una fe, distintas tradiciones',
          'Católica, evangélica/protestante y cristiana general son opciones de tradición cristiana. La opción general no representa una iglesia concreta. Puedes cambiar tu elección sin perder tu progreso.',
        ),
        _section(
          context,
          'Católica',
          'Incluye oración tradicional y devociones como el rosario y las novenas. Una devoción no equivale a la liturgia oficial del día. Para doctrina y fórmulas católicas enlazamos la Santa Sede.',
        ),
        _link(
          context,
          'Compendio del Catecismo',
          'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
        ),
        _section(
          context,
          'Calendario Romano General',
          'La información base del día se genera a partir de Romcal y se guarda para funcionar sin conexión. Ecuador puede elegirse como calendario local, pero mientras no exista un paquete nacional verificado Verbum utiliza el Calendario Romano General y no afirma incluir todos los propios nacionales o diocesanos.',
        ),
        _link(
          context,
          'Romcal · proyecto y licencia',
          'https://github.com/romcal/romcal',
        ),
        _section(
          context,
          'Cómo nombramos a Dios',
          'En el contenido católico usamos normalmente Dios o Señor. Las citas bíblicas conservan su traducción: por eso una cita de la Reina-Valera 1909 puede contener Jehová sin que Verbum altere el texto.',
        ),
        _link(
          context,
          'Catecismo, nn. 206-209',
          'https://www.vatican.va/archive/catechism_sp/p1s2c1p1_sp.html',
        ),
        _section(
          context,
          'Evangélica / protestante',
          'Da prioridad a la lectura bíblica y la oración dirigida a Dios. Estas comunidades tienen diferencias doctrinales y litúrgicas; Verbum no atribuye a todas una única formulación ni recomienda devociones exclusivamente católicas en esta selección.',
        ),
        _section(
          context,
          'Cristiana general',
          'Ofrece un recorrido bíblico compartido y oraciones devocionales, sin atribuirlo a una denominación. La Biblia utilizada siempre se identifica por su edición.',
        ),
        _section(
          context,
          'La Biblia sin conexión',
          'Reina-Valera 1909: edición histórica de dominio público en español, con 39 libros del Antiguo Testamento y 27 del Nuevo. No es una edición católica completa. Tus marcas y tu última lectura pertenecen a esta edición.',
        ),
        _link(
          context,
          'Información editorial de RV1909',
          'https://ebible.org/spaRV1909/copyright.htm',
        ),
        _section(
          context,
          'Consulta católica en línea',
          'El Libro del Pueblo de Dios (1990), alojado por la Santa Sede. Su canon reúne 46 libros del Antiguo Testamento y 27 del Nuevo. Se consulta en la web; sus textos no se descargan ni se mezclan con RV1909.',
        ),
        _link(
          context,
          'Canon católico: Catecismo, n. 120',
          'https://www.vatican.va/archive/catechism_sp/p1s1c2a3_sp.html',
        ),
        _section(
          context,
          'Cómo identificamos las oraciones',
          'Texto bíblico: pasaje vinculado a su edición. Oración tradicional: fórmula recibida, que puede tener variantes. Composición devocional: oración del catálogo generada con IA, según confirmó el responsable de Verbum. No atribuimos esos textos a un santo o a una iglesia.',
        ),
        _section(
          context,
          'Sobre el uso de inteligencia artificial',
          'Las composiciones devocionales generadas con IA no son textos oficiales ni sustituyen las oraciones del calendario litúrgico. Pueden contener imprecisiones y siguen pendientes de revisión editorial y doctrinal. Una fórmula tradicional obtenida mediante IA conserva su origen tradicional; la Biblia se identifica por su edición, no como contenido generado.',
        ),
        _section(
          context,
          'Una biblioteca en revisión',
          'Las referencias oficiales sirven para consultar y contrastar. No implican que Verbum cuente con aprobación eclesial ni autorización para reproducir íntegramente esas publicaciones. Conocer que se utilizó IA no certifica fidelidad doctrinal, originalidad ni derechos sobre posibles coincidencias con otras obras.',
        ),
      ],
    ),
  );

  Widget _section(BuildContext context, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(body),
      ],
    ),
  );
  Widget _link(BuildContext context, String label, String url) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: OutlinedButton.icon(
      onPressed: () => openSource(context, url),
      icon: const Icon(Icons.open_in_new),
      label: Text(label),
    ),
  );
}
