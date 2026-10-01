import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/privacy_security_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'package:provider/provider.dart';
import 'package:verbum/design_system/design_system.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _service = PrivacySecurityService();
  final _auth = FirebaseAuth.instance;
  bool _isConfirmed = false;
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes confirmar la eliminación')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    try {
      // Registrar solicitud en Firestore
      await _service.requestAccountDeletion(user.uid, user.email ?? '');

      // Intentar eliminar la cuenta de Firebase Auth
      try {
        await user.delete();
      } catch (e) {
        // Si requiere re-autenticación, mostrar mensaje
        if (e.toString().contains('requires-recent-login')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Por seguridad, debes volver a iniciar sesión antes de eliminar tu cuenta',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() => _isDeleting = false);
          return;
        }
        rethrow;
      }

      // Cerrar sesión (Google Sign In, etc.). La UI se actualiza sola por authStateChanges.
      if (mounted) {
        await context.read<app_auth.AuthProvider>().signOut();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar cuenta: $e')));
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: VAppBar(title: Text('Eliminar cuenta', style: t.heading)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VerbumSpace.gutter,
          8,
          VerbumSpace.gutter,
          40,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(VerbumRadius.tile),
            ),
            child: Row(
              children: [
                VIcon(
                  VerbumIcons.warning,
                  weight: VIconWeight.fill,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta acción no se puede deshacer',
                    style: t.bodyStrong.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VSectionHeader(
            '¿Qué se eliminará?',
            padding: EdgeInsets.fromLTRB(2, 24, 2, 10),
          ),
          VSurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Column(
              children: [
                _buildListItem('Tu perfil y toda tu información personal'),
                _buildListItem('Todas tus publicaciones y comentarios'),
                _buildListItem('Tu historial de actividad'),
                _buildListItem('Tus configuraciones y preferencias'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          VSurfaceCard(
            padding: EdgeInsets.zero,
            onTap: () => setState(() => _isConfirmed = !_isConfirmed),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
              child: Row(
                children: [
                  Checkbox(
                    value: _isConfirmed,
                    onChanged: (value) {
                      setState(() => _isConfirmed = value ?? false);
                    },
                    activeColor: scheme.error,
                    checkColor: scheme.onError,
                    side: BorderSide(color: p.line, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Entiendo que esta acción es permanente e irreversible',
                      style: t.bodyStrong,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isConfirmed && !_isDeleting ? _deleteAccount : null,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              disabledBackgroundColor: p.surfaceMuted,
              disabledForegroundColor: p.inkSubtle,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VerbumRadius.control),
              ),
            ),
            child: _isDeleting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onError,
                    ),
                  )
                : const Text('Eliminar cuenta permanentemente'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: VIcon(VerbumIcons.minus, size: 16, color: p.inkSubtle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.type.body.copyWith(color: p.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
