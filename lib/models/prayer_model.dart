import 'dart:convert';

class PrayerModel {
  final String id;
  final String category;
  final String title;
  final String text;
  final List<String> tags;
  final String? verseRef;

  const PrayerModel({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
    required this.tags,
    this.verseRef,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      verseRef: json['verseRef'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'text': text,
      'tags': tags,
      if (verseRef != null) 'verseRef': verseRef,
    };
  }

  static List<PrayerModel> listFromJson(String source) {
    final data = json.decode(source) as List<dynamic>;
    return data
        .map((e) => PrayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

