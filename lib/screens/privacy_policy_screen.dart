import 'package:flutter/material.dart';
import 'package:verbum/design_system/design_system.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      'Información que recopilamos',
      'Recopilamos información que nos proporcionas directamente, como tu nombre, email y foto de perfil cuando creas una cuenta.',
    ),
    (
      'Cómo usamos tu información',
      'Utilizamos tu información para proporcionar, mantener y mejorar nuestros servicios, personalizar tu experiencia y comunicarnos contigo.',
    ),
    (
      'Protección de datos',
      'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal contra acceso no autorizado, alteración, divulgación o destrucción.',
    ),
    (
      'Tus derechos',
      'Tienes derecho a acceder, rectificar, eliminar o portar tus datos personales. También puedes oponerte al procesamiento de tus datos en ciertas circunstancias.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Scaffold(
      appBar: VAppBar(title: Text('Política de privacidad', style: t.heading)),
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
          Text('Política de privacidad', style: t.title),
          const SizedBox(height: 12),
          Text(
            'Respetamos tu privacidad y nos comprometemos a proteger tus datos personales. Esta política describe cómo recopilamos, usamos y protegemos tu información.',
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
            label: 'Ver política completa',
            icon: VerbumIcons.arrowSquareOut,
            variant: VButtonVariant.outlined,
            expanded: true,
            onPressed: () {
              // Placeholder: mostrar mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace a política completa próximamente'),
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
