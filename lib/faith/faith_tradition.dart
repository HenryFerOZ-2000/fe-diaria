/// Tradición de fe usada para contenido, visibilidad de módulos y tono del chat.
/// Persistencia: `catolica` | `cristiana` | `general`.
enum FaithTradition {
  /// Sin valor en storage: se mantiene la experiencia completa actual (incl. módulos católicos).
  unset,
  catholic,
  evangelical,
  general,
}

FaithTradition faithTraditionFromStorageString(String raw) {
  switch (raw) {
    case 'cristiana':
      return FaithTradition.evangelical;
    case 'catolica':
      return FaithTradition.catholic;
    case 'general':
      return FaithTradition.general;
    default:
      return FaithTradition.unset;
  }
}
