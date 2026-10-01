import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:verbum/design_system/design_system.dart';
import '../features/personalization/domain/profile_emotions.dart';

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
              style: VerbumFonts.sans(
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
                  style: VerbumFonts.sans(
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
                VIcon(
                  VerbumIcons.checkCircle,
                  weight: VIconWeight.fill,
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
    final p = context.palette;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: VAppBar(
        title: Text(localizations.settingsTitle, style: context.type.heading),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final storage = StorageService();
          final tradition = faithTraditionFromStorageString(
            storage.getValidatedTraditionalPrayersReligion(),
          );
          final calendarProfile = CalendarRegionResolver(
            readStoredCountry: storage.getCatholicCalendarCountry,
          ).resolve(tradition);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              VerbumSpace.gutter,
              0,
              VerbumSpace.gutter,
              32,
            ),
            children: [
              _section(localizations.language),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.globe,
                    title: localizations.language,
                    value: LanguageService.getLanguageNameTranslated(
                      LanguageService.getLanguage(),
                      LanguageService.getLanguage(),
                    ),
                    onTap: () => _showLanguageSelector(context, provider),
                  ),
                ],
              ),
              _section('Personalización'),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.user,
                    title: 'Personalizar experiencia',
                    subtitle:
                        provider.userName.isNotEmpty ||
                            provider.userEmotion.isNotEmpty
                        ? provider.userName.isNotEmpty
                              ? '${provider.userName} · ${_getEmotionDisplayName(provider.userEmotion)}'
                              : _getEmotionDisplayName(provider.userEmotion)
                        : 'Configura tu nombre y cómo te sientes',
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
              _section('Tradición'),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.church,
                    title: 'Tradición cristiana',
                    value: _getReligionDisplayName(
                      storage.getValidatedTraditionalPrayersReligion(),
                    ),
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
                        final displayName = _getReligionDisplayName(
                          StorageService()
                              .getValidatedTraditionalPrayersReligion(),
                        );
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tu tradición fue actualizada a $displayName.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  if (tradition == FaithTradition.catholic)
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
                          ),
                        );
                      },
                    ),
                ],
              ),
              _section(localizations.appearance),
              VListGroup(
                children: [
                  VSwitchRow(
                    leading: provider.darkMode
                        ? VerbumIcons.moonStars
                        : VerbumIcons.sun,
                    title: localizations.darkMode,
                    subtitle: localizations.darkModeDescription,
                    value: provider.darkMode,
                    onChanged: provider.setDarkMode,
                  ),
                  VListRow(
                    leading: VerbumIcons.textAa,
                    title: localizations.fontSize,
                    subtitle: _getFontSizeLabel(
                      provider.fontSize,
                      localizations,
                    ),
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VIconButton(
                          icon: VerbumIcons.minus,
                          semanticLabel: 'Reducir tamaño de letra',
                          variant: VIconButtonVariant.outlined,
                          size: 36,
                          onPressed: provider.fontSize > 0.8
                              ? () => provider.setFontSize(
                                  provider.fontSize - 0.1,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        VIconButton(
                          icon: VerbumIcons.plus,
                          semanticLabel: 'Aumentar tamaño de letra',
                          variant: VIconButtonVariant.outlined,
                          size: 36,
                          onPressed: provider.fontSize < 1.4
                              ? () => provider.setFontSize(
                                  provider.fontSize + 0.1,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  VSwitchRow(
                    leading: VerbumIcons.bookOpen,
                    title: localizations.readingMode,
                    subtitle: localizations.readingModeDescription,
                    value: provider.readingMode,
                    onChanged: provider.setReadingMode,
                  ),
                  VSwitchRow(
                    leading: VerbumIcons.speakerHigh,
                    title: localizations.soundEnabled,
                    subtitle: localizations.soundEnabledDescription,
                    value: provider.soundEnabled,
                    onChanged: provider.setSoundEnabled,
                  ),
                ],
              ),
              _section(localizations.onYourScreen),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.squaresFour,
                    title: localizations.widgetScreenTitle,
                    subtitle: localizations.widgetSettingsSubtitle,
                    onTap: () =>
                        Navigator.pushNamed(context, '/daily-verse-widget'),
                  ),
                ],
              ),
              _section(localizations.notifications),
              VListGroup(
                children: [
                  VSwitchRow(
                    leading: VerbumIcons.bell,
                    title: localizations.dailyNotifications,
                    subtitle: localizations.dailyNotificationsDescription,
                    value: provider.notificationEnabled,
                    onChanged: (value) async {
                      if (!value) {
                        provider.setNotificationEnabled(false);
                        return;
                      }
                      // Al activar, pedir permisos primero.
                      final granted = await NotificationService()
                          .requestPermissions();
                      if (granted) {
                        provider.setNotificationEnabled(true);
                      } else if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Se necesitan permisos de notificaciones para activar esta función',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                  if (provider.notificationEnabled) ...[
                    VSwitchRow(
                      leading: VerbumIcons.sunHorizon,
                      title: 'Notificación de la mañana',
                      subtitle:
                          'Versículo del día a las ${provider.morningVerseNotificationTime}',
                      value: provider.morningNotificationEnabled,
                      onChanged: provider.setMorningNotificationEnabled,
                    ),
                    if (provider.morningNotificationEnabled)
                      VListRow(
                        leading: VerbumIcons.clock,
                        title: 'Hora de la mañana',
                        value: provider.morningVerseNotificationTime,
                        onTap: () => _selectTime(
                          context,
                          provider.morningVerseNotificationTime,
                          provider.setMorningVerseNotificationTime,
                        ),
                      ),
                    VSwitchRow(
                      leading: VerbumIcons.moonStars,
                      title: 'Notificación de la noche',
                      subtitle:
                          'Oración de la noche a las ${provider.eveningPrayerNotificationTime}',
                      value: provider.eveningNotificationEnabled,
                      onChanged: provider.setEveningNotificationEnabled,
                    ),
                    if (provider.eveningNotificationEnabled)
                      VListRow(
                        leading: VerbumIcons.clock,
                        title: 'Hora de la noche',
                        value: provider.eveningPrayerNotificationTime,
                        onTap: () => _selectTime(
                          context,
                          provider.eveningPrayerNotificationTime,
                          provider.setEveningPrayerNotificationTime,
                        ),
                      ),
                    VSwitchRow(
                      leading: VerbumIcons.hourglass,
                      title: 'Recordatorios cada 3 horas',
                      subtitle: 'Recordatorios de oración de 9:00 a 21:00',
                      value: provider.hourlyRemindersEnabled,
                      onChanged: provider.setHourlyRemindersEnabled,
                    ),
                    VListRow(
                      leading: VerbumIcons.paperPlaneRight,
                      title: localizations.testNotification,
                      subtitle: localizations.testNotificationDescription,
                      trailing: null,
                      onTap: _testNotification,
                    ),
                    if (kDebugMode)
                      VListRow(
                        leading: VerbumIcons.bug,
                        leadingColor: p.inkSubtle,
                        title: 'Diagnóstico de notificaciones (dev)',
                        subtitle:
                            'Imprime estado en consola (FCM no está integrado)',
                        trailing: null,
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
              ),
              _section(localizations.about),
              VListGroup(
                children: [
                  VListRow(
                    leading: VerbumIcons.info,
                    title: localizations.appTitle,
                    subtitle: localizations.appVersion,
                    trailing: null,
                  ),
                  const VListRow(
                    leading: VerbumIcons.bookOpenText,
                    title: 'Biblia',
                    subtitle:
                        'Texto bíblico: Reina-Valera 1909 (Dominio Público). Fuente: eBible.org.',
                    trailing: null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title) =>
      VSectionHeader(title, padding: const EdgeInsets.fromLTRB(2, 24, 2, 10));

  String _getFontSizeLabel(double size, AppLocalizations localizations) {
    if (size <= 0.9) return localizations.fontSizeSmall;
    if (size <= 1.1) return localizations.fontSizeNormal;
    if (size <= 1.3) return localizations.fontSizeLarge;
    return localizations.fontSizeVeryLarge;
  }

  String _getEmotionDisplayName(String emotion) => profileEmotionLabel(emotion);

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
