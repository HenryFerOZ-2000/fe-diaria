import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos de uso',
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
              'Términos de Uso',
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
              'Al usar esta aplicación, aceptas estos términos de uso. Por favor, léelos cuidadosamente.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Aceptación de términos',
              'Al acceder y usar esta aplicación, aceptas cumplir con estos términos y todas las leyes y regulaciones aplicables.',
            ),
            _buildSection(
              'Uso de la aplicación',
              'Te comprometes a usar la aplicación de manera legal y ética. No debes usar la aplicación para ningún propósito ilegal o no autorizado.',
            ),
            _buildSection(
              'Contenido del usuario',
              'Eres responsable del contenido que publicas. No debes publicar contenido que sea difamatorio, ofensivo, ilegal o que viole los derechos de otros.',
            ),
            _buildSection(
              'Propiedad intelectual',
              'Todo el contenido de la aplicación, incluyendo textos, gráficos, logos y software, es propiedad de la aplicación o sus licenciantes y está protegido por leyes de derechos de autor.',
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Placeholder: mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace a términos completos próximamente'),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver términos completos'),
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

