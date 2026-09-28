import 'package:flutter/foundation.dart';

@immutable
class SharePage {
  const SharePage({
    required this.body,
    required this.index,
    required this.total,
  });

  final String body;
  final int index;
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharePage &&
          other.body == body &&
          other.index == index &&
          other.total == total;

  @override
  int get hashCode => Object.hash(body, index, total);
}
