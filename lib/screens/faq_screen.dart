import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/help_support_service.dart';

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
      'answer': 'El chat espiritual es un asistente basado en IA que te ayuda con preguntas sobre la fe, la Biblia y la vida espiritual. Puedes hacer preguntas y recibir respuestas personalizadas y compasivas.',
    },
    {
      'question': '¿Cómo publico una oración?',
      'answer': 'Ve a la pestaña "En vivo" y toca el botón "+" en la esquina inferior derecha. Escribe tu oración (mínimo 10 caracteres) y presiona "Publicar". Tu oración aparecerá en el feed para que otros puedan verla y unirse en oración.',
    },
    {
      'question': '¿Cómo reporto contenido inapropiado?',
      'answer': 'Puedes reportar contenido desde el menú de tres puntos en cualquier publicación, o desde Perfil > Privacidad y seguridad > Reportar contenido. Todos los reportes son revisados por nuestro equipo.',
    },
    {
      'question': '¿Qué son las rachas?',
      'answer': 'Las rachas (streaks) son días consecutivos en los que usas la app. Cada día que abres la app y ves el versículo del día, tu racha aumenta. Puedes ver tu racha actual y mejor racha en Perfil > Mis rachas.',
    },
    {
      'question': '¿Cómo bloqueo a un usuario?',
      'answer': 'Ve al perfil del usuario que quieres bloquear y toca el menú de opciones. Selecciona "Bloquear usuario". Puedes gestionar usuarios bloqueados en Perfil > Privacidad y seguridad > Usuarios bloqueados.',
    },
    {
      'question': '¿Cómo cambio mi contraseña?',
      'answer': 'Si usas email y contraseña, ve a Perfil > Privacidad y seguridad > Cambiar contraseña. Se enviará un email con instrucciones para restablecer tu contraseña. Si usas Google o Apple, tu contraseña se gestiona desde esos servicios.',
    },
    {
      'question': '¿Qué son los logros?',
      'answer': 'Los logros son medallas que puedes desbloquear al completar diferentes objetivos, como mantener una racha de días, leer versículos o completar oraciones. Puedes ver tus logros en Perfil > Mis datos espirituales.',
    },
    {
      'question': '¿Cómo guardo un versículo favorito?',
      'answer': 'Toca el ícono de corazón en cualquier versículo para guardarlo en tus favoritos. Puedes ver todos tus versículos favoritos desde la pantalla principal.',
    },
    {
      'question': '¿Cómo funcionan las notificaciones?',
      'answer': 'Puedes configurar notificaciones para recibir el versículo del día y las oraciones. Ve a Configuración para personalizar los horarios y tipos de notificaciones que deseas recibir.',
    },
    {
      'question': '¿Puedo eliminar mi cuenta?',
      'answer': 'Sí, puedes eliminar tu cuenta desde Perfil > Privacidad y seguridad > Eliminar cuenta. Esta acción es permanente e irreversible. Se eliminará toda tu información y publicaciones.',
    },
    {
      'question': '¿Cómo contacto con soporte?',
      'answer': 'Puedes contactarnos desde Perfil > Ayuda y soporte > Contacto. También puedes reportar problemas desde la misma sección. Responderemos a tu consulta lo antes posible.',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Preguntas frecuentes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en FAQ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          // Lista de FAQ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron resultados',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                item['question'] ?? '',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    item['answer'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
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

