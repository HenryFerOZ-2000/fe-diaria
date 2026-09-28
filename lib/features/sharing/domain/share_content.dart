import 'dart:ui';

import 'package:flutter/foundation.dart';

enum ShareContentKind { verse, prayer, psalm, mission, reflection }

enum ShareContentMood { neutral, hopeful, night, liturgical }

enum ShareTradition { catholic, evangelical, ecumenical }

@immutable
class ShareContent {
  factory ShareContent({
    required String title,
    required String body,
    required ShareContentKind kind,
    String? reference,
    ShareTradition? tradition,
    ShareContentMood mood = ShareContentMood.neutral,
    Color? liturgicalColor,
    String? sourceLabel,
    String? shareCaption,
  }) {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) {
      throw ArgumentError.value(body, 'body', 'No puede estar vacío');
    }
    return ShareContent._(
      title: title.trim(),
      body: normalizedBody,
      kind: kind,
      reference: reference?.trim(),
      tradition: tradition,
      mood: mood,
      liturgicalColor: liturgicalColor,
      sourceLabel: sourceLabel?.trim(),
      shareCaption: shareCaption?.trim(),
    );
  }

  const ShareContent._({
    required this.title,
    required this.body,
    required this.kind,
    required this.reference,
    required this.tradition,
    required this.mood,
    required this.liturgicalColor,
    required this.sourceLabel,
    required this.shareCaption,
  });

  final String title;
  final String body;
  final ShareContentKind kind;
  final String? reference;
  final ShareTradition? tradition;
  final ShareContentMood mood;
  final Color? liturgicalColor;
  final String? sourceLabel;
  final String? shareCaption;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareContent &&
          other.title == title &&
          other.body == body &&
          other.kind == kind &&
          other.reference == reference &&
          other.tradition == tradition &&
          other.mood == mood &&
          other.liturgicalColor == liturgicalColor &&
          other.sourceLabel == sourceLabel &&
          other.shareCaption == shareCaption;

  @override
  int get hashCode => Object.hash(
    title,
    body,
    kind,
    reference,
    tradition,
    mood,
    liturgicalColor,
    sourceLabel,
    shareCaption,
  );
}
