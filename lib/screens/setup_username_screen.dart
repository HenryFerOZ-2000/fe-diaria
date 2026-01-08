import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/social_service.dart';

class SetupUsernameScreen extends StatefulWidget {
  const SetupUsernameScreen({super.key});

  @override
  State<SetupUsernameScreen> createState() => _SetupUsernameScreenState();
}

class _SetupUsernameScreenState extends State<SetupUsernameScreen> {
  final _usernameController = TextEditingController();
  final _social = SocialService();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _error;
  String _suggestedUsername = '';

  @override
  void initState() {
    super.initState();
    _generateSuggestedUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _generateSuggestedUsername() {
    final user = _auth.currentUser;
    if (user != null) {
      final suggested = _social.generateAutoUsername(
        user.email,
        user.displayName,
      );
      setState(() {
        _suggestedUsername = suggested;
        _usernameController.text = suggested;
      });
    }
  }

  bool _validUsername(String value) {
    return RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(value.trim().toLowerCase());
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim().toLowerCase();
    
    if (username.isEmpty) {
      setState(() {
        _error = 'El username no puede estar vacío';
      });
      return;
    }

    if (!_validUsername(username)) {
      setState(() {
        _error = 'Username inválido: usa 3-20 caracteres [a-z0-9._]';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _social.setUsername(username);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      String errorMessage = 'Error al guardar username';
      if (e.toString().contains('username_taken') || 
          e.toString().contains('already-exists')) {
        errorMessage = 'Este username ya está en uso. Prueba con otro.';
      } else if (e.toString().contains('username_invalid')) {
        errorMessage = 'Username inválido: usa 3-20 caracteres [a-z0-9._]';
      }
      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                '¡Bienvenido!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Elige un nombre de usuario para tu perfil',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'ejemplo: usuario123',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface.withOpacity(0.5),
                ),
                style: GoogleFonts.inter(),
                onChanged: (value) {
                  setState(() {
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo minúsculas, números, punto o guión bajo (3-20 caracteres)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      color: Colors.red.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUsername,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continuar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  _usernameController.text = _suggestedUsername;
                  setState(() {
                    _error = null;
                  });
                },
                child: Text(
                  'Usar sugerencia: $_suggestedUsername',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

