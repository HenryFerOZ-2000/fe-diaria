import 'package:flutter/material.dart';

/// Modelo para categorías de contenido
class Category {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final String? subtitle;
  final List<String>? tags;

  Category({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.subtitle,
    this.tags,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: _iconFromString(json['icon'] as String? ?? 'menu_book'),
      route: json['route'] as String,
      subtitle: json['subtitle'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon.toString(),
      'route': route,
      'subtitle': subtitle,
      'tags': tags,
    };
  }

  static IconData _iconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'emoji_emotions':
        return Icons.emoji_emotions_rounded;
      case 'calendar_view_day':
        return Icons.calendar_view_day_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'library_books':
        return Icons.library_books_rounded;
      case 'bedtime':
        return Icons.bedtime_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'church':
        return Icons.church_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

