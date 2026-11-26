import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/sensor_snapshot.dart';

/// Centraliza streams de podometro, acelerometro, giroscopio y GPS.
/// Aplica muestreo regulado (~120 ms) y cancelacion limpia para ahorrar bateria (RNF-01).
class FitnessSensors {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  StreamSubscription<Position>? _positionSub;

  int? _initialSensorSteps;
  bool _motionActive = false;
  bool _gpsActive = false;

  DateTime _lastAccelEmit = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastGyroEmit = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastStridePeak;
  int _estimatedCadence = 0;

  SensorSnapshot _current = const SensorSnapshot();
  SensorSnapshot get current => _current;

  final snapshot = StreamController<SensorSnapshot>.broadcast();
  final position = StreamController<Position>.broadcast();
  final errors = StreamController<String>.broadcast();

  bool get isMotionRunning => _motionActive;
  bool get isGpsRunning => _gpsActive;

  void _updateSnapshot(SensorSnapshot next) {
    _current = next;
    if (!snapshot.isClosed) {
      snapshot.add(next);
    }
  }

  /// Inicia unicamente los sensores de movimiento (podometro, acelerometro, giroscopio).
  Future<void> startMotionSensors({bool resetStepBaseline = false}) async {
    if (resetStepBaseline) {
      _initialSensorSteps = null;
      _updateSnapshot(_current.copyWith(steps: 0));
    }
    if (_motionActive) return;
    _motionActive = true;

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          _initialSensorSteps ??= event.steps;
          final sessionSteps = max(0, event.steps - _initialSensorSteps!);
          _updateSnapshot(
            _current.copyWith(
              steps: sessionSteps,
              pedometerAvailable: true,
            ),
          );
        },
        onError: (_) {
          _updateSnapshot(_current.copyWith(pedometerAvailable: false));
          if (!errors.isClosed) {
            errors.add('Podómetro físico no disponible en este dispositivo.');
          }
        },
      );
    } catch (_) {
      _updateSnapshot(_current.copyWith(pedometerAvailable: false));
    }

    try {
      _accelerometerSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (event) {
          final now = DateTime.now();
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final dynamicAccel = (magnitude - 9.81).abs();

          // Deteccion basica de zancadas para estimar cadencia (spm) y pasos por fallback.
          if (dynamicAccel > 2.1) {
            if (_lastStridePeak != null) {
              final deltaMs = now.difference(_lastStridePeak!).inMilliseconds;
              if (deltaMs > 250 && deltaMs < 1500) {
                _estimatedCadence = (60000 / deltaMs).round().clamp(40, 210);
              }
            }

            // Si el podómetro físico no está disponible (ej. en emulador), usamos el acelerómetro como fallback.
            if (!_current.pedometerAvailable) {
              if (_lastStridePeak == null ||
                  now.difference(_lastStridePeak!).inMilliseconds > 350) {
                final newSteps = _current.steps + 1;
                _updateSnapshot(_current.copyWith(steps: newSteps));
              }
            }

            _lastStridePeak = now;
          } else if (_lastStridePeak != null &&
              now.difference(_lastStridePeak!).inSeconds > 3) {
            _estimatedCadence = 0;
          }

          if (now.difference(_lastAccelEmit).inMilliseconds < 120) return;
          _lastAccelEmit = now;

          final stateLabel = switch (dynamicAccel) {
            < 0.9 => 'En reposo',
            < 2.5 => 'Caminata ligera',
            < 5.0 => 'Ritmo moderado',
            _ => 'Movimiento intenso',
          };

          final nextHistory = List<double>.from(_current.accelHistory)
            ..add(dynamicAccel.clamp(0.0, 12.0));
          if (nextHistory.length > 26) nextHistory.removeAt(0);

          _updateSnapshot(
            _current.copyWith(
              accelMagnitude: dynamicAccel,
              accelX: event.x,
              accelY: event.y,
              accelZ: event.z,
              activityState: stateLabel,
              cadenceSpm: _estimatedCadence,
              accelerometerAvailable: true,
              accelHistory: nextHistory,
            ),
          );
        },
        onError: (_) {
          _updateSnapshot(_current.copyWith(accelerometerAvailable: false));
          if (!errors.isClosed) {
            errors.add('Acelerómetro no disponible en este dispositivo.');
          }
        },
      );
    } catch (_) {
      _updateSnapshot(_current.copyWith(accelerometerAvailable: false));
    }

    try {
      _gyroscopeSub = gyroscopeEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        (event) {
          final now = DateTime.now();
          if (now.difference(_lastGyroEmit).inMilliseconds < 120) return;
          _lastGyroEmit = now;

          final angularMag = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          final tiltDeg = (atan2(event.y, event.x) * 180 / pi).abs();

          final posture = angularMag < 0.25
              ? 'Postura estable'
              : (event.y.abs() > event.x.abs()
                  ? 'Giro lateral'
                  : 'Inclinación activa');

          final nextHistory = List<double>.from(_current.gyroHistory)
            ..add(angularMag.clamp(0.0, 8.0));
          if (nextHistory.length > 26) nextHistory.removeAt(0);

          _updateSnapshot(
            _current.copyWith(
              gyroMagnitude: angularMag,
              gyroX: event.x,
              gyroY: event.y,
              gyroZ: event.z,
              postureLabel: posture,
              tiltDegrees: tiltDeg,
              gyroscopeAvailable: true,
              gyroHistory: nextHistory,
            ),
          );
        },
        onError: (_) {
          _updateSnapshot(_current.copyWith(gyroscopeAvailable: false));
          if (!errors.isClosed) {
            errors.add('Giroscopio no disponible en este dispositivo.');
          }
        },
      );
    } catch (_) {
      _updateSnapshot(_current.copyWith(gyroscopeAvailable: false));
    }
  }

  /// Inicia el rastreo GPS de alta precision para rutas y velocidad.
  Future<void> startGpsTracking() async {
    if (_gpsActive) return;
    _gpsActive = true;
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 4,
      );
      _positionSub = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
        (pos) {
          _updateSnapshot(_current.copyWith(gpsAvailable: true));
          if (!position.isClosed) position.add(pos);
        },
        onError: (_) {
          _updateSnapshot(_current.copyWith(gpsAvailable: false));
          if (!errors.isClosed) {
            errors.add('No fue posible obtener señal GPS.');
          }
        },
      );
    } catch (_) {
      _updateSnapshot(_current.copyWith(gpsAvailable: false));
      if (!errors.isClosed) {
        errors.add('Error al iniciar el servicio GPS.');
      }
    }
  }

  Future<Position?> getCurrentLocationOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _updateSnapshot(_current.copyWith(gpsAvailable: true));
      return pos;
    } catch (_) {
      return null;
    }
  }

  Future<void> startAll({bool resetStepBaseline = true}) async {
    await startMotionSensors(resetStepBaseline: resetStepBaseline);
    await startGpsTracking();
  }

  void stopGps() {
    _positionSub?.cancel();
    _positionSub = null;
    _gpsActive = false;
  }

  /// Detiene todos los listeners de hardware para conservar bateria.
  void stopAll() {
    _stepSub?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    _positionSub?.cancel();
    _stepSub = null;
    _accelerometerSub = null;
    _gyroscopeSub = null;
    _positionSub = null;
    _motionActive = false;
    _gpsActive = false;
  }

  void dispose() {
    stopAll();
    snapshot.close();
    position.close();
    errors.close();
  }
}
