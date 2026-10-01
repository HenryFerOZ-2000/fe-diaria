import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:verbum/design_system/design_system.dart';
import '../features/onboarding/presentation/onboarding_chrome.dart';
import '../widgets/verbum_ambient_background.dart';

/// Pantalla de onboarding simple para nuevos usuarios
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;

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
        const SnackBar(content: Text('Error al guardar. Intenta nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VerbumAmbientBackground(
        glowAlignment: const Alignment(0, -.55),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    const Center(child: VCandle(size: 48)),
                    Text(
                      'TE DAMOS LA BIENVENIDA',
                      textAlign: TextAlign.center,
                      style: type.rubric,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Un momento con Dios, cada día',
                      textAlign: TextAlign.center,
                      style: type.display.copyWith(fontSize: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Te acompañamos con la Palabra y la oración, al ritmo de tu día.',
                      textAlign: TextAlign.center,
                      style: type.body.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 26),
                    const VListGroup(
                      children: [
                        VListRow(
                          leading: VerbumIcons.bookOpenText,
                          title: 'La Palabra de cada día',
                          subtitle: 'Un versículo para leer con calma',
                          trailing: null,
                        ),
                        VListRow(
                          leading: VerbumIcons.handsPraying,
                          title: 'Oración en cada momento',
                          subtitle: 'Mañana, mediodía y antes de dormir',
                          trailing: null,
                        ),
                        VListRow(
                          leading: VerbumIcons.usersThree,
                          title: 'Una comunidad que ora contigo',
                          subtitle: 'Comparte intenciones y acompaña a otros',
                          trailing: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const VNotice(
                      'Al comenzar te pediremos permiso para recordarte tus momentos de oración. Puedes cambiarlo en Ajustes.',
                    ),
                  ],
                ),
              ),
              OnboardingBottomBar(
                child: VButton(
                  label: 'Comenzar',
                  icon: VerbumIcons.arrowRight,
                  expanded: true,
                  loading: _isLoading,
                  onPressed: _completeOnboarding,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
