import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../services/privacy_security_service.dart';

/// Cuenta y seguridad: contraseña, sesiones, bloqueos, documentos legales y
/// eliminación de la cuenta.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _sendPasswordReset(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PrivacySecurityService().sendPasswordResetEmail(email);
      messenger.showSnackBar(
        SnackBar(content: Text('Te enviamos un correo a $email')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No pudimos enviar el correo. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PrivacySecurityService();
    final usesPassword = service.isEmailPasswordUser();
    final scheme = Theme.of(context).colorScheme;
    void go(String route) => Navigator.of(context).pushNamed(route);

    return Scaffold(
      appBar: VAppBar(
        title: Text('Cuenta y seguridad', style: context.type.heading),
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
            'Seguridad',
            padding: EdgeInsets.fromLTRB(2, 16, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.lockSimple,
                title: 'Cambiar contraseña',
                subtitle: usesPassword
                    ? 'Te enviaremos un correo para restablecerla'
                    : 'Tu cuenta usa inicio de sesión con Google',
                trailing: usesPassword ? VerbumIcons.caretRight : null,
                onTap: usesPassword ? () => _sendPasswordReset(context) : null,
              ),
              VListRow(
                leading: VerbumIcons.devices,
                title: 'Sesiones y dispositivos',
                subtitle: 'Ver y gestionar sesiones activas',
                onTap: () => go('/sessions-devices'),
              ),
            ],
          ),
          const VSectionHeader(
            'Comunidad',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.prohibit,
                title: 'Usuarios bloqueados',
                subtitle: 'Gestiona a quién has bloqueado',
                onTap: () => go('/blocked-users'),
              ),
              VListRow(
                leading: VerbumIcons.flag,
                title: 'Reportar contenido',
                subtitle: 'Avísanos de contenido inapropiado',
                onTap: () => go('/report-content'),
              ),
            ],
          ),
          const VSectionHeader(
            'Información y control',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VListGroup(
            children: [
              VListRow(
                leading: VerbumIcons.shieldCheck,
                title: 'Política de privacidad',
                onTap: () => go('/privacy-policy'),
              ),
              VListRow(
                leading: VerbumIcons.fileText,
                title: 'Términos de uso',
                onTap: () => go('/terms'),
              ),
              VListRow(
                leading: VerbumIcons.trash,
                leadingColor: scheme.error,
                title: 'Eliminar cuenta',
                subtitle: 'Borra tu cuenta y tus datos de forma permanente',
                onTap: () => go('/delete-account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
