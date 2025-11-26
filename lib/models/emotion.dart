import 'package:flutter/material.dart';

/// Modelo para emociones con contenido asociado
class Emotion {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? description;
  final List<String>? tags;

  Emotion({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description,
    this.tags,
  });

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: _iconFromString(json['icon'] as String? ?? 'sentiment_neutral'),
      color: _colorFromString(json['color'] as String? ?? '#FF9800'),
      description: json['description'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.toString(),
      'color': _colorToString(color),
      'description': description,
      'tags': tags,
    };
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'sentiment_very_dissatisfied':
        return Icons.sentiment_very_dissatisfied;
      case 'bedtime':
        return Icons.bedtime;
      case 'warning':
        return Icons.warning;
      case 'favorite':
        return Icons.favorite;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'help':
        return Icons.help;
      case 'visibility_off':
        return Icons.visibility_off;
      default:
        return Icons.sentiment_neutral;
    }
  }

  static Color _colorFromString(String colorString) {
    switch (colorString) {
      case '#FF9800':
        return const Color(0xFFFF9800);
      case '#2196F3':
        return const Color(0xFF2196F3);
      case '#9E9E9E':
        return const Color(0xFF9E9E9E);
      case '#FFC107':
        return const Color(0xFFFFC107);
      case '#4CAF50':
        return const Color(0xFF4CAF50);
      case '#FFEB3B':
        return const Color(0xFFFFEB3B);
      case '#9C27B0':
        return const Color(0xFF9C27B0);
      case '#F44336':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  static String _colorToString(Color color) {
    if (color.value == 0xFFFF9800) return '#FF9800';
    if (color.value == 0xFF2196F3) return '#2196F3';
    if (color.value == 0xFF9E9E9E) return '#9E9E9E';
    if (color.value == 0xFFFFC107) return '#FFC107';
    if (color.value == 0xFF4CAF50) return '#4CAF50';
    if (color.value == 0xFFFFEB3B) return '#FFEB3B';
    if (color.value == 0xFF9C27B0) return '#9C27B0';
    if (color.value == 0xFFF44336) return '#F44336';
    return '#FF9800';
  }
}

