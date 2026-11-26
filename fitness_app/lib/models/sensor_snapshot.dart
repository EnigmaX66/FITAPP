/// Lectura instantanea consolidada de los sensores fisicos del dispositivo.
class SensorSnapshot {
  const SensorSnapshot({
    this.steps = 0,
    this.accelMagnitude = 0.0,
    this.accelX = 0.0,
    this.accelY = 0.0,
    this.accelZ = 0.0,
    this.activityState = 'En reposo',
    this.cadenceSpm = 0,
    this.gyroMagnitude = 0.0,
    this.gyroX = 0.0,
    this.gyroY = 0.0,
    this.gyroZ = 0.0,
    this.postureLabel = 'Estable',
    this.tiltDegrees = 0.0,
    this.pedometerAvailable = true,
    this.accelerometerAvailable = true,
    this.gyroscopeAvailable = true,
    this.gpsAvailable = true,
    this.accelHistory = const [0.1, 0.15, 0.12, 0.2, 0.14, 0.18],
    this.gyroHistory = const [0.05, 0.08, 0.06, 0.1, 0.07, 0.09],
  });

  final int steps;
  final double accelMagnitude;
  final double accelX;
  final double accelY;
  final double accelZ;
  final String activityState;
  final int cadenceSpm;

  final double gyroMagnitude;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final String postureLabel;
  final double tiltDegrees;

  final bool pedometerAvailable;
  final bool accelerometerAvailable;
  final bool gyroscopeAvailable;
  final bool gpsAvailable;

  final List<double> accelHistory;
  final List<double> gyroHistory;

  bool get isMoving => accelMagnitude >= 1.2;

  SensorSnapshot copyWith({
    int? steps,
    double? accelMagnitude,
    double? accelX,
    double? accelY,
    double? accelZ,
    String? activityState,
    int? cadenceSpm,
    double? gyroMagnitude,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    String? postureLabel,
    double? tiltDegrees,
    bool? pedometerAvailable,
    bool? accelerometerAvailable,
    bool? gyroscopeAvailable,
    bool? gpsAvailable,
    List<double>? accelHistory,
    List<double>? gyroHistory,
  }) =>
      SensorSnapshot(
        steps: steps ?? this.steps,
        accelMagnitude: accelMagnitude ?? this.accelMagnitude,
        accelX: accelX ?? this.accelX,
        accelY: accelY ?? this.accelY,
        accelZ: accelZ ?? this.accelZ,
        activityState: activityState ?? this.activityState,
        cadenceSpm: cadenceSpm ?? this.cadenceSpm,
        gyroMagnitude: gyroMagnitude ?? this.gyroMagnitude,
        gyroX: gyroX ?? this.gyroX,
        gyroY: gyroY ?? this.gyroY,
        gyroZ: gyroZ ?? this.gyroZ,
        postureLabel: postureLabel ?? this.postureLabel,
        tiltDegrees: tiltDegrees ?? this.tiltDegrees,
        pedometerAvailable: pedometerAvailable ?? this.pedometerAvailable,
        accelerometerAvailable:
            accelerometerAvailable ?? this.accelerometerAvailable,
        gyroscopeAvailable: gyroscopeAvailable ?? this.gyroscopeAvailable,
        gpsAvailable: gpsAvailable ?? this.gpsAvailable,
        accelHistory: accelHistory ?? this.accelHistory,
        gyroHistory: gyroHistory ?? this.gyroHistory,
      );
}
