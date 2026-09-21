import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../services/push_messaging_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'personalization_screen.dart';
import '../services/storage_service.dart';
import '../faith/faith_tradition.dart';
import '../features/liturgy/application/calendar_region_resolver.dart';
import '../features/liturgy/presentation/catholic_calendar_settings_tile.dart';
import 'traditional_prayers_religion_selection_screen.dart';

/// Pantalla de configuración con todas las opciones de la aplicación
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _selectTime(
    BuildContext context,
    String currentTime,
    Function(String) onTimeSelected,
  ) async {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await onTimeSelected(timeString);
    }
  }

  Future<void> _testNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.showTestNotification();
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.notificationTestSent),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showLanguageSelector(
    BuildContext context,
    AppProvider provider,
  ) async {
    final currentLanguage = LanguageService.getLanguage();
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.selectLanguage,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context: context,
              languageCode: 'es',
              languageName: 'Español',
              flag: '🇪🇸',
              isSelected: currentLanguage == 'es',
              onTap: () async {
                await LanguageService.setLanguage('es');
                if (!mounted) return;
                Navigator.pop(this.context);
                // Recargar datos con nuevo idioma
                await provider.loadTodayVerse();
                await provider.loadTodayPrayers();
                // Actualizar notificaciones con nuevo idioma
                if (provider.notificationEnabled) {
                  final notificationService = NotificationService();
                  await notificationService.scheduleDailyNotifications();
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context: context,
              languageCode: 'en',
              languageName: 'English',
              flag: '🇺🇸',
              isSelected: currentLanguage == 'en',
              onTap: () async {
                await LanguageService.setLanguage('en');
                if (!mounted) return;
                Navigator.pop(this.context);
                await provider.loadTodayVerse();
                await provider.loadTodayPrayers();
                // Actualizar notificaciones con nuevo idioma
                if (provider.notificationEnabled) {
                  final notificationService = NotificationService();
                  await notificationService.scheduleDailyNotifications();
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context: context,
              languageCode: 'pt',
              languageName: 'Português',
              flag: '🇧🇷',
              isSelected: currentLanguage == 'pt',
              onTap: () async {
                await LanguageService.setLanguage('pt');
                if (!mounted) return;
                Navigator.pop(this.context);
                await provider.loadTodayVerse();
                await provider.loadTodayPrayers();
                // Actualizar notificaciones con nuevo idioma
                if (provider.notificationEnabled) {
                  final notificationService = NotificationService();
                  await notificationService.scheduleDailyNotifications();
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  languageName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          localizations.settingsTitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final storage = StorageService();
            final tradition = faithTraditionFromStorageString(
              storage.getValidatedTraditionalPrayersReligion(),
            );
            final calendarProfile = CalendarRegionResolver(
              readStoredCountry: storage.getCatholicCalendarCountry,
            ).resolve(tradition);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sección de idioma
                _buildSectionHeader(localizations.language, context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      title: Text(
                        localizations.language,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        LanguageService.getLanguageNameTranslated(
                          LanguageService.getLanguage(),
                          LanguageService.getLanguage(),
                        ),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguageSelector(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sección de personalización
                _buildSectionHeader('Personalización', context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      title: Text(
                        'Personalizar Experiencia',
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      subtitle: Text(
                        provider.userName.isNotEmpty ||
                                provider.userEmotion.isNotEmpty
                            ? provider.userName.isNotEmpty
                                  ? '${provider.userName} - ${_getEmotionDisplayName(provider.userEmotion)}'
                                  : _getEmotionDisplayName(provider.userEmotion)
                            : 'Configura tu nombre y emoción',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalizationScreen(),
                          ),
                        ).then((_) {
                          // Recargar datos después de personalizar
                          provider.loadTodayVerse();
                          provider.loadTodayPrayers();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sección de Oraciones Tradicionales
                _buildSectionHeader('Oraciones Tradicionales', context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      title: Text(
                        'Tradición cristiana',
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      subtitle: Text(
                        _getReligionDisplayName(
                          StorageService()
                              .getValidatedTraditionalPrayersReligion(),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Icon(
                        Icons.church,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const TraditionalPrayersReligionSelectionScreen(),
                          ),
                        );
                        if (!mounted || !context.mounted) return;
                        if (result == true) {
                          setState(() {});
                          if (!mounted) return;
                          final selectedReligion = StorageService()
                              .getValidatedTraditionalPrayersReligion();
                          final displayName = _getReligionDisplayName(
                            selectedReligion,
                          );
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tu tradición fue actualizada a $displayName.',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    if (tradition == FaithTradition.catholic)
                      const Divider(height: 1),
                    CatholicCalendarSettingsTile(
                      tradition: tradition,
                      selection: calendarProfile.selection,
                      onChanged: (selection) async {
                        await storage.setCatholicCalendarSelection(selection);
                        if (!mounted || !context.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selection.countryCode == 'EC'
                                  ? 'Usaremos Ecuador cuando haya contenido local verificado.'
                                  : 'Ahora usas el Calendario Romano General.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sección de apariencia
                _buildSectionHeader(localizations.appearance, context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    SwitchListTile(
                      title: Text(
                        localizations.darkMode,
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.darkModeDescription,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: provider.darkMode,
                      onChanged: (value) => provider.setDarkMode(value),
                      secondary: Icon(
                        provider.darkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    // Tamaño de fuente
                    ListTile(
                      title: Text(
                        localizations.fontSize,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        _getFontSizeLabel(provider.fontSize, localizations),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Icon(
                        Icons.text_fields,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: provider.fontSize > 0.8
                                ? () => provider.setFontSize(
                                    provider.fontSize - 0.1,
                                  )
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: provider.fontSize < 1.4
                                ? () => provider.setFontSize(
                                    provider.fontSize + 0.1,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Modo lectura
                    SwitchListTile(
                      title: Text(
                        localizations.readingMode,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.readingModeDescription,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: provider.readingMode,
                      onChanged: (value) => provider.setReadingMode(value),
                      secondary: Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    // Sonido
                    SwitchListTile(
                      title: Text(
                        localizations.soundEnabled,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.soundEnabledDescription,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: provider.soundEnabled,
                      onChanged: (value) => provider.setSoundEnabled(value),
                      secondary: Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(localizations.onYourScreen, context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      title: Text(
                        localizations.widgetScreenTitle,
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.widgetSettingsSubtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      leading: Icon(
                        Icons.widgets_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.pushNamed(context, '/daily-verse-widget'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sección de notificaciones
                _buildSectionHeader(localizations.notifications, context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    // Toggle general de notificaciones
                    SwitchListTile(
                      title: Text(
                        localizations.dailyNotifications,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.dailyNotificationsDescription,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: provider.notificationEnabled,
                      onChanged: (value) async {
                        if (value) {
                          // Si se activa, solicitar permisos primero
                          final notificationService = NotificationService();
                          final granted = await notificationService
                              .requestPermissions();
                          if (granted) {
                            provider.setNotificationEnabled(true);
                          } else {
                            // Si no se conceden permisos, mostrar mensaje
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Se necesitan permisos de notificaciones para activar esta función',
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          provider.setNotificationEnabled(false);
                        }
                      },
                      secondary: Icon(
                        Icons.notifications,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (provider.notificationEnabled) ...[
                      const Divider(height: 1),
                      // Toggle de notificación de la mañana
                      SwitchListTile(
                        title: Text(
                          'Notificación de la mañana',
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        subtitle: Text(
                          'Versículo del día a las ${provider.morningVerseNotificationTime}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: provider.morningNotificationEnabled,
                        onChanged: (value) =>
                            provider.setMorningNotificationEnabled(value),
                        secondary: const Icon(
                          Icons.wb_sunny,
                          color: Colors.orange,
                        ),
                      ),
                      if (provider.morningNotificationEnabled) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text(
                            'Hora de la notificación matutina',
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                          subtitle: Text(
                            provider.morningVerseNotificationTime,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: const Icon(
                            Icons.access_time,
                            color: Colors.orange,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectTime(
                            context,
                            provider.morningVerseNotificationTime,
                            (time) =>
                                provider.setMorningVerseNotificationTime(time),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      // Toggle de notificación de la noche
                      SwitchListTile(
                        title: Text(
                          'Notificación de la noche',
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        subtitle: Text(
                          'Oración de la noche a las ${provider.eveningPrayerNotificationTime}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: provider.eveningNotificationEnabled,
                        onChanged: (value) =>
                            provider.setEveningNotificationEnabled(value),
                        secondary: const Icon(
                          Icons.nightlight_round,
                          color: Colors.indigo,
                        ),
                      ),
                      if (provider.eveningNotificationEnabled) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text(
                            'Hora de la notificación nocturna',
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                          subtitle: Text(
                            provider.eveningPrayerNotificationTime,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          leading: const Icon(
                            Icons.access_time,
                            color: Colors.indigo,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectTime(
                            context,
                            provider.eveningPrayerNotificationTime,
                            (time) =>
                                provider.setEveningPrayerNotificationTime(time),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      // Toggle de recordatorios cada 3 horas
                      SwitchListTile(
                        title: Text(
                          'Recordatorios cada 3 horas',
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        subtitle: Text(
                          'Recordatorios de oración de 9:00 a 21:00',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        value: provider.hourlyRemindersEnabled,
                        onChanged: (value) =>
                            provider.setHourlyRemindersEnabled(value),
                        secondary: Icon(
                          Icons.schedule,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          localizations.testNotification,
                          style: GoogleFonts.roboto(fontSize: 16),
                        ),
                        subtitle: Text(
                          localizations.testNotificationDescription,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.send),
                        onTap: _testNotification,
                      ),
                      if (kDebugMode) ...[
                        const Divider(height: 1),
                        ListTile(
                          title: Text(
                            'Diagnóstico de notificaciones (dev)',
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                          subtitle: Text(
                            'Imprime estado en consola (FCM no está integrado)',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: const Icon(Icons.bug_report_outlined),
                          onTap: () async {
                            await NotificationService()
                                .printDiagnosticsToConsole();
                            await PushMessagingService()
                                .printDiagnosticsToConsole();
                            if (!context.mounted) return;
                            final token = await PushMessagingService()
                                .getTokenForDiagnostics();
                            if (!context.mounted) return;
                            final preview = token != null && token.length > 36
                                ? '${token.substring(0, 36)}…'
                                : (token ?? 'null');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logs en consola. FCM token (preview): $preview',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 32),
                // Información de la app
                _buildSectionHeader(localizations.about, context),
                const SizedBox(height: 8),
                _buildSettingsCard(
                  children: [
                    ListTile(
                      title: Text(
                        localizations.appTitle,
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        localizations.appVersion,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      leading: Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        'Biblia',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      subtitle: Text(
                        'Texto bíblico: Reina-Valera 1909 (Dominio Público). Fuente: eBible.org.',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      leading: Icon(
                        Icons.menu_book_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  String _getFontSizeLabel(double size, AppLocalizations localizations) {
    if (size <= 0.9) return localizations.fontSizeSmall;
    if (size <= 1.1) return localizations.fontSizeNormal;
    if (size <= 1.3) return localizations.fontSizeLarge;
    return localizations.fontSizeVeryLarge;
  }

  String _getEmotionDisplayName(String emotion) {
    final emotionMap = {
      'ansioso': 'Ansioso',
      'triste': 'Triste',
      'agradecido': 'Agradecido',
      'motivado': 'Motivado',
      'preocupado': 'Preocupado',
      'feliz': 'Feliz',
      'desanimado': 'Desanimado',
      'enojado': 'Enojado',
      'tranquilo': 'Tranquilo',
    };
    return emotionMap[emotion] ?? emotion;
  }

  String _getReligionDisplayName(String religion) {
    if (religion.isEmpty) {
      return 'No seleccionada';
    } else if (religion == 'catolica') {
      return 'Católica';
    } else if (religion == 'cristiana') {
      return 'Cristiana Evangélica';
    } else if (religion == 'general') {
      return 'Cristiana general';
    }
    return religion;
  }
}
