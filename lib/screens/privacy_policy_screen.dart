import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Política de privacidad',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Última actualización: ${DateTime.now().year}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Respetamos tu privacidad y nos comprometemos a proteger tus datos personales. Esta política describe cómo recopilamos, usamos y protegemos tu información.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Información que recopilamos',
              'Recopilamos información que nos proporcionas directamente, como tu nombre, email y foto de perfil cuando creas una cuenta.',
            ),
            _buildSection(
              'Cómo usamos tu información',
              'Utilizamos tu información para proporcionar, mantener y mejorar nuestros servicios, personalizar tu experiencia y comunicarnos contigo.',
            ),
            _buildSection(
              'Protección de datos',
              'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal contra acceso no autorizado, alteración, divulgación o destrucción.',
            ),
            _buildSection(
              'Tus derechos',
              'Tienes derecho a acceder, rectificar, eliminar o portar tus datos personales. También puedes oponerte al procesamiento de tus datos en ciertas circunstancias.',
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Placeholder: mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace a política completa próximamente'),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver política completa'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

