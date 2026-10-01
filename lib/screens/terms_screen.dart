import 'package:flutter/material.dart';
import 'package:verbum/design_system/design_system.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Aceptación de términos',
      'Al acceder y usar esta aplicación, aceptas cumplir con estos términos y todas las leyes y regulaciones aplicables.',
    ),
    (
      'Uso de la aplicación',
      'Te comprometes a usar la aplicación de manera legal y ética. No debes usar la aplicación para ningún propósito ilegal o no autorizado.',
    ),
    (
      'Contenido del usuario',
      'Eres responsable del contenido que publicas. No debes publicar contenido que sea difamatorio, ofensivo, ilegal o que viole los derechos de otros.',
    ),
    (
      'Propiedad intelectual',
      'Todo el contenido de la aplicación, incluyendo textos, gráficos, logos y software, es propiedad de la aplicación o sus licenciantes y está protegido por leyes de derechos de autor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Scaffold(
      appBar: VAppBar(title: Text('Términos de uso', style: t.heading)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          8,
          VerbumSpace.gutter,
          40,
        ),
        children: [
          Text('Última actualización: ${DateTime.now().year}', style: t.rubric),
          const SizedBox(height: 10),
          Text('Términos de uso', style: t.title),
          const SizedBox(height: 12),
          Text(
            'Al usar esta aplicación, aceptas estos términos de uso. Por favor, léelos cuidadosamente.',
            style: t.body.copyWith(color: p.inkMuted, height: 1.6),
          ),
          const SizedBox(height: 20),
          VSurfaceCard(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, content) in _sections)
                  _Section(title: title, content: content),
              ],
            ),
          ),
          const SizedBox(height: 24),
          VButton(
            label: 'Ver términos completos',
            icon: VerbumIcons.arrowSquareOut,
            variant: VButtonVariant.outlined,
            expanded: true,
            onPressed: () {
              // Placeholder: mostrar mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace a términos completos próximamente'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.bodyStrong.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            content,
            style: t.body.copyWith(
              color: context.palette.inkMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
