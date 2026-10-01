import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/personalization/domain/profile_emotions.dart';

void main() {
  test('ids únicos y nombres visibles', () {
    final ids = profileEmotions.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(profileEmotionLabel('agradecido'), 'Agradecido');
    expect(profileEmotionLabel('valor_antiguo'), 'valor_antiguo');
  });
}
