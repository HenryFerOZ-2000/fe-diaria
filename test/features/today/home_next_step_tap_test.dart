import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La tarjeta del siguiente paso se monta sobre la portada con un
/// Transform; solo recibe toques en la zona solapada si comparte hijo de
/// la lista con la portada (como en HomeScreen).
void main() {
  testWidgets('la parte solapada sobre la portada recibe toques', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 300),
                  Transform.translate(
                    offset: const Offset(0, -64),
                    child: GestureDetector(
                      onTap: () => taps++,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox(height: 80),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 300 - 64 + 20));
    expect(taps, 1);
  });
}
