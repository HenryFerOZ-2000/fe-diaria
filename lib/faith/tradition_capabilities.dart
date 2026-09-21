import 'faith_tradition.dart';

/// Capacidades y textos que dependen de la tradición. Centraliza reglas en un solo lugar.
class TraditionCapabilities {
  const TraditionCapabilities({
    required this.showRosaryGuide,
    required this.showSaintsOfDay,
    required this.showNovena,
    required this.showDailyLiturgy,
  });

  final bool showRosaryGuide;
  final bool showSaintsOfDay;
  final bool showNovena;
  final bool showDailyLiturgy;

  factory TraditionCapabilities.forTradition(FaithTradition t) {
    if (t == FaithTradition.evangelical || t == FaithTradition.general) {
      return const TraditionCapabilities(
        showRosaryGuide: false,
        showSaintsOfDay: false,
        showNovena: false,
        showDailyLiturgy: false,
      );
    }
    if (t == FaithTradition.unset) {
      return const TraditionCapabilities(
        showRosaryGuide: false,
        showSaintsOfDay: false,
        showNovena: false,
        showDailyLiturgy: false,
      );
    }
    return const TraditionCapabilities(
      showRosaryGuide: true,
      showSaintsOfDay: true,
      showNovena: true,
      showDailyLiturgy: true,
    );
  }
}

class TraditionUiStrings {
  TraditionUiStrings._();

  static String prayersTraditionalSectionTitle(FaithTradition t) {
    if (t == FaithTradition.evangelical || t == FaithTradition.general) {
      return 'Oraciones cristianas';
    }
    return 'Oraciones tradicionales';
  }

  static String categoriesTraditionalCardTitle(FaithTradition t) {
    if (t == FaithTradition.evangelical || t == FaithTradition.general) {
      return 'Oraciones cristianas';
    }
    return 'Oraciones tradicionales';
  }

  static String categoriesTraditionalCardDescription(FaithTradition t) {
    if (t == FaithTradition.evangelical) {
      return 'Oraciones bíblicas y promesas para tu vida diaria';
    }
    if (t == FaithTradition.general) {
      return 'Oraciones y reflexiones cristianas para cada día';
    }
    return 'Oraciones clásicas de la tradición cristiana';
  }

  static String communityLeaderFieldLabel(FaithTradition t) {
    if (t == FaithTradition.evangelical) {
      return 'Pastor o responsable (opcional)';
    }
    if (t == FaithTradition.general) {
      return 'Líder o responsable (opcional)';
    }
    return 'Sacerdote o responsable (opcional)';
  }

  static String communityLeaderFieldLabelShort(FaithTradition t) {
    if (t == FaithTradition.evangelical) {
      return 'Pastor / Responsable';
    }
    if (t == FaithTradition.general) {
      return 'Líder / Responsable';
    }
    return 'Sacerdote / Responsable';
  }

  static String communityLeaderHint(FaithTradition t) {
    if (t == FaithTradition.evangelical) {
      return 'Ejemplo: Pastor Juan Pérez';
    }
    if (t == FaithTradition.general) {
      return 'Ejemplo: Juan Pérez';
    }
    return 'Ejemplo: P. Juan Perez';
  }
}
