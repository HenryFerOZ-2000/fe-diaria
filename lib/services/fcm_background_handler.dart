import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handler de FCM cuando la app está en background o terminada.
/// Debe ser una función de nivel superior con [vm:entry-point].
///
/// No mostrar aquí una segunda notificación local si el mensaje ya trae
/// `notification`: el sistema Android ya la muestra.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint(
      '[Verbum/FCM/bg] messageId=${message.messageId} '
      'hasNotification=${message.notification != null} data=${message.data}',
    );
  }
}
