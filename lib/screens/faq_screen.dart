import 'package:flutter/material.dart';
import '../services/help_support_service.dart';
import 'package:verbum/design_system/design_system.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _service = HelpSupportService();
  List<Map<String, dynamic>> _faqItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // FAQ local por defecto
  static const List<Map<String, dynamic>> _defaultFaq = [
    {
      'question': '¿Cómo funciona el chat espiritual?',
      'answer':
          'El chat espiritual es un asistente basado en IA que te ayuda con preguntas sobre la fe, la Biblia y la vida espiritual. Puedes hacer preguntas y recibir respuestas personalizadas y compasivas.',
    },
    {
      'question': '¿Cómo publico una oración?',
      'answer':
          'Ve a la pestaña "En vivo" y toca el botón "+" en la esquina inferior derecha. Escribe tu oración (mínimo 10 caracteres) y presiona "Publicar". Tu oración aparecerá en el feed para que otros puedan verla y unirse en oración.',
    },
    {
      'question': '¿Cómo reporto contenido inapropiado?',
      'answer':
          'Puedes reportar contenido desde el menú de tres puntos en cualquier publicación, o desde Perfil > Privacidad y seguridad > Reportar contenido. Todos los reportes son revisados por nuestro equipo.',
    },
    {
      'question': '¿Qué son las rachas?',
      'answer':
          'La racha representa tu constancia espiritual en Verbum. Cada día aumenta cuando completas los tres momentos esenciales de la pantalla Hoy: recibir la Palabra, hacerla oración y realizar la práctica diaria. Puedes consultar tu recorrido desde la tarjeta Tu constancia o en Perfil > Mi constancia.',
    },
    {
      'question': '¿Cómo bloqueo a un usuario?',
      'answer':
          'Ve al perfil del usuario que quieres bloquear y toca el menú de opciones. Selecciona "Bloquear usuario". Puedes gestionar usuarios bloqueados en Perfil > Privacidad y seguridad > Usuarios bloqueados.',
    },
    {
      'question': '¿Cómo cambio mi contraseña?',
      'answer':
          'Si usas email y contraseña, ve a Perfil > Privacidad y seguridad > Cambiar contraseña. Se enviará un email con instrucciones para restablecer tu contraseña. Si usas Google o Apple, tu contraseña se gestiona desde esos servicios.',
    },
    {
      'question': '¿Qué son los logros?',
      'answer':
          'Los logros son medallas que puedes desbloquear al completar diferentes objetivos, como mantener una racha de días, leer versículos o completar oraciones. Puedes ver tus logros en Perfil > Mis datos espirituales.',
    },
    {
      'question': '¿Cómo guardo un versículo favorito?',
      'answer':
          'Toca el ícono de corazón en cualquier versículo para guardarlo en tus favoritos. Puedes ver todos tus versículos favoritos desde la pantalla principal.',
    },
    {
      'question': '¿Cómo funcionan las notificaciones?',
      'answer':
          'Puedes configurar notificaciones para recibir el versículo del día y las oraciones. Ve a Configuración para personalizar los horarios y tipos de notificaciones que deseas recibir.',
    },
    {
      'question': '¿Puedo eliminar mi cuenta?',
      'answer':
          'Sí, puedes eliminar tu cuenta desde Perfil > Privacidad y seguridad > Eliminar cuenta. Esta acción es permanente e irreversible. Se eliminará toda tu información y publicaciones.',
    },
    {
      'question': '¿Cómo contacto con soporte?',
      'answer':
          'Puedes contactarnos desde Perfil > Ayuda y soporte > Contacto. También puedes reportar problemas desde la misma sección. Responderemos a tu consulta lo antes posible.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFaq();
    _searchController.addListener(_filterFaq);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaq() async {
    setState(() => _isLoading = true);
    try {
      // Intentar cargar desde Firestore
      final firestoreFaq = await _service.getFaqFromFirestore();
      if (firestoreFaq != null && firestoreFaq.isNotEmpty) {
        setState(() {
          _faqItems = firestoreFaq;
          _filteredItems = firestoreFaq;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading FAQ from Firestore: $e');
    }

    // Usar FAQ local por defecto
    setState(() {
      _faqItems = _defaultFaq;
      _filteredItems = _defaultFaq;
      _isLoading = false;
    });
  }

  void _filterFaq() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredItems = _faqItems);
      return;
    }

    setState(() {
      _filteredItems = _faqItems.where((item) {
        final question = (item['question'] ?? '').toString().toLowerCase();
        final answer = (item['answer'] ?? '').toString().toLowerCase();
        return question.contains(query) || answer.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Scaffold(
      appBar: VAppBar(title: Text('Preguntas frecuentes', style: t.heading)),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              8,
              VerbumSpace.gutter,
              12,
            ),
            child: TextField(
              controller: _searchController,
              style: t.body,
              decoration: InputDecoration(
                hintText: 'Buscar en las preguntas…',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VIcon(
                    VerbumIcons.magnifyingGlass,
                    size: 20,
                    color: p.inkMuted,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: _searchController.text.isNotEmpty
                    ? VIconButton(
                        icon: VerbumIcons.close,
                        semanticLabel: 'Borrar búsqueda',
                        variant: VIconButtonVariant.ghost,
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Lista de FAQ
          Expanded(
            child: _isLoading
                ? const Center(
                    child: VEmptyState(
                      title: 'Cargando preguntas',
                      loading: true,
                    ),
                  )
                : _filteredItems.isEmpty
                ? const Center(
                    child: VEmptyState(
                      icon: VerbumIcons.magnifyingGlassMinus,
                      title: 'No se encontraron resultados',
                      message: 'Prueba con otras palabras.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      VerbumSpace.gutter,
                      0,
                      VerbumSpace.gutter,
                      32,
                    ),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return VSurfaceCard(
                        padding: EdgeInsets.zero,
                        radius: VerbumRadius.tile,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            iconColor: p.rubric,
                            collapsedIconColor: p.inkSubtle,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 4,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              18,
                              0,
                              18,
                              18,
                            ),
                            title: Text(
                              item['question'] ?? '',
                              style: t.bodyStrong,
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item['answer'] ?? '',
                                  style: t.body.copyWith(
                                    color: p.inkMuted,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
