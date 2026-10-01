import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/social_service.dart';
import 'package:verbum/design_system/design_system.dart';

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
        _error = 'El nombre de usuario no puede estar vacío';
      });
      return;
    }

    if (!_validUsername(username)) {
      setState(() {
        _error = 'Nombre de usuario inválido: usa 3-20 caracteres [a-z0-9._]';
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
      String errorMessage = 'Error al guardar el nombre de usuario';
      if (e.toString().contains('username_taken') ||
          e.toString().contains('already-exists')) {
        errorMessage =
            'Este nombre de usuario ya está en uso. Prueba con otro.';
      } else if (e.toString().contains('username_invalid')) {
        errorMessage =
            'Nombre de usuario inválido: usa 3-20 caracteres [a-z0-9._]';
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
    final p = context.palette;
    final t = context.type;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VerbumSpace.gutter + 6,
            36,
            VerbumSpace.gutter + 6,
            32,
          ),
          children: [
            Text('Tu perfil', style: t.rubric),
            const SizedBox(height: 10),
            Text('¡Bienvenido!', style: t.display),
            const SizedBox(height: 10),
            Text(
              'Elige un nombre de usuario para tu perfil',
              style: t.body.copyWith(color: p.inkMuted, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              enabled: !_isLoading,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                hintText: 'ejemplo: usuario123',
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VIcon(VerbumIcons.at, size: 20, color: p.inkMuted),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
              ),
              style: t.body,
              onChanged: (value) {
                setState(() {
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: VIcon(VerbumIcons.info, size: 16, color: p.gold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Solo minúsculas, números, punto o guion bajo '
                    '(3-20 caracteres)',
                    style: t.caption.copyWith(color: p.inkMuted),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              VNotice(_error!, tone: VNoticeTone.error),
            ],
            const SizedBox(height: 28),
            VButton(
              label: 'Continuar',
              icon: VerbumIcons.arrowRight,
              expanded: true,
              loading: _isLoading,
              onPressed: _isLoading ? null : _saveUsername,
            ),
            const SizedBox(height: 8),
            if (_suggestedUsername.isNotEmpty)
              VButton(
                label: 'Usar sugerencia: $_suggestedUsername',
                variant: VButtonVariant.text,
                expanded: true,
                onPressed: _isLoading
                    ? null
                    : () {
                        _usernameController.text = _suggestedUsername;
                        setState(() {
                          _error = null;
                        });
                      },
              ),
          ],
        ),
      ),
    );
  }
}
