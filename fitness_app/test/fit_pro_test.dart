import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fitness_app/models/meal_entry.dart';
import 'package:fitness_app/models/sensor_snapshot.dart';
import 'package:fitness_app/models/user_profile.dart';
import 'package:fitness_app/models/workout_session.dart';
import 'package:fitness_app/screens/estado_tab.dart';
import 'package:fitness_app/screens/login_screen.dart';
import 'package:fitness_app/screens/nutrition_screen.dart';
import 'package:fitness_app/services/auth_store.dart';
import 'package:fitness_app/services/biometric_service.dart';
import 'package:fitness_app/services/meal_analyzer_service.dart';
import 'package:fitness_app/services/meal_store.dart';
import 'package:fitness_app/services/session_store.dart';
import 'package:fitness_app/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fit_pro_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('AuthStore registra usuario, valida credenciales y cierra sesion', () async {
    final store = AuthStore();
    final reg = await store.register(
      name: 'Gael',
      email: 'gael@fitpro.mx',
      password: 'password123',
      stepGoal: 9000,
    );
    expect(reg.ok, isTrue);
    expect(reg.user?.name, 'Gael');
    expect(reg.user?.stepGoal, 9000);

    await store.logout();
    expect(await store.getCurrentUser(), isNull);

    final badLogin = await store.loginWithCredentials('gael@fitpro.mx', 'wrong');
    expect(badLogin.ok, isFalse);

    final goodLogin =
        await store.loginWithCredentials('gael@fitpro.mx', 'password123');
    expect(goodLogin.ok, isTrue);
    expect(goodLogin.user?.email, 'gael@fitpro.mx');
  });

  test('SessionStore guarda y calcula estadisticas acumuladas', () async {
    final sessions = SessionStore();
    await sessions.clearAll();
    await sessions.save(
      WorkoutSession(
        id: '1',
        userEmail: 'gael@fitpro.mx',
        activityType: 'Carrera',
        startedAt: DateTime(2026, 11, 25, 7, 30),
        duration: const Duration(minutes: 25),
        steps: 3200,
        distanceMeters: 2450,
        calories: 180,
        route: const [
          {'latitude': 20.2279, 'longitude': -99.0928},
          {'latitude': 20.2290, 'longitude': -99.0910},
        ],
      ),
    );

    final list = await sessions.load(userEmail: 'gael@fitpro.mx');
    expect(list.length, 1);
    expect(list.first.activityType, 'Carrera');
    expect(list.first.route.length, 2);

    final stats = await sessions.getStats(userEmail: 'gael@fitpro.mx');
    expect(stats.totalSteps, 3200);
    expect(stats.totalDistanceMeters, 2450);
  });

  test('MealStore guarda comidas y suma calorias del dia', () async {
    final mealStore = MealStore();
    await mealStore.clearAll();
    final analyzer = SimulatedVisionMealAnalyzer();
    final estimated = await analyzer.analyzePhoto('sample://avena.jpg');
    expect(estimated.calories, greaterThan(0));

    await mealStore.saveMeal(
      MealEntry(
        id: 'm1',
        userEmail: 'gael@fitpro.mx',
        name: estimated.name,
        portionLabel: estimated.portionLabel,
        calories: estimated.calories,
        proteinGrams: estimated.proteinGrams,
        carbsGrams: estimated.carbsGrams,
        fatGrams: estimated.fatGrams,
        loggedAt: DateTime.now(),
        addedToDailyTotal: true,
      ),
    );

    final totals = await mealStore.getTodayTotals(userEmail: 'gael@fitpro.mx');
    expect(totals.mealsCount, 1);
    expect(totals.calories, estimated.calories);
  });

  testWidgets('LoginScreen muestra FITPRO, huella y boton de registro',
      (tester) async {
    final store = AuthStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(darkMode: true, accentIndex: 0),
        home: LoginScreen(
          authStore: store,
          biometricService: BiometricService(),
          onAuthenticated: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FITPRO'), findsOneWidget);
    expect(find.text('Ingresar con huella dactilar'), findsOneWidget);
    expect(find.text('Regístrate aquí'), findsOneWidget);
  });

  testWidgets('EstadoTab renderiza anillo, nutricion y tarjetas de sensores',
      (tester) async {
    final user = UserProfile(
      id: 'u1',
      name: 'Gael',
      email: 'gael@fitpro.mx',
      passwordHash: 'abc',
      createdAt: DateTime(2026, 11, 25),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(darkMode: true, accentIndex: 0),
        home: Scaffold(
          body: EstadoTab(
            user: user,
            snapshot: const SensorSnapshot(
              steps: 1250,
              accelMagnitude: 2.3,
              activityState: 'Caminata ligera',
              gyroMagnitude: 0.45,
              postureLabel: 'Giro lateral',
            ),
            todaySteps: 1250,
            todayDistanceKm: 0.95,
            todayCalories: 62,
            nutritionTotals: const DailyNutritionTotals(
              calories: 480,
              proteinGrams: 34,
              carbsGrams: 46,
              fatGrams: 14,
              mealsCount: 1,
            ),
            workoutRunning: false,
            onGoToWorkout: () {},
            onOpenNutrition: () {},
          ),
        ),
      ),
    );

    expect(find.text('1250'), findsOneWidget);
    expect(find.text('Pasos'), findsOneWidget);
    expect(find.text('Kcal'), findsOneWidget);
    expect(find.text('Km'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nutrición y Comidas'), 150);
    expect(find.text('Nutrición y Comidas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Intensidad y Zancada'), 150);
    expect(find.text('Intensidad y Zancada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Orientación y Postura'), 150);
    expect(find.text('Orientación y Postura'), findsOneWidget);
  });

  testWidgets('NutritionScreen analiza platillo de ejemplo y suma al contador',
      (tester) async {
    final mealStore = _InMemoryMealStore();
    final user = UserProfile(
      id: 'u1',
      name: 'Gael',
      email: 'gael@fitpro.mx',
      passwordHash: 'abc',
      createdAt: DateTime(2026, 11, 25),
    );

    var changedCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(darkMode: true, accentIndex: 0),
        home: NutritionScreen(
          user: user,
          mealStore: mealStore,
          analyzerService: SimulatedVisionMealAnalyzer(),
          burnedCaloriesToday: 120,
          onMealsChanged: () => changedCount++,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Probar análisis con platillo de ejemplo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    await tester.ensureVisible(find.text('Sumar al contador diario'));
    await tester.pump();
    await tester.tap(find.text('Sumar al contador diario'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(changedCount, 1);
    final totals = await mealStore.getTodayTotals(userEmail: 'gael@fitpro.mx');
    expect(totals.mealsCount, 1);
    expect(totals.calories, greaterThan(0));
  });
}

class _InMemoryMealStore extends MealStore {
  final List<MealEntry> _items = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> saveMeal(MealEntry meal) async {
    _items.removeWhere((m) => m.id == meal.id);
    _items.add(meal);
  }

  @override
  Future<void> deleteMeal(String id) async {
    _items.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<MealEntry>> loadTodayMeals({String? userEmail}) async =>
      List<MealEntry>.from(_items);

  @override
  Future<DailyNutritionTotals> getTodayTotals({String? userEmail}) async {
    var kcal = 0.0;
    var p = 0.0;
    var c = 0.0;
    var f = 0.0;
    var count = 0;
    for (final m in _items) {
      if (!m.addedToDailyTotal) continue;
      kcal += m.calories;
      p += m.proteinGrams;
      c += m.carbsGrams;
      f += m.fatGrams;
      count++;
    }
    return DailyNutritionTotals(
      calories: kcal,
      proteinGrams: p,
      carbsGrams: c,
      fatGrams: f,
      mealsCount: count,
    );
  }
}
