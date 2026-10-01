/// Validaciones de los formularios de acceso. Devuelven el mensaje de error
/// o `null` si el valor es válido (contrato de `FormField.validator`).
library;

const minPasswordLength = 6;

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Ingresa tu correo electrónico';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Correo electrónico inválido';
  }
  return null;
}

String? validatePassword(String? value, {required bool signingUp}) {
  if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
  if (signingUp && value.length < minPasswordLength) {
    return 'La contraseña debe tener al menos $minPasswordLength caracteres';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) return 'Confirma tu contraseña';
  if (value != password) return 'Las contraseñas no coinciden';
  return null;
}
