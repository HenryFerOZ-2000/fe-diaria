/// Modelo para la guía del rosario
class RosaryGuide {
  final String id;
  final String title;
  final String description;
  final List<RosaryMystery> mysteries;
  final List<RosaryStep> steps;

  RosaryGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.mysteries,
    required this.steps,
  });

  factory RosaryGuide.fromJson(Map<String, dynamic> json) {
    return RosaryGuide(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      mysteries: (json['mysteries'] as List<dynamic>)
          .map((m) => RosaryMystery.fromJson(m as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((s) => RosaryStep.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mysteries': mysteries.map((m) => m.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }
}

/// Modelo para los misterios del rosario
class RosaryMystery {
  final String id;
  final String name;
  final String day;
  final List<String> mysteries;

  RosaryMystery({
    required this.id,
    required this.name,
    required this.day,
    required this.mysteries,
  });

  factory RosaryMystery.fromJson(Map<String, dynamic> json) {
    return RosaryMystery(
      id: json['id'] as String,
      name: json['name'] as String,
      day: json['day'] as String,
      mysteries: List<String>.from(json['mysteries'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'day': day,
      'mysteries': mysteries,
    };
  }
}

/// Modelo para los pasos del rosario
class RosaryStep {
  final int order;
  final String title;
  final String prayer;
  final int? repetitions;

  RosaryStep({
    required this.order,
    required this.title,
    required this.prayer,
    this.repetitions,
  });

  factory RosaryStep.fromJson(Map<String, dynamic> json) {
    return RosaryStep(
      order: json['order'] as int,
      title: json['title'] as String,
      prayer: json['prayer'] as String,
      repetitions: json['repetitions'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'prayer': prayer,
      'repetitions': repetitions,
    };
  }
}

