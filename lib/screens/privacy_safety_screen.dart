import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/privacy_security_service.dart';
import 'package:verbum/design_system/design_system.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  final _service = PrivacySecurityService();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Ya no cargamos configuraciones de perfil público
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacidad y seguridad',
          style: VerbumFonts.serif(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // A) Seguridad
                _buildSectionHeader('Seguridad'),
                const SizedBox(height: 8),
                _buildListTile(
                  icon: VerbumIcons.lockSimple,
                  title: 'Cambiar contraseña',
                  subtitle: _service.isEmailPasswordUser()
                      ? 'Enviar email de restablecimiento'
                      : 'Tu cuenta usa inicio de sesión externo',
                  onTap: _service.isEmailPasswordUser()
                      ? () => _handleChangePassword()
                      : null,
                ),
                _buildListTile(
                  icon: VerbumIcons.devices,
                  title: 'Sesiones y dispositivos',
                  subtitle: 'Ver y gestionar sesiones activas',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/sessions-devices'),
                ),
                _buildListTile(
                  icon: VerbumIcons.shieldCheck,
                  title: 'Autenticación en dos pasos',
                  subtitle: 'Añade una capa extra de seguridad',
                  onTap: () => _showPlaceholder(
                    'Autenticación en dos pasos próximamente',
                  ),
                ),
                const SizedBox(height: 24),
                // B) Bloqueos y reportes
                _buildSectionHeader('Bloqueos y reportes'),
                const SizedBox(height: 8),
                _buildListTile(
                  icon: VerbumIcons.prohibit,
                  title: 'Usuarios bloqueados',
                  subtitle: 'Gestiona usuarios que has bloqueado',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/blocked-users'),
                ),
                _buildListTile(
                  icon: VerbumIcons.flag,
                  title: 'Reportar contenido',
                  subtitle: 'Reporta contenido inapropiado',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/report-content'),
                ),
                const SizedBox(height: 24),
                // C) Información legal y control
                _buildSectionHeader('Información legal y control'),
                const SizedBox(height: 8),
                _buildListTile(
                  icon: VerbumIcons.shieldCheck,
                  title: 'Política de privacidad',
                  subtitle: 'Lee nuestra política de privacidad',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/privacy-policy'),
                ),
                _buildListTile(
                  icon: VerbumIcons.fileText,
                  title: 'Términos de uso',
                  subtitle: 'Lee nuestros términos de uso',
                  onTap: () => Navigator.of(context).pushNamed('/terms'),
                ),
                _buildListTile(
                  icon: VerbumIcons.trash,
                  title: 'Eliminar cuenta',
                  subtitle: 'Elimina permanentemente tu cuenta',
                  titleColor: Colors.red,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/delete-account'),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: VerbumFonts.sans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildListTile({
    required VerbumIcons icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: VIcon(icon, color: titleColor),
        title: Text(
          title,
          style: VerbumFonts.sans(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: VerbumFonts.sans(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const VIcon(VerbumIcons.caretRight),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    try {
      await _service.sendPasswordResetEmail(user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de restablecimiento enviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
