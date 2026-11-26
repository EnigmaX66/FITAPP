import 'package:hive_flutter/hive_flutter.dart';

import '../models/workout_session.dart';

class AggregateStats {
  const AggregateStats({
    required this.sessionsCount,
    required this.totalSteps,
    required this.totalDistanceMeters,
    required this.totalCalories,
    required this.totalDuration,
  });

  final int sessionsCount;
  final int totalSteps;
  final double totalDistanceMeters;
  final double totalCalories;
  final Duration totalDuration;
}

/// Persistencia local de sesiones e historial acumulado en Hive.
class SessionStore {
  static const _boxName = 'fitness_sessions';

  Future<void> init() => Hive.initFlutter();

  Future<Box<dynamic>> _openBox() async => Hive.isBoxOpen(_boxName)
      ? Hive.box<dynamic>(_boxName)
      : await Hive.openBox<dynamic>(_boxName);

  Future<void> save(WorkoutSession session) async {
    final box = await _openBox();
    await box.add(session.toMap());
  }

  Future<List<WorkoutSession>> load({String? userEmail}) async {
    final box = await _openBox();
    final all = box.values
        .whereType<Map>()
        .map(WorkoutSession.fromMap)
        .toList()
        .reversed
        .toList();

    if (userEmail == null || userEmail.isEmpty) return all;
    return all
        .where((s) => s.userEmail == userEmail || s.userEmail == 'local')
        .toList();
  }

  Future<AggregateStats> getStats({String? userEmail}) async {
    final list = await load(userEmail: userEmail);
    var steps = 0;
    var dist = 0.0;
    var kcal = 0.0;
    var secs = 0;
    for (final s in list) {
      steps += s.steps;
      dist += s.distanceMeters;
      kcal += s.calories > 0 ? s.calories : s.steps * 0.04;
      secs += s.duration.inSeconds;
    }
    return AggregateStats(
      sessionsCount: list.length,
      totalSteps: steps,
      totalDistanceMeters: dist,
      totalCalories: kcal,
      totalDuration: Duration(seconds: secs),
    );
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
