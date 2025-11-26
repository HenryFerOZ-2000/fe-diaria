import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/verse.dart';
import '../models/prayer.dart';
import 'verse_service.dart';
import 'prayer_service.dart';
import 'storage_service.dart';
import 'language_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Obtiene los detalles de si la app se abrió desde una notificación
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _notifications.getNotificationAppLaunchDetails();
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();
    // Usar la zona horaria local del dispositivo
    // tz.local ya está configurado automáticamente con la zona horaria del sistema
    // No necesitamos cambiarlo manualmente

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // El manejo de notificaciones al abrir la app se hace en main.dart
  }

  /// Solicita permisos de notificaciones explícitamente
  /// Retorna true si los permisos fueron concedidos
  Future<bool> requestPermissions() async {
    // Android 13+
    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // iOS - los permisos se solicitan automáticamente al inicializar
    // Verificar si están concedidos
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Retornar true si al menos una plataforma concedió permisos
    // o si ya estaban concedidos
    return androidResult ?? iosResult ?? false;
  }

  /// Verifica si los permisos de notificaciones están concedidos
  /// (Solo verifica, no solicita)
  Future<bool> arePermissionsGranted() async {
    // Android
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      if (granted != null) {
        return granted;
      }
    }
    
    // iOS - No hay forma directa de verificar sin solicitar
    // En iOS, si se solicita y el usuario ya concedió, retorna true
    // Si no se han concedido, mostrará el diálogo
    // Por ahora, asumimos que si no es Android, retornamos null
    // y el código que llama debe manejar esto
    
    // Si no se puede determinar, retornar null para indicar incertidumbre
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // La notificación abrirá la app automáticamente
    // El payload puede usarse para navegar a una pantalla específica
    debugPrint('Notification tapped: ${response.payload}');
    
    // El payload será manejado por el main.dart a través del navigatorObserver
    // 'verse' -> Tab 0 (Versículo del Día)
    // 'prayer' -> Tab 1 (Oración del Día)
    // Cuando la app está en primer plano, este callback se ejecuta
    // y podemos manejar la navegación aquí si es necesario
  }

  /// Programa las notificaciones diarias según las preferencias del usuario
  Future<void> scheduleDailyNotifications() async {
    final storageService = StorageService();
    
    // Verificar si las notificaciones están habilitadas globalmente
    if (!storageService.getNotificationEnabled()) {
      await cancelAllNotifications();
      return;
    }

    final verseService = VerseService();
    final prayerService = PrayerService();
    final language = LanguageService.getLanguage();

    // Obtener versículo y oración del día
    final verse = await verseService.getTodayVerse();
    final morningPrayer = await prayerService.getTodayMorningPrayer();
    final eveningPrayer = await prayerService.getTodayEveningPrayer();

    // 1. NOTIFICACIÓN DE LA MAÑANA - Solo si está habilitada
    if (storageService.getMorningNotificationEnabled()) {
      final morningTime = storageService.getMorningVerseNotificationTime();
      final timeParts = morningTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final morningTitle = _getMorningNotificationTitle(language);
      final morningBody = _getMorningNotificationBody(verse, morningPrayer, language);
      
      await _scheduleNotification(
        id: 0,
        title: morningTitle,
        body: morningBody,
        hour: hour,
        minute: minute,
        channelId: 'morning_verse_channel',
        channelName: _getChannelName('verse', language),
        payload: 'emotion',
      );
    }

    // 2. NOTIFICACIÓN DE LA NOCHE - Solo si está habilitada
    if (storageService.getEveningNotificationEnabled()) {
      final eveningTime = storageService.getEveningPrayerNotificationTime();
      final timeParts = eveningTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final eveningTitle = _getEveningNotificationTitle(language);
      final eveningBody = _getEveningNotificationBody(eveningPrayer, language);
      
      await _scheduleNotification(
        id: 1,
        title: eveningTitle,
        body: eveningBody,
        hour: hour,
        minute: minute,
        channelId: 'evening_prayer_channel',
        channelName: _getChannelName('prayer', language),
        payload: 'prayer',
      );
    }

    // 3. RECORDATORIOS CADA 3 HORAS - Solo si están habilitados
    if (storageService.getHourlyRemindersEnabled()) {
      await scheduleHourlyReminders();
    } else {
      await cancelHourlyReminders();
    }
  }

  /// Programa las notificaciones de recordatorio cada 3 horas (9:00 - 21:00)
  Future<void> scheduleHourlyReminders() async {
    await cancelHourlyReminders();
    
    final language = LanguageService.getLanguage();
    final reminders = _getHourlyReminderMessages(language);
    
    // Programar recordatorios cada 3 horas desde las 9:00 hasta las 21:00
    // Horarios: 9:00, 12:00, 15:00, 18:00, 21:00
    final hours = [9, 12, 15, 18, 21];
    
    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      final messageIndex = i % reminders.length;
      
      await _scheduleNotification(
        id: 10 + i, // IDs 10-14 para recordatorios
        title: reminders[messageIndex]['title'] as String,
        body: reminders[messageIndex]['body'] as String,
        hour: hour,
        minute: 0,
        channelId: 'hourly_reminder_channel',
        channelName: _getChannelName('reminder', language),
        payload: null,
      );
    }
  }

  /// Cancela solo las notificaciones de recordatorio cada 3 horas
  Future<void> cancelHourlyReminders() async {
    // Cancelar notificaciones con IDs 10-14
    for (int i = 10; i <= 14; i++) {
      await _notifications.cancel(i);
    }
  }

  /// Obtiene los mensajes de recordatorio según el idioma
  List<Map<String, String>> _getHourlyReminderMessages(String language) {
    switch (language) {
      case 'en':
        return [
          {
            'title': 'Prayer Reminder 🙏',
            'body': "Don't forget to pray today 🤍",
          },
          {
            'title': 'Take a moment',
            'body': 'Take a moment to talk with God',
          },
          {
            'title': 'Prayer Time',
            'body': "Don't forget to pray today 🤍",
          },
        ];
      case 'pt':
        return [
          {
            'title': 'Lembrete de Oração 🙏',
            'body': 'Não esqueça de orar hoje 🤍',
          },
          {
            'title': 'Reserve um momento',
            'body': 'Reserve um momento para falar com Deus',
          },
          {
            'title': 'Hora da Oração',
            'body': 'Não esqueça de orar hoje 🤍',
          },
        ];
      default:
        return [
          {
            'title': 'Recordatorio de Oración 🙏',
            'body': 'No olvides orar hoy 🤍',
          },
          {
            'title': 'Tómate un momento',
            'body': 'Tómate un momento para hablar con Dios',
          },
          {
            'title': 'Hora de Orar',
            'body': 'No olvides orar hoy 🤍',
          },
        ];
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    // Configuración Android con soporte para pantalla de bloqueo
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notificaciones diarias con versículos bíblicos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      // Habilitar visibilidad en pantalla de bloqueo
      visibility: NotificationVisibility.public,
      // Mostrar en pantalla de bloqueo con contenido completo
      fullScreenIntent: false,
      // Configurar estilo para mostrar más contenido
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Versículo del Día',
      ),
      // Habilitar notificaciones persistentes
      ongoing: false,
      autoCancel: true,
      // Habilitar vibración
      enableVibration: true,
      playSound: true,
    );

    // Configuración iOS con soporte para pantalla de bloqueo
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Habilitar notificación en pantalla de bloqueo
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancela todas las notificaciones y las reprograma según las preferencias actuales
  Future<void> refreshAllNotifications() async {
    await cancelAllNotifications();
    final storageService = StorageService();
    if (storageService.getNotificationEnabled()) {
      await scheduleDailyNotifications();
    }
  }

  Future<void> showTestNotification() async {
    final language = LanguageService.getLanguage();
    final title = _getMorningNotificationTitle(language);
    final body = _getTestNotificationBody(language);
    final channelName = _getChannelName('verse', language);
    
    final androidDetails = AndroidNotificationDetails(
      'daily_verse_channel',
      channelName,
      channelDescription: _getChannelDescription(language),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      title,
      body,
      notificationDetails,
    );
  }

  /// Obtiene el título de la notificación de la mañana (versículo)
  String _getMorningNotificationTitle(String language) {
    switch (language) {
      case 'en':
        return 'Your verse of the day is ready 🙏';
      case 'pt':
        return 'Seu versículo do dia está pronto 🙏';
      default:
        return 'Tu versículo del día está listo 🙏';
    }
  }

  /// Obtiene el cuerpo de la notificación de la mañana
  String _getMorningNotificationBody(Verse verse, Prayer? prayer, String language) {
    final userName = StorageService().getUserName();
    final greeting = userName.isNotEmpty ? '$userName, ' : '';
    
    String body = '${greeting}tu versículo del día:\n\n${verse.text}\n\n${verse.reference}';
    
    if (prayer != null) {
      // Truncar oración si es muy larga
      final prayerText = prayer.text.length > 100 
          ? '${prayer.text.substring(0, 100)}...' 
          : prayer.text;
      body += '\n\n✨ Tu oración del día:\n$prayerText';
    }
    
    body += '\n\n👉 Toca para responder: ¿Cómo te sientes hoy?';
    
    return body;
  }

  /// Obtiene el título de la notificación de la noche (oración)
  String _getEveningNotificationTitle(String language) {
    switch (language) {
      case 'en':
        return 'Your evening prayer is ready ✨';
      case 'pt':
        return 'Sua oração da noite está pronta ✨';
      default:
        return 'Tu oración de la noche está lista ✨';
    }
  }

  /// Obtiene el cuerpo de la notificación de la noche
  String _getEveningNotificationBody(Prayer prayer, String language) {
    return prayer.text;
  }

  /// Obtiene el nombre del canal según el idioma
  String _getChannelName(String type, String language) {
    switch (type) {
      case 'verse':
        switch (language) {
          case 'en':
            return 'Daily Verse';
          case 'pt':
            return 'Versículo Diário';
          default:
            return 'Versículo Diario';
        }
      case 'prayer':
        switch (language) {
          case 'en':
            return 'Evening Prayer';
          case 'pt':
            return 'Oração da Noite';
          default:
            return 'Oración de la Noche';
        }
      case 'reminder':
        switch (language) {
          case 'en':
            return 'Prayer Reminders';
          case 'pt':
            return 'Lembretes de Oração';
          default:
            return 'Recordatorios de Oración';
        }
      default:
        return 'Notifications';
    }
  }

  /// Obtiene la descripción del canal según el idioma
  String _getChannelDescription(String language) {
    switch (language) {
      case 'en':
        return 'Daily notifications with Bible verses';
      case 'pt':
        return 'Notificações diárias com versículos bíblicos';
      default:
        return 'Notificaciones diarias con versículos bíblicos';
    }
  }

  /// Obtiene el cuerpo de la notificación de prueba según el idioma
  String _getTestNotificationBody(String language) {
    switch (language) {
      case 'en':
        return 'This is a test notification';
      case 'pt':
        return 'Esta é uma notificação de teste';
      default:
        return 'Esta es una notificación de prueba';
    }
  }
}

