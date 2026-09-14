import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/social_service.dart';
import '../widgets/verbum_ambient_background.dart';

class WelcomeAuthScreen extends StatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  bool _isLoading = false;
  String? _error;
  int _selectedTab = 0; // 0 = Google, 1 = Email/Password
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn();

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && authProvider.isSignedIn) {
          await StorageService()
              .syncTraditionalPrayersReligionFromCloudForCurrentUser();
          // Sincronizar perfil con Firestore
          final social = SocialService();
          final user = authProvider.firebaseUser;
          if (user != null) {
            await social.syncCurrentUserProfile(
              displayName: user.displayName,
              photoURL: user.photoURL,
            );
          }

          await StorageService().setOnboardingCompleted(true);

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      if (_isSignUp) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _error = 'Las contraseñas no coinciden';
            _isLoading = false;
          });
          return;
        }
        await authProvider.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authProvider.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && authProvider.isSignedIn) {
          await StorageService()
              .syncTraditionalPrayersReligionFromCloudForCurrentUser();
          // Sincronizar perfil con Firestore
          final social = SocialService();
          final user = authProvider.firebaseUser;
          if (user != null) {
            await social.syncCurrentUserProfile(
              displayName:
                  user.displayName ?? _emailController.text.split('@').first,
              photoURL: user.photoURL,
            );
          }

          await StorageService().setOnboardingCompleted(true);

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Error al autenticarse';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No existe una cuenta con este correo';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Este correo ya está registrado';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'La contraseña es muy débil';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Correo electrónico inválido';
      } else {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('FirebaseAuthException: ', '');
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

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Ingresa tu correo electrónico';
      });
      return;
    }

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se envió un correo para restablecer tu contraseña'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error al enviar correo: ${e.toString()}';
      });
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await StorageService().setOnboardingCompleted(true);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'No se pudo continuar como invitado: $e';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.15, -.9),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: .10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .18),
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Verbum',
                        style: GoogleFonts.playfairDisplay(
                          color: colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? .20 : .09,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: .18),
                        ),
                      ),
                      child: Text(
                        'PASO 2 DE 2',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? colorScheme.primaryContainer
                              : colorScheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(
                          alpha: isDark ? 0.24 : 0.16,
                        ),
                        colorScheme.secondary.withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.16),
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.24 : 0.08,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu camino puede\nacompañarte siempre',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Text(
                          'Guarda tus oraciones, progreso y comunidades en todos tus dispositivos.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.76,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.18 : 0.07,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guarda tu camino',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige cómo quieres continuar. Crear una cuenta es opcional.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.4,
                          color: colorScheme.onSurface.withValues(alpha: 0.70),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_selectedTab == 0) _buildGoogleSignIn(context),
                      if (_selectedTab == 1) _buildEmailPasswordForm(context),
                      if (_selectedTab == 0) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _selectedTab = 1;
                              _error = null;
                            }),
                            icon: Icon(
                              Icons.email_outlined,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              'Usar correo electrónico',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade800,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _continueAsGuest,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: colorScheme.primary.withValues(
                                alpha: 0.28,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                          ),
                          child: Text(
                            _isLoading
                                ? 'Procesando...'
                                : 'Explorar sin crear una cuenta',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Al continuar aceptas nuestros',
                      style: GoogleFonts.inter(
                        fontSize: 11.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/terms'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text('Términos'),
                    ),
                    Text(
                      'y',
                      style: GoogleFonts.inter(
                        fontSize: 11.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/privacy-policy'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text('Privacidad'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignIn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'La forma más rápida de conservar tu progreso.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.g_mobiledata_rounded, size: 27),
            label: Text(
              _isLoading ? 'Conectando...' : 'Continuar con Google',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailPasswordForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selectedTab = 0;
                _error = null;
              }),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
              label: Text(
                'Volver a Google',
                style: GoogleFonts.inter(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -2,
                  vertical: -2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildAuthModeSelector(context),
          const SizedBox(height: 12),
          Text(
            _isSignUp
                ? 'Crea una cuenta con tu correo electrónico'
                : 'Ingresa con tu correo y contraseña',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.45,
              color: colorScheme.onSurface.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!value.contains('@')) {
                return 'Correo electrónico inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: _isSignUp
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: _isSignUp
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            onFieldSubmitted: _isSignUp
                ? null
                : (_) => _handleEmailPasswordAuth(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu contraseña';
              }
              if (_isSignUp && value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _handleEmailPasswordAuth(),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirma tu contraseña';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handlePasswordReset,
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailPasswordAuth,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget option({required String label, required bool signUp}) {
      final selected = _isSignUp == signUp;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isLoading
                ? null
                : () => setState(() {
                    _isSignUp = signUp;
                    _error = null;
                    _confirmPasswordController.clear();
                  }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? scheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? .20 : .08,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: scheme.outline.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          option(label: 'Iniciar sesión', signUp: false),
          option(label: 'Crear cuenta', signUp: true),
        ],
      ),
    );
  }
}
