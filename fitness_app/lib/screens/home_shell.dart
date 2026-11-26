import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/sensor_snapshot.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../services/auth_store.dart';
import '../services/biometric_service.dart';
import '../services/fitness_sensors.dart';
import '../services/meal_analyzer_service.dart';
import '../services/meal_store.dart';
import '../services/permissions_service.dart';
import '../services/session_store.dart';
import '../widgets/workout_map_widget.dart';
import 'deporte_tab.dart';
import 'dispositivo_tab.dart';
import 'estado_tab.dart';
import 'nutrition_screen.dart';
import 'yo_tab.dart';

/// Contenedor principal con barra inferior de 4 pestanas y ciclo de vida optimizado (RNF-01).
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.initialUser,
    required this.authStore,
    required this.sessionStore,
    required this.mealStore,
    required this.permissionsService,
    required this.biometricService,
    required this.onUserUpdated,
    required this.onLogout,
  });

  final UserProfile initialUser;
  final AuthStore authStore;
  final SessionStore sessionStore;
  final MealStore mealStore;
  final PermissionsService permissionsService;
  final BiometricService biometricService;
  final ValueChanged<UserProfile> onUserUpdated;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tabIndex = 0;
  late UserProfile _user;

  final _sensors = FitnessSensors();
  StreamSubscription<SensorSnapshot>? _snapshotSub;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<String>? _errorSub;
  Timer? _clockTimer;

  SensorSnapshot _snapshot = const SensorSnapshot();
  bool _workoutRunning = false;
  String _activityType = 'Caminata';
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  double _distanceMeters = 0.0;
  double _speedKmh = 0.0;
  double _maxIntensity = 0.0;
  LatLng? _currentLocation;
  LatLng? _lastPoint;
  final List<LatLng> _route = [];
  String _statusMessage =
      'Presiona iniciar para activar el mapa GPS y el registro de ruta.';

  List<WorkoutSession> _history = const [];
  AggregateStats? _stats;
  final _mealAnalyzer = SimulatedVisionMealAnalyzer();
  DailyNutritionTotals _nutritionTotals = const DailyNutritionTotals(
    calories: 0,
    proteinGrams: 0,
    carbsGrams: 0,
    fatGrams: 0,
    mealsCount: 0,
  );

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    WidgetsBinding.instance.addObserver(this);
    _bindStreams();
    _sensors.startMotionSensors(resetStepBaseline: false);
    _loadHistory();
    _loadNutrition();
  }

  void _bindStreams() {
    _snapshotSub = _sensors.snapshot.stream.listen((snap) {
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _maxIntensity = max(_maxIntensity, snap.accelMagnitude);
      });
    });

    _positionSub = _sensors.position.stream.listen((pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = point;
        if (_workoutRunning) {
          if (_lastPoint != null) {
            _distanceMeters += Geolocator.distanceBetween(
              _lastPoint!.latitude,
              _lastPoint!.longitude,
              pos.latitude,
              pos.longitude,
            );
          }
          _lastPoint = point;
          _route.add(point);
          _speedKmh = max(0.0, pos.speed * 3.6);
        }
      });
    });

    _errorSub = _sensors.errors.stream.listen((msg) {
      if (!mounted) return;
      setState(() => _statusMessage = msg);
    });
  }

  Future<void> _loadHistory() async {
    final list = await widget.sessionStore.load(userEmail: _user.email);
    final stats = await widget.sessionStore.getStats(userEmail: _user.email);
    if (!mounted) return;
    setState(() {
      _history = list;
      _stats = stats;
    });
  }

  Future<void> _loadNutrition() async {
    final totals = await widget.mealStore.getTodayTotals(userEmail: _user.email);
    if (!mounted) return;
    setState(() => _nutritionTotals = totals);
  }

  Future<void> _openNutrition(double burnedCalories) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionScreen(
          user: _user,
          mealStore: widget.mealStore,
          analyzerService: _mealAnalyzer,
          burnedCaloriesToday: burnedCalories,
          onMealsChanged: _loadNutrition,
        ),
      ),
    );
    await _loadNutrition();
  }

  Future<void> _locateMe() async {
    final ok = await widget.permissionsService.requestLocationOnly(context);
    if (!ok) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'Activa los permisos y el GPS del teléfono para centrar tu ubicación.',
        );
      }
      return;
    }
    setState(() => _statusMessage = 'Obteniendo coordenadas GPS actuales...');
    final pos = await _sensors.getCurrentLocationOnce();
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _statusMessage =
            'Ubicación actual fijada (±${pos.accuracy.toStringAsFixed(0)} m).';
      });
    } else {
      setState(
        () => _statusMessage = 'No se pudo fijar señal GPS. Intenta al aire libre.',
      );
    }
  }

  Future<void> _toggleWorkout() async {
    if (_workoutRunning) {
      await _finishWorkout();
      return;
    }

    final granted =
        await widget.permissionsService.requestWorkoutPermissions(context);
    if (!granted) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'Permisos de ubicación y actividad física requeridos para iniciar.',
        );
      }
      return;
    }

    setState(() {
      _workoutRunning = true;
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
      _distanceMeters = 0.0;
      _speedKmh = 0.0;
      _maxIntensity = 0.0;
      _lastPoint = null;
      _route.clear();
      _statusMessage = 'Entrenamiento activo: sensores y GPS grabando ruta.';
    });

    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt!);
      });
    });

    await _sensors.startAll(resetStepBaseline: true);
    final initialPos = await _sensors.getCurrentLocationOnce();
    if (initialPos != null && mounted && _workoutRunning) {
      final p = LatLng(initialPos.latitude, initialPos.longitude);
      setState(() {
        _currentLocation = p;
        if (_route.isEmpty) {
          _route.add(p);
          _lastPoint = p;
        }
      });
    }
  }

  Future<void> _finishWorkout() async {
    _clockTimer?.cancel();
    _clockTimer = null;

    final start = _startedAt;
    if (start != null) {
      final duration = DateTime.now().difference(start);
      final kcal = _estimateCalories(_snapshot.steps, _distanceMeters);
      final avgKmh = duration.inSeconds > 0
          ? (_distanceMeters / 1000.0) / (duration.inSeconds / 3600.0)
          : 0.0;

      await widget.sessionStore.save(
        WorkoutSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userEmail: _user.email,
          activityType: _activityType,
          startedAt: start,
          duration: duration,
          steps: _snapshot.steps,
          distanceMeters: _distanceMeters,
          calories: kcal,
          avgSpeedKmh: avgKmh,
          maxIntensity: _maxIntensity,
          route: _route
              .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
              .toList(),
        ),
      );
    }

    _sensors.stopGps();
    await _loadHistory();
    if (!mounted) return;
    setState(() {
      _workoutRunning = false;
      _statusMessage = 'Recorrido guardado en tu historial local.';
    });
  }

  double _estimateCalories(int steps, double distanceMeters) {
    final factor = _user.weightKg / 70.0;
    final fromSteps = steps * 0.042 * factor;
    final fromDist = (distanceMeters / 1000.0) * 58.0 * factor;
    return max(fromSteps, fromDist);
  }

  void _handleUserUpdate(UserProfile next) {
    setState(() => _user = next);
    widget.authStore.updateUser(next);
    widget.onUserUpdated(next);
  }

  void _inspectSession(WorkoutSession session) {
    final pts = session.route
        .map(
          (p) => LatLng(
            p['latitude'] ?? 0.0,
            p['longitude'] ?? 0.0,
          ),
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${session.activityType} · ${(session.distanceMeters / 1000).toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${session.steps} pasos · ${session.duration.inMinutes} min · ${session.calories.toStringAsFixed(0)} kcal',
            ),
            const SizedBox(height: 12),
            WorkoutMapWidget(
              route: pts,
              currentLocation: pts.isNotEmpty ? pts.last : _currentLocation,
              accentColor: Theme.of(context).colorScheme.primary,
              height: 260,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_workoutRunning) {
        _finishWorkout();
      }
      _sensors.stopAll();
    } else if (state == AppLifecycleState.resumed) {
      _sensors.startMotionSensors(resetStepBaseline: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _snapshotSub?.cancel();
    _positionSub?.cancel();
    _errorSub?.cancel();
    _sensors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalStepsToday =
        (_workoutRunning ? _snapshot.steps : (_stats?.totalSteps ?? 0) + _snapshot.steps);
    final totalDistanceKm = _workoutRunning
        ? (_distanceMeters / 1000.0)
        : ((_stats?.totalDistanceMeters ?? 0.0) + _distanceMeters) / 1000.0;
    final totalKcal = _estimateCalories(
      totalStepsToday,
      totalDistanceKm * 1000.0,
    );

    final pages = [
      EstadoTab(
        user: _user,
        snapshot: _snapshot,
        todaySteps: totalStepsToday,
        todayDistanceKm: totalDistanceKm,
        todayCalories: totalKcal,
        nutritionTotals: _nutritionTotals,
        workoutRunning: _workoutRunning,
        onGoToWorkout: () => setState(() => _tabIndex = 1),
        onOpenNutrition: () => _openNutrition(totalKcal),
      ),
      DeporteTab(
        user: _user,
        snapshot: _snapshot,
        running: _workoutRunning,
        activityType: _activityType,
        onActivityChanged: (m) => setState(() => _activityType = m),
        elapsed: _elapsed,
        workoutSteps: _snapshot.steps,
        distanceMeters: _distanceMeters,
        speedKmh: _speedKmh,
        calories: _estimateCalories(_snapshot.steps, _distanceMeters),
        route: _route,
        currentLocation: _currentLocation,
        statusMessage: _statusMessage,
        history: _history,
        stats: _stats,
        onToggleWorkout: _toggleWorkout,
        onLocateMe: _locateMe,
        onInspectSession: _inspectSession,
      ),
      DispositivoTab(
        user: _user,
        snapshot: _snapshot,
        onUpdateUser: _handleUserUpdate,
      ),
      YoTab(
        user: _user,
        permissionsService: widget.permissionsService,
        biometricService: widget.biometricService,
        onUpdateUser: _handleUserUpdate,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (idx) => setState(() => _tabIndex = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.adjust_rounded),
            label: 'Estado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_rounded),
            label: 'Deporte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch_outlined),
            label: 'Dispositivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Yo',
          ),
        ],
      ),
    );
  }
}
