import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _openEmail(BuildContext context) {
    // TODO: Cuando url_launcher esté disponible, usar estas variables:
    // final user = FirebaseAuth.instance.currentUser;
    // final uid = user?.uid ?? 'N/A';
    // final email = user?.email ?? 'usuario@ejemplo.com';
    // final version = AppConstants.appVersion;
    // final platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown');
    // final subject = Uri.encodeComponent('Soporte - Verbum');
    // final body = Uri.encodeComponent(
    //   'Hola,\n\n'
    //   'UID: $uid\n'
    //   'Email: $email\n'
    //   'Versión de la app: $version\n'
    //   'Plataforma: $platform\n\n'
    //   'Descripción del problema o consulta:\n',
    // );
    // final mailtoUri = 'mailto:${AppConstants.supportEmail}?subject=$subject&body=$body';
    // await launchUrl(Uri.parse(mailtoUri));

    // TODO: Cuando url_launcher esté disponible, usar:
    // final subject = Uri.encodeComponent('Soporte - Verbum');
    // final body = Uri.encodeComponent(
    //   'Hola,\n\n'
    //   'UID: $uid\n'
    //   'Email: $email\n'
    //   'Versión de la app: $version\n'
    //   'Plataforma: $platform\n\n'
    //   'Descripción del problema o consulta:\n',
    // );
    // final mailtoUri = 'mailto:${AppConstants.supportEmail}?subject=$subject&body=$body';
    // await launchUrl(Uri.parse(mailtoUri));

    // Por ahora, mostrar el email para que el usuario pueda copiarlo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email: ${AppConstants.supportEmail}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _openWhatsApp(BuildContext context) {
    if (AppConstants.supportWhatsApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp no disponible')),
      );
      return;
    }

    // TODO: Usar url_launcher cuando esté disponible
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('WhatsApp: ${AppConstants.supportWhatsApp}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayuda y soporte',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ
          _buildSectionHeader('Ayuda'),
          const SizedBox(height: 8),
          _buildListTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Preguntas frecuentes (FAQ)',
            subtitle: 'Encuentra respuestas a las preguntas más comunes',
            onTap: () => Navigator.of(context).pushNamed('/faq'),
          ),
          const SizedBox(height: 24),
          // Contacto
          _buildSectionHeader('Contacto'),
          const SizedBox(height: 8),
          _buildListTile(
            context: context,
            icon: Icons.mail_outline,
            title: 'Enviar email',
            subtitle: AppConstants.supportEmail,
            onTap: () => _openEmail(context),
          ),
          if (AppConstants.supportWhatsApp != null) ...[
            const SizedBox(height: 8),
            _buildListTile(
              context: context,
              icon: Icons.chat_outlined,
              title: 'WhatsApp',
              subtitle: 'Chatea con nosotros',
              onTap: () => _openWhatsApp(context),
            ),
          ],
          const SizedBox(height: 24),
          // Reportes
          _buildSectionHeader('Reportes'),
          const SizedBox(height: 8),
          _buildListTile(
            context: context,
            icon: Icons.bug_report_outlined,
            title: 'Reportar un problema',
            subtitle: 'Reporta bugs, sugerencias o problemas',
            onTap: () => Navigator.of(context).pushNamed('/report-problem'),
          ),
          const SizedBox(height: 24),
          // Legal
          _buildSectionHeader('Información legal'),
          const SizedBox(height: 8),
          _buildListTile(
            context: context,
            icon: Icons.description_outlined,
            title: 'Términos y Privacidad',
            subtitle: 'Lee nuestros términos y política de privacidad',
            onTap: () {
              // Reutilizar pantallas existentes
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Términos y Privacidad'),
                  content: const Text('¿Qué deseas ver?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/terms');
                      },
                      child: const Text('Términos'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/privacy-policy');
                      },
                      child: const Text('Privacidad'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
