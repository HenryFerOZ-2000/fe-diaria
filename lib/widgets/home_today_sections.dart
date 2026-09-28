import 'package:flutter/material.dart';

/// Groups the daily practice and the optional content that follows it.
class HomeTodaySections extends StatelessWidget {
  const HomeTodaySections({
    super.key,
    required this.missions,
    required this.spiritualPath,
    required this.liturgy,
  });

  final Widget missions;
  final Widget spiritualPath;
  final Widget liturgy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [missions, const SizedBox(height: 22), spiritualPath, liturgy],
    );
  }
}
