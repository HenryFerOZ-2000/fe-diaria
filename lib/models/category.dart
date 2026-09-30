import '../design_system/icons/verbum_icons.dart';

/// Modelo para categorías de contenido
class Category {
  final String id;
  final String title;
  final String description;
  final VerbumIcons icon;
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

  static VerbumIcons _iconFromString(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return VerbumIcons.bookOpenText;
      case 'favorite':
        return VerbumIcons.heart;
      case 'emoji_emotions':
        return VerbumIcons.smiley;
      case 'calendar_view_day':
        return VerbumIcons.calendarCheck;
      case 'book':
        return VerbumIcons.book;
      case 'auto_stories':
        return VerbumIcons.bookOpen;
      case 'library_books':
        return VerbumIcons.books;
      case 'bedtime':
        return VerbumIcons.moonStars;
      case 'healing':
        return VerbumIcons.firstAid;
      case 'edit_note':
        return VerbumIcons.notePencil;
      case 'church':
        return VerbumIcons.church;
      default:
        return VerbumIcons.squaresFour;
    }
  }
}
