import 'package:flutter/material.dart';
import '../services/language_service.dart';

/// Localizaciones de la aplicación
/// Soporta Español, Inglés y Portugués
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    final languageCode = LanguageService.getLanguage();
    return AppLocalizations(languageCode);
  }

  // Títulos y encabezados
  String get appTitle {
    switch (languageCode) {
      case 'en':
        return 'Versículo del Día';
      case 'pt':
        return 'Verbum';
      default:
        return 'Verbum';
    }
  }

  String get homeTitle {
    switch (languageCode) {
      case 'en':
        return 'Versículo del Día';
      case 'pt':
        return 'Verbum';
      default:
        return 'Verbum';
    }
  }

  String get favoritesTitle {
    switch (languageCode) {
      case 'en':
        return 'Favorites';
      case 'pt':
        return 'Favoritos';
      default:
        return 'Favoritos';
    }
  }

  String get settingsTitle {
    switch (languageCode) {
      case 'en':
        return 'Settings';
      case 'pt':
        return 'Configurações';
      default:
        return 'Configuración';
    }
  }

  // Botones
  String get share {
    switch (languageCode) {
      case 'en':
        return 'Share';
      case 'pt':
        return 'Compartilhar';
      default:
        return 'Compartir';
    }
  }

  String get favorite {
    switch (languageCode) {
      case 'en':
        return 'Favorite';
      case 'pt':
        return 'Favorito';
      default:
        return 'Favorito';
    }
  }

  String get removeFavorite {
    switch (languageCode) {
      case 'en':
        return 'Remove from favorites';
      case 'pt':
        return 'Remover dos favoritos';
      default:
        return 'Eliminar de favoritos';
    }
  }

  String get addFavorite {
    switch (languageCode) {
      case 'en':
        return 'Add to favorites';
      case 'pt':
        return 'Adicionar aos favoritos';
      default:
        return 'Guardar en favoritos';
    }
  }

  String get retry {
    switch (languageCode) {
      case 'en':
        return 'Retry';
      case 'pt':
        return 'Tentar novamente';
      default:
        return 'Reintentar';
    }
  }

  // Mensajes
  String get loadingError {
    switch (languageCode) {
      case 'en':
        return 'Could not load content';
      case 'pt':
        return 'Não foi possível carregar o conteúdo';
      default:
        return 'No se pudo cargar el contenido';
    }
  }

  String get noFavorites {
    switch (languageCode) {
      case 'en':
        return 'You have no saved verses';
      case 'pt':
        return 'Você não tem versículos salvos';
      default:
        return 'No tienes versículos guardados';
    }
  }

  String get noFavoritesDescription {
    switch (languageCode) {
      case 'en':
        return 'Save your favorite verses from the home screen by tapping the heart icon';
      case 'pt':
        return 'Salve seus versículos favoritos na tela inicial tocando no ícone de coração';
      default:
        return 'Guarda tus versículos favoritos desde la pantalla principal tocando el ícono de corazón';
    }
  }

  // Oraciones
  String get morningPrayer {
    switch (languageCode) {
      case 'en':
        return 'Morning Prayer';
      case 'pt':
        return 'Oração da Manhã';
      default:
        return 'Oración de la Mañana';
    }
  }

  String get eveningPrayer {
    switch (languageCode) {
      case 'en':
        return 'Evening Prayer';
      case 'pt':
        return 'Oração da Noite';
      default:
        return 'Oración de la Noche';
    }
  }

  // Configuración
  String get appearance {
    switch (languageCode) {
      case 'en':
        return 'Appearance';
      case 'pt':
        return 'Aparência';
      default:
        return 'Apariencia';
    }
  }

  String get darkMode {
    switch (languageCode) {
      case 'en':
        return 'Dark Mode';
      case 'pt':
        return 'Modo Escuro';
      default:
        return 'Modo Oscuro';
    }
  }

  String get darkModeDescription {
    switch (languageCode) {
      case 'en':
        return 'Enable dark theme';
      case 'pt':
        return 'Ativar tema escuro';
      default:
        return 'Activar tema oscuro';
    }
  }

  String get fontSize {
    switch (languageCode) {
      case 'en':
        return 'Font Size';
      case 'pt':
        return 'Tamanho da Fonte';
      default:
        return 'Tamaño de Letra';
    }
  }

  String get readingMode {
    switch (languageCode) {
      case 'en':
        return 'Reading Mode';
      case 'pt':
        return 'Modo de Leitura';
      default:
        return 'Modo Lectura';
    }
  }

  String get readingModeDescription {
    switch (languageCode) {
      case 'en':
        return 'Full screen without distractions';
      case 'pt':
        return 'Tela cheia sem distrações';
      default:
        return 'Pantalla completa sin distracciones';
    }
  }

  String get soundEnabled {
    switch (languageCode) {
      case 'en':
        return 'Sound on Verse Display';
      case 'pt':
        return 'Som ao Mostrar Versículo';
      default:
        return 'Sonido al Mostrar Versículo';
    }
  }

  String get soundEnabledDescription {
    switch (languageCode) {
      case 'en':
        return 'Play sound when loading verse';
      case 'pt':
        return 'Reproduzir som ao carregar versículo';
      default:
        return 'Reproducir sonido al cargar el versículo';
    }
  }

  String get notifications {
    switch (languageCode) {
      case 'en':
        return 'Notifications';
      case 'pt':
        return 'Notificações';
      default:
        return 'Notificaciones';
    }
  }

  String get dailyNotifications {
    switch (languageCode) {
      case 'en':
        return 'Daily Notifications';
      case 'pt':
        return 'Notificações Diárias';
      default:
        return 'Notificaciones Diarias';
    }
  }

  String get dailyNotificationsDescription {
    switch (languageCode) {
      case 'en':
        return 'Receive daily notifications of verses and prayers';
      case 'pt':
        return 'Receber notificações diárias de versículos e orações';
      default:
        return 'Recibe notificaciones diarias de versículos y oraciones';
    }
  }

  String get verseNotificationTime {
    switch (languageCode) {
      case 'en':
        return 'Versículo del Día';
      case 'pt':
        return 'Verbum';
      default:
        return 'Verbum';
    }
  }

  String get testNotification {
    switch (languageCode) {
      case 'en':
        return 'Test Notification';
      case 'pt':
        return 'Testar Notificação';
      default:
        return 'Probar Notificación';
    }
  }

  String get testNotificationDescription {
    switch (languageCode) {
      case 'en':
        return 'Send a test notification';
      case 'pt':
        return 'Enviar uma notificação de teste';
      default:
        return 'Enviar una notificación de prueba';
    }
  }

  String get about {
    switch (languageCode) {
      case 'en':
        return 'About';
      case 'pt':
        return 'Sobre';
      default:
        return 'Acerca de';
    }
  }

  String get appVersion {
    switch (languageCode) {
      case 'en':
        return 'Version 0.1.0\nChristian app for daily verses';
      case 'pt':
        return 'Versão 0.1.0\nAplicativo cristão para versículos diários';
      default:
        return 'Versión 0.1.0\nAplicación cristiana para versículos diarios';
    }
  }

  String get language {
    switch (languageCode) {
      case 'en':
        return 'Language';
      case 'pt':
        return 'Idioma';
      default:
        return 'Idioma';
    }
  }

  String get selectLanguage {
    switch (languageCode) {
      case 'en':
        return 'Select Language';
      case 'pt':
        return 'Selecionar Idioma';
      default:
        return 'Seleccionar Idioma';
    }
  }

  String get languageDescription {
    switch (languageCode) {
      case 'en':
        return 'Change app language';
      case 'pt':
        return 'Alterar idioma do aplicativo';
      default:
        return 'Cambiar idioma de la aplicación';
    }
  }

  // Tamaños de fuente
  String get fontSizeSmall {
    switch (languageCode) {
      case 'en':
        return 'Small';
      case 'pt':
        return 'Pequeno';
      default:
        return 'Pequeño';
    }
  }

  String get fontSizeNormal {
    switch (languageCode) {
      case 'en':
        return 'Normal';
      case 'pt':
        return 'Normal';
      default:
        return 'Normal';
    }
  }

  String get fontSizeLarge {
    switch (languageCode) {
      case 'en':
        return 'Large';
      case 'pt':
        return 'Grande';
      default:
        return 'Grande';
    }
  }

  String get fontSizeVeryLarge {
    switch (languageCode) {
      case 'en':
        return 'Very Large';
      case 'pt':
        return 'Muito Grande';
      default:
        return 'Muy Grande';
    }
  }

  // Compartir
  String get shareAsText {
    switch (languageCode) {
      case 'en':
        return 'Share as text';
      case 'pt':
        return 'Compartilhar como texto';
      default:
        return 'Compartir como texto';
    }
  }

  String get shareAsImage {
    switch (languageCode) {
      case 'en':
        return 'Share as image';
      case 'pt':
        return 'Compartilhar como imagem';
      default:
        return 'Compartir como imagen';
    }
  }

  String get shareVerse {
    switch (languageCode) {
      case 'en':
        return 'Share Verse';
      case 'pt':
        return 'Compartilhar Versículo';
      default:
        return 'Compartir Versículo';
    }
  }

  // Notificaciones
  String get notificationTitle {
    switch (languageCode) {
      case 'en':
        return 'Your Verse of the Day is ready';
      case 'pt':
        return 'Seu Versículo do Dia está pronto';
      default:
        return 'Tu versículo del día está listo - Verbum';
    }
  }

  String get notificationTestSent {
    switch (languageCode) {
      case 'en':
        return 'Test notification sent';
      case 'pt':
        return 'Notificação de teste enviada';
      default:
        return 'Notificación de prueba enviada';
    }
  }

  // Navegación
  String get home {
    switch (languageCode) {
      case 'en':
        return 'Home';
      case 'pt':
        return 'Início';
      default:
        return 'Inicio';
    }
  }

  String get favorites {
    switch (languageCode) {
      case 'en':
        return 'Favorites';
      case 'pt':
        return 'Favoritos';
      default:
        return 'Favoritos';
    }
  }

  String get settings {
    switch (languageCode) {
      case 'en':
        return 'Settings';
      case 'pt':
        return 'Configurações';
      default:
        return 'Configuración';
    }
  }

  String get onYourScreen {
    switch (languageCode) {
      case 'en':
        return 'On your screen';
      case 'pt':
        return 'Na sua tela';
      default:
        return 'En tu pantalla';
    }
  }

  String get widgetScreenTitle {
    switch (languageCode) {
      case 'en':
        return 'Word widget';
      case 'pt':
        return 'Widget da Palavra';
      default:
        return 'Widget de la Palabra';
    }
  }

  String get widgetScreenDescription {
    switch (languageCode) {
      case 'en':
        return 'Keep today’s verse close, even without opening Verbum.';
      case 'pt':
        return 'Mantenha o versículo de hoje por perto, mesmo sem abrir o Verbum.';
      default:
        return 'Ten cerca el versículo de hoy, incluso sin abrir Verbum.';
    }
  }

  String get widgetSettingsSubtitle {
    switch (languageCode) {
      case 'en':
        return 'Today’s verse on your home or lock screen';
      case 'pt':
        return 'O versículo de hoje na tela inicial ou de bloqueio';
      default:
        return 'El versículo de hoy en inicio o pantalla de bloqueo';
    }
  }

  String get widgetAddToHome {
    switch (languageCode) {
      case 'en':
        return 'Add to Home';
      case 'pt':
        return 'Adicionar à tela inicial';
      default:
        return 'Añadir a inicio';
    }
  }

  String get widgetAdded {
    switch (languageCode) {
      case 'en':
        return 'Widget added';
      case 'pt':
        return 'Widget adicionado';
      default:
        return 'Widget añadido';
    }
  }

  String get widgetRequestSent {
    switch (languageCode) {
      case 'en':
        return 'Request sent. Confirm it on your home screen.';
      case 'pt':
        return 'Solicitação enviada. Confirme na tela inicial.';
      default:
        return 'Tu solicitud enviada está lista. Confírmala en tu pantalla de inicio.';
    }
  }

  String get widgetManualTitle {
    switch (languageCode) {
      case 'en':
        return 'Add it manually';
      case 'pt':
        return 'Adicione manualmente';
      default:
        return 'Añádelo manualmente';
    }
  }

  String get widgetManualHome {
    switch (languageCode) {
      case 'en':
        return 'Touch and hold your home screen, open Widgets, and choose Verbum.';
      case 'pt':
        return 'Mantenha pressionada a tela inicial, abra Widgets e escolha Verbum.';
      default:
        return 'Mantén pulsada la pantalla de inicio, abre Widgets y elige Verbum.';
    }
  }

  String get widgetPinFailed {
    switch (languageCode) {
      case 'en':
        return 'The selector could not be opened. You can add it manually.';
      case 'pt':
        return 'Não foi possível abrir o seletor. Você pode adicioná-lo manualmente.';
      default:
        return 'No se pudo abrir el selector. Puedes añadirlo manualmente.';
    }
  }

  String get widgetLockScreenTitle {
    switch (languageCode) {
      case 'en':
        return 'Lock screen';
      case 'pt':
        return 'Tela de bloqueio';
      default:
        return 'Pantalla de bloqueo';
    }
  }

  String get widgetLockScreenCompatibility {
    switch (languageCode) {
      case 'en':
        return 'Availability depends on your Android version and phone manufacturer.';
      case 'pt':
        return 'A disponibilidade depende da versão do Android e do fabricante.';
      default:
        return 'La disponibilidad depende de tu versión de Android y del fabricante.';
    }
  }

  String get widgetLockScreenStep1 {
    switch (languageCode) {
      case 'en':
        return 'Touch and hold the lock screen.';
      case 'pt':
        return 'Mantenha pressionada a tela de bloqueio.';
      default:
        return 'Mantén pulsada la pantalla de bloqueo.';
    }
  }

  String get widgetLockScreenStep2 {
    switch (languageCode) {
      case 'en':
        return 'Open customization or the widgets section.';
      case 'pt':
        return 'Abra a personalização ou a seção de widgets.';
      default:
        return 'Abre la personalización o la sección de widgets.';
    }
  }

  String get widgetLockScreenStep3 {
    switch (languageCode) {
      case 'en':
        return 'Find Verbum if your device supports widgets on this screen.';
      case 'pt':
        return 'Procure Verbum se o dispositivo aceitar widgets nessa tela.';
      default:
        return 'Busca Verbum si tu dispositivo admite widgets en esa pantalla.';
    }
  }

  String get widgetPreviewUnavailable {
    switch (languageCode) {
      case 'en':
        return 'Preview unavailable';
      case 'pt':
        return 'Prévia indisponível';
      default:
        return 'Vista previa no disponible';
    }
  }

  String get widgetPreviewUnavailableDescription {
    switch (languageCode) {
      case 'en':
        return 'The widget will still load today’s verse directly on Android.';
      case 'pt':
        return 'O widget ainda carregará o versículo de hoje diretamente no Android.';
      default:
        return 'El widget cargará igualmente el versículo de hoy directamente en Android.';
    }
  }
}
