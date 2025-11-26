class Prayer {
  final int id;
  final String text;
  final String type; // 'morning' or 'evening'
  final String title;

  Prayer({
    required this.id,
    required this.text,
    required this.type,
    required this.title,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as int,
      text: json['text'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'title': title,
    };
  }

  Prayer copyWith({
    int? id,
    String? text,
    String? type,
    String? title,
  }) {
    return Prayer(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      title: title ?? this.title,
    );
  }
}

