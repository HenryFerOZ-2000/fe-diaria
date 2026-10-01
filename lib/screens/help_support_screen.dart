import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import 'package:verbum/design_system/design_system.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WhatsApp no disponible')));
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
    void go(String route) => Navigator.of(context).pushNamed(route);

    return Scaffold(
      appBar: VAppBar(
        title: Text('Ayuda y soporte', style: context.type.heading),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          0,
          VerbumSpace.gutter,
          32,
        ),
        children: [
          const VSectionHeader(
            'Ayuda',
            padding: EdgeInsets.fromLTRB(2, 16, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.question,
                title: 'Preguntas frecuentes',
                subtitle: 'Encuentra respuestas a las preguntas más comunes',
                onTap: () => go('/faq'),
              ),
            ],
          ),
          const VSectionHeader(
            'Contacto',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.envelope,
                title: 'Enviar correo',
                subtitle: AppConstants.supportEmail,
                onTap: () => _openEmail(context),
              ),
              if (AppConstants.supportWhatsApp != null)
                VListRow(
                  leading: VerbumIcons.chatCircle,
                  title: 'WhatsApp',
                  subtitle: 'Chatea con nosotros',
                  onTap: () => _openWhatsApp(context),
                ),
            ],
          ),
          const VSectionHeader(
            'Reportes',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.bug,
                title: 'Reportar un problema',
                subtitle: 'Reporta errores, sugerencias o problemas',
                onTap: () => go('/report-problem'),
              ),
            ],
          ),
          const VSectionHeader(
            'Información legal',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.fileText,
                title: 'Términos de uso',
                onTap: () => go('/terms'),
              ),
              VListRow(
                leading: VerbumIcons.shieldCheck,
                title: 'Política de privacidad',
                onTap: () => go('/privacy-policy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
