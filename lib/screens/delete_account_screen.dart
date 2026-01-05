import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/privacy_security_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'package:provider/provider.dart';

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

      // Cerrar sesión
      if (mounted) {
        await context.read<app_auth.AuthProvider>().signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cuenta: $e')),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eliminar cuenta',
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Qué se eliminará?',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildListItem('Tu perfil y toda tu información personal'),
            _buildListItem('Todas tus publicaciones y comentarios'),
            _buildListItem('Tu historial de actividad'),
            _buildListItem('Tus configuraciones y preferencias'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: CheckboxListTile(
                title: Text(
                  'Entiendo que esta acción es permanente e irreversible',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                value: _isConfirmed,
                onChanged: (value) {
                  setState(() => _isConfirmed = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirmed && !_isDeleting ? _deleteAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Eliminar cuenta permanentemente',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.remove, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

