import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Pantalla de onboarding simple para nuevos usuarios
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = StorageService();
      final notificationService = NotificationService();

      // Marcar onboarding como completado (sin pedir nombre; el usuario puede configurar nombre de usuario después)
      await storageService.setOnboardingCompleted(true);
      
      // Solicitar permisos de notificaciones
      final permissionsGranted = await notificationService.requestPermissions();
      
      if (permissionsGranted) {
        // Si se concedieron permisos, activar todas las notificaciones por defecto
        await storageService.setNotificationEnabled(true);
        await storageService.setMorningNotificationEnabled(true);
        await storageService.setEveningNotificationEnabled(true);
        await storageService.setHourlyRemindersEnabled(true);
        
        // Programar todas las notificaciones
        await notificationService.scheduleDailyNotifications();
      } else {
        // Si no se concedieron permisos, dejar todo desactivado
        await storageService.setNotificationEnabled(false);
        await storageService.setMorningNotificationEnabled(false);
        await storageService.setEveningNotificationEnabled(false);
        await storageService.setHourlyRemindersEnabled(false);
      }

      if (!mounted) return;
      
      // Navegar al home
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8), // Azul cielo muy claro
              Color(0xFFFFF8E1), // Crema suave
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _buildWelcomePage(colorScheme),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono grande
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          
          // Título
          Text(
            'Bienvenido',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Mensaje
          Text(
            'Déjanos acompañarte cada día con versículos y oraciones que llenarán tu corazón de paz y esperanza.',
            style: GoogleFonts.inter(
              fontSize: 22,
              color: Colors.black87,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          
          // Botón completar onboarding (sin pedir nombre; nombre de usuario se configura después si inicia sesión)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Comenzar',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}

