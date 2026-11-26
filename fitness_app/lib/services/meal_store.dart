import 'package:hive_flutter/hive_flutter.dart';

import '../models/meal_entry.dart';

class DailyNutritionTotals {
  const DailyNutritionTotals({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.mealsCount,
  });

  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int mealsCount;
}

/// Persistencia local de comidas del dia y conteo calorico en Hive.
class MealStore {
  static const _boxName = 'fit_pro_meals';

  Future<void> init() async {
    await _openBox();
  }

  Future<Box<dynamic>> _openBox() async => Hive.isBoxOpen(_boxName)
      ? Hive.box<dynamic>(_boxName)
      : await Hive.openBox<dynamic>(_boxName);

  Future<void> saveMeal(MealEntry meal) async {
    final box = await _openBox();
    await box.put(meal.id, meal.toMap());
  }

  Future<void> deleteMeal(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<List<MealEntry>> loadTodayMeals({String? userEmail}) async {
    final box = await _openBox();
    final now = DateTime.now();
    final items = box.values
        .whereType<Map>()
        .map(MealEntry.fromMap)
        .where((m) {
          final userOk = userEmail == null ||
              userEmail.isEmpty ||
              m.userEmail == userEmail ||
              m.userEmail == 'local';
          return userOk && _isSameDay(m.loggedAt, now);
        })
        .toList();

    items.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return items;
  }

  Future<DailyNutritionTotals> getTodayTotals({String? userEmail}) async {
    final meals = await loadTodayMeals(userEmail: userEmail);
    var kcal = 0.0;
    var p = 0.0;
    var c = 0.0;
    var f = 0.0;
    var counted = 0;

    for (final m in meals) {
      if (!m.addedToDailyTotal) continue;
      kcal += m.calories;
      p += m.proteinGrams;
      c += m.carbsGrams;
      f += m.fatGrams;
      counted++;
    }

    return DailyNutritionTotals(
      calories: kcal,
      proteinGrams: p,
      carbsGrams: c,
      fatGrams: f,
      mealsCount: counted,
    );
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
