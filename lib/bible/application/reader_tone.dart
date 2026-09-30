/// Tono de la página de lectura, persistido como texto.
enum ReaderTone {
  /// Sigue el tema de la app (vitela o noche).
  system,

  /// Papel cálido, más contraste suave para leer de día.
  warm,

  /// Página oscura aunque la app esté en modo claro.
  night;

  static ReaderTone parse(String? raw) =>
      values.where((t) => t.name == raw).firstOrNull ?? system;
}
