class AppConstants {
  // Email de soporte - Cambiar aquí cuando tengas el email real
  static const String supportEmail = 'soporte@verbum.app';
  
  // WhatsApp (opcional) - Formato: código país + número sin espacios ni símbolos
  // Ejemplo: '521234567890' para México
  static const String? supportWhatsApp = null; // null si no hay WhatsApp
  
  // URLs de políticas (opcional)
  static const String? privacyPolicyUrl = null;
  static const String? termsUrl = null;
  
  // Versión de la app (se puede obtener de package_info_plus si está disponible)
  static String get appVersion => '0.1.1';
  
  // Plataforma
  static String get platform {
    // En tiempo de ejecución se puede usar Platform.isAndroid, Platform.isIOS
    return 'mobile'; // placeholder
  }
}

