import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

typedef ItemLoader<T> = Future<List<T>> Function(String categoryKey);
typedef IdSelector<T> = String Function(T item);

class RotationService<T> {
  final ItemLoader<T> loader;
  final IdSelector<T> idSelector;
  final Random _random;
  final String sourceKey;

  RotationService({
    required this.sourceKey,
    required this.loader,
    required this.idSelector,
    Random? random,
  }) : _random = random ?? Random();

  String _key(String category) => 'seen_${sourceKey}_$category';

  Future<T?> next(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_key(category)) ?? [];
    final items = await loader(category);
    if (items.isEmpty) return null;

    var available = items.where((i) => !seen.contains(idSelector(i))).toList();
    if (available.isEmpty) {
      await prefs.remove(_key(category));
      available = items;
      seen.clear();
    }

    final chosen = available[_random.nextInt(available.length)];
    await prefs.setStringList(_key(category), [...seen, idSelector(chosen)]);
    return chosen;
  }

  Future<void> reset(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(category));
  }
}

