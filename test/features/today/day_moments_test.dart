import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/controllers/missions_controller.dart';
import 'package:verbum/design_system/icons/verbum_icons.dart';
import 'package:verbum/features/today/application/day_moments.dart';

void main() {
  Mission m(String id, {bool done = false, bool optional = false}) => Mission(
    id: id,
    title: id,
    description: '',
    icon: VerbumIcons.sun,
    completed: done,
    isOptional: optional,
  );

  test('asigna la hora de oración a cada momento', () {
    final moments = dayMomentsFor([m('verse'), m('morning'), m('night')]);
    expect(moments.map((x) => x.time), ['7:00', '12:00', '21:00']);
  });

  test('centra el primer esencial pendiente', () {
    final moments = dayMomentsFor([
      m('verse', done: true),
      m('morning'),
      m('practice'),
      m('night', optional: true),
    ]);
    expect(initialMomentIndex(moments), 1);
  });

  test('con los esenciales hechos centra la noche', () {
    final moments = dayMomentsFor([
      m('verse', done: true),
      m('morning', done: true),
      m('night', optional: true),
    ]);
    expect(initialMomentIndex(moments), 2);
  });
}
