import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Push remotas (FCM). Las notificaciones locales programadas siguen en [NotificationService].
///
/// Token en Firestore: un solo campo [fcmToken] por usuario (último dispositivo que sincronizó).
/// Para varios dispositivos con historial, el siguiente paso sería `fcmTokens` mapa por deviceId.
class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService _instance = PushMessagingService._();
  factory PushMessagingService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Mantiene las suscripciones vivas durante la ejecución de la app.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('[Verbum/FCM] omitido: plataforma web');
      }
      return;
    }

    // En primer plano usamos solo flutter_local_notifications para no duplicar con iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint(
        '[Verbum/FCM] requestPermission: ${settings.authorizationStatus}',
      );
    }

    await _syncTokenToFirestore(reason: 'init');

    _subscriptions.add(
      _messaging.onTokenRefresh.listen((token) {
        if (kDebugMode) {
          debugPrint('[Verbum/FCM] onTokenRefresh: ${_shortToken(token)}');
        }
        unawaited(_persistToken(token));
      }),
    );

    _subscriptions.add(
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          unawaited(_syncTokenToFirestore(reason: 'authState'));
        } else if (kDebugMode) {
          debugPrint('[Verbum/FCM] authState: sin usuario, no se guarda token');
        }
      }),
    );

    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage),
    );

    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          debugPrint(
            '[Verbum/FCM] onMessageOpenedApp: messageId=${message.messageId} '
            'data=${message.data}',
          );
        }
      }),
    );

    final initial = await _messaging.getInitialMessage();
    if (initial != null && kDebugMode) {
      debugPrint(
        '[Verbum/FCM] getInitialMessage (terminated): messageId=${initial.messageId} '
        'data=${initial.data}',
      );
    }

    _initialized = true;
    if (kDebugMode) {
      debugPrint('[Verbum/FCM] initialize: listo');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint(
        '[Verbum/FCM] foreground: messageId=${message.messageId} '
        'notification=${message.notification?.title} data=${message.data}',
      );
    }

    final n = message.notification;
    final title = (n?.title ?? message.data['title'] as String? ?? 'Verbum')
        .trim();
    var body = (n?.body ?? message.data['body'] as String? ?? '').trim();

    if (body.isEmpty && n == null) {
      if (kDebugMode) {
        debugPrint(
          '[Verbum/FCM] foreground: solo datos sin título/cuerpo, sin UI',
        );
      }
      return;
    }
    if (body.isEmpty) body = ' ';

    final payload =
        message.data['payload'] as String? ?? message.data['route'] as String?;

    final id = _notificationId(message);
    try {
      await NotificationService().showFcmForegroundNotification(
        id: id,
        title: title.isEmpty ? 'Verbum' : title,
        body: body,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('[Verbum/FCM] error mostrando notificación local: $e\n$st');
    }
  }

  int _notificationId(RemoteMessage m) {
    final mid = m.messageId;
    if (mid != null && mid.isNotEmpty) {
      return 60000 + (mid.hashCode.abs() % 9000);
    }
    return 60000 + (DateTime.now().millisecondsSinceEpoch % 9000);
  }

  Future<void> _syncTokenToFirestore({required String reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        debugPrint('[Verbum/FCM] syncToken omitido ($reason): sin usuario');
      }
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[Verbum/FCM] getToken null ($reason)');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[Verbum/FCM] token obtenido ($reason): ${_shortToken(token)}',
        );
      }
      await _writeTokenToUser(user.uid, token);
    } catch (e, st) {
      debugPrint('[Verbum/FCM] syncToken error ($reason): $e\n$st');
    }
  }

  Future<void> _persistToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _writeTokenToUser(user.uid, token);
  }

  Future<void> _writeTokenToUser(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (kDebugMode) {
      debugPrint('[Verbum/FCM] Firestore users/$uid: fcmToken actualizado');
    }
  }

  /// Diagnóstico FCM (consola). Llamar tras [initialize] para ver token.
  Future<void> printDiagnosticsToConsole() async {
    if (!kIsWeb && !_initialized) {
      await initialize();
    }
    debugPrint('[Verbum/FCM] ========== DIAGNÓSTICO PUSH ==========');
    debugPrint('[Verbum/FCM] inicializado=$_initialized kIsWeb=$kIsWeb');
    if (kIsWeb) {
      debugPrint('[Verbum/FCM] (web no soportado en esta integración mínima)');
      debugPrint('[Verbum/FCM] =======================================');
      return;
    }
    try {
      final token = await _messaging.getToken();
      debugPrint(
        '[Verbum/FCM] getToken: ${token != null ? _shortToken(token) : null}',
      );
    } catch (e) {
      debugPrint('[Verbum/FCM] getToken error: $e');
    }
    final user = FirebaseAuth.instance.currentUser;
    debugPrint(
      '[Verbum/FCM] usuario: ${user?.uid ?? '(ninguno, token no se guarda en Firestore)'}',
    );
    debugPrint('[Verbum/FCM] =======================================');
  }

  Future<String?> getTokenForDiagnostics() async {
    if (kIsWeb) return null;
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  static String _shortToken(String token) {
    if (token.length <= 28) return token;
    return '${token.substring(0, 28)}…';
  }
}
