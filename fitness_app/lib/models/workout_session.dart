/// Modelo de una sesion de entrenamiento guardada localmente en Hive.
class WorkoutSession {
  const WorkoutSession({
    required this.startedAt,
    required this.duration,
    required this.steps,
    required this.distanceMeters,
    required this.route,
    this.id = '',
    this.userEmail = 'local',
    this.activityType = 'Caminata',
    this.calories = 0,
    this.avgSpeedKmh = 0,
    this.maxIntensity = 0,
  });

  final String id;
  final String userEmail;
  final String activityType;
  final DateTime startedAt;
  final Duration duration;
  final int steps;
  final double distanceMeters;
  final double calories;
  final double avgSpeedKmh;
  final double maxIntensity;
  final List<Map<String, double>> route;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userEmail': userEmail,
        'activityType': activityType,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'steps': steps,
        'distanceMeters': distanceMeters,
        'calories': calories,
        'avgSpeedKmh': avgSpeedKmh,
        'maxIntensity': maxIntensity,
        'route': route,
      };

  factory WorkoutSession.fromMap(Map<dynamic, dynamic> map) {
    final rawRoute = (map['route'] as List?) ?? const [];
    return WorkoutSession(
      id: (map['id'] as String?) ?? '',
      userEmail: (map['userEmail'] as String?) ?? 'local',
      activityType: (map['activityType'] as String?) ?? 'Caminata',
      startedAt: DateTime.tryParse((map['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      duration: Duration(seconds: (map['durationSeconds'] as num?)?.toInt() ?? 0),
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      avgSpeedKmh: (map['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
      maxIntensity: (map['maxIntensity'] as num?)?.toDouble() ?? 0,
      route: rawRoute
          .whereType<Map>()
          .map(
            (p) => {
              'latitude': (p['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (p['longitude'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList(),
    );
  }
}
