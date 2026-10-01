import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/social_service.dart';
import '../widgets/verbum_ambient_background.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/auth/domain/credential_validators.dart';
import '../features/onboarding/presentation/onboarding_chrome.dart';

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
    final type = context.type;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(1.15, -.9),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            children: [
              const OnboardingHeader(step: 'Paso 2 de 2'),
              const SizedBox(height: 26),
              const VRubricLabel('Guarda tu camino'),
              const SizedBox(height: 8),
              Text(
                'Tu camino puede acompañarte siempre',
                style: type.display.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 10),
              Text(
                'Guarda tus oraciones, progreso y comunidades en todos tus dispositivos. Crear una cuenta es opcional.',
                style: type.body.copyWith(fontSize: 14.5),
              ),
              const SizedBox(height: 20),
              VSurfaceCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedTab == 0)
                      _buildGoogleSignIn(context)
                    else
                      _buildEmailPasswordForm(context),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      VNotice(_error!, tone: VNoticeTone.error),
                    ],
                    const SizedBox(height: 12),
                    VButton(
                      label: 'Explorar sin crear una cuenta',
                      variant: VButtonVariant.outlined,
                      expanded: true,
                      onPressed: _isLoading ? null : _continueAsGuest,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Al continuar aceptas nuestros', style: type.caption),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/terms'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Términos'),
                  ),
                  Text('y', style: type.caption),
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
    );
  }

  Widget _buildGoogleSignIn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'La forma más rápida de conservar tu progreso.',
          textAlign: TextAlign.center,
          style: context.type.body,
        ),
        const SizedBox(height: 12),
        VButton(
          label: _isLoading ? 'Conectando…' : 'Continuar con Google',
          icon: VerbumIcons.googleLogo,
          iconLeading: true,
          expanded: true,
          loading: _isLoading,
          onPressed: _handleGoogleSignIn,
        ),
        const SizedBox(height: 6),
        Center(
          child: VButton(
            label: 'Usar correo electrónico',
            icon: VerbumIcons.envelope,
            iconLeading: true,
            variant: VButtonVariant.text,
            onPressed: () => setState(() {
              _selectedTab = 1;
              _error = null;
            }),
          ),
        ),
      ],
    );
  }

  InputDecoration _field(String label, VerbumIcons icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: VIcon(icon, size: 20, color: context.palette.inkSubtle),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      suffixIcon: suffix,
    );
  }

  Widget _visibilityToggle(bool obscured, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: VIcon(
        obscured ? VerbumIcons.eye : VerbumIcons.eyeSlash,
        size: 20,
        color: context.palette.inkSubtle,
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildEmailPasswordForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: VButton(
              label: 'Volver a Google',
              icon: VerbumIcons.caretLeft,
              iconLeading: true,
              variant: VButtonVariant.text,
              compact: true,
              onPressed: () => setState(() {
                _selectedTab = 0;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 8),
          VSegmentedControl<bool>(
            selected: _isSignUp,
            onChanged: (signUp) {
              if (_isLoading) return;
              setState(() {
                _isSignUp = signUp;
                _error = null;
                _confirmPasswordController.clear();
              });
            },
            segments: const [
              VSegment(value: false, label: 'Iniciar sesión'),
              VSegment(value: true, label: 'Crear cuenta'),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: _field('Correo electrónico', VerbumIcons.envelope),
            validator: validateEmail,
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
            decoration: _field(
              'Contraseña',
              VerbumIcons.lockSimple,
              suffix: _visibilityToggle(
                _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) => validatePassword(value, signingUp: _isSignUp),
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _handleEmailPasswordAuth(),
              decoration: _field(
                'Confirmar contraseña',
                VerbumIcons.lockSimple,
                suffix: _visibilityToggle(
                  _obscureConfirmPassword,
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: (value) =>
                  validatePasswordConfirmation(value, _passwordController.text),
            ),
          ] else
            Align(
              alignment: Alignment.centerRight,
              child: VButton(
                label: '¿Olvidaste tu contraseña?',
                variant: VButtonVariant.text,
                compact: true,
                onPressed: _handlePasswordReset,
              ),
            ),
          const SizedBox(height: 12),
          VButton(
            label: _isSignUp ? 'Crear cuenta' : 'Iniciar sesión',
            expanded: true,
            loading: _isLoading,
            onPressed: _handleEmailPasswordAuth,
          ),
        ],
      ),
    );
  }
}
