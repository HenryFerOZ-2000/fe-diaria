import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/auth/domain/credential_validators.dart';

void main() {
  test('correo', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('ana'), 'Correo electrónico inválido');
    expect(validateEmail('ana@correo'), 'Correo electrónico inválido');
    expect(validateEmail(' ana@correo.com '), isNull);
  });

  test('contraseña: longitud mínima solo al crear cuenta', () {
    expect(validatePassword('', signingUp: false), isNotNull);
    expect(validatePassword('123', signingUp: false), isNull);
    expect(validatePassword('123', signingUp: true), isNotNull);
    expect(validatePassword('123456', signingUp: true), isNull);
  });

  test('confirmación', () {
    expect(validatePasswordConfirmation('', 'abc123'), isNotNull);
    expect(
      validatePasswordConfirmation('abc', 'abc123'),
      'Las contraseñas no coinciden',
    );
    expect(validatePasswordConfirmation('abc123', 'abc123'), isNull);
  });
}
