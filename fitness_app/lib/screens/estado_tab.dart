import 'package:flutter/material.dart';

import '../models/sensor_snapshot.dart';
import '../models/user_profile.dart';
import '../services/meal_store.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_chart_card.dart';
import '../widgets/step_ring_gauge.dart';
import '../widgets/wave_metric_card.dart';

/// Pestana principal "Estado" (Dashboard) conectada a sensores y modulo de comidas con animacion de entrada.
class EstadoTab extends StatefulWidget {
  const EstadoTab({
    super.key,
    required this.user,
    required this.snapshot,
    required this.todaySteps,
    required this.todayDistanceKm,
    required this.todayCalories,
    required this.nutritionTotals,
    required this.workoutRunning,
    required this.onGoToWorkout,
    required this.onOpenNutrition,
  });

  final UserProfile user;
  final SensorSnapshot snapshot;
  final int todaySteps;
  final double todayDistanceKm;
  final double todayCalories;
  final DailyNutritionTotals nutritionTotals;
  final bool workoutRunning;
  final VoidCallback onGoToWorkout;
  final VoidCallback onOpenNutrition;

  @override
  State<EstadoTab> createState() => _EstadoTabState();
}

class _EstadoTabState extends State<EstadoTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FitPalette.surfaceDark : Colors.white;
    final border = isDark ? FitPalette.borderDark : FitPalette.borderLight;
    final unitDistance = widget.user.useImperialUnits ? 'Mi' : 'Km';
    final displayDistance = widget.user.useImperialUnits
        ? (widget.todayDistanceKm * 0.621371)
        : widget.todayDistanceKm;
    final netCalories = widget.nutritionTotals.calories - widget.todayCalories;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Encabezado compacto FITPRO
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FITPRO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Hola, ${widget.user.name} · Meta ${widget.user.stepGoal} pasos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: FitPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Contar calorías por foto',
                  onPressed: widget.onOpenNutrition,
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? FitPalette.surfaceElevatedDark
                        : FitPalette.surfaceElevatedLight,
                  ),
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  onPressed: widget.onGoToWorkout,
                  backgroundColor: widget.workoutRunning
                      ? FitPalette.green.withValues(alpha: 0.18)
                      : accent.withValues(alpha: 0.16),
                  side: BorderSide(
                    color: widget.workoutRunning ? FitPalette.green : accent,
                  ),
                  avatar: Icon(
                    widget.workoutRunning
                        ? Icons.gps_fixed
                        : Icons.play_arrow_rounded,
                    size: 16,
                    color: widget.workoutRunning ? FitPalette.green : accent,
                  ),
                  label: Text(
                    widget.workoutRunning ? 'GPS activo' : 'Deporte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.workoutRunning ? FitPalette.green : accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Anillo central de pasos con degradado electrico
            Center(
              child: StepRingGauge(
                steps: widget.todaySteps,
                goal: widget.user.stepGoal,
                accentColor: accent,
              ),
            ),
            const SizedBox(height: 16),

            // Dos tarjetas con curvas: Kcal quemadas y Distancia Km
            Row(
              children: [
                Expanded(
                  child: WaveMetricCard(
                    icon: Icons.local_fire_department_rounded,
                    iconBgColor: FitPalette.orange,
                    value: widget.todayCalories.toStringAsFixed(0),
                    unit: 'Kcal',
                    waveColor: FitPalette.orange,
                    points: widget.snapshot.accelHistory
                        .map((e) => (e / 6.0).clamp(0.1, 1.0))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WaveMetricCard(
                    icon: Icons.location_on_rounded,
                    iconBgColor: FitPalette.green,
                    value: displayDistance.toStringAsFixed(2),
                    unit: unitDistance,
                    waveColor: FitPalette.green,
                    points: widget.snapshot.gyroHistory
                        .map((e) => (e / 4.0).clamp(0.1, 1.0))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tarjeta de acceso directo a Nutricion / Comidas por foto
            InkWell(
              onTap: widget.onOpenNutrition,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nutrición y Comidas',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consumidas: ${widget.nutritionTotals.calories.toStringAsFixed(0)} kcal · Balance neto: ${netCalories.toStringAsFixed(0)} kcal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: FitPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Color(0xFF00E5FF),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Foto',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tarjeta ancha 1: Intensidad y Movimiento (Acelerometro RF-03)
            SensorChartCard(
              icon: Icons.directions_run_rounded,
              iconColor: FitPalette.heartRed,
              title: 'Intensidad y Zancada',
              subtitle:
                  'Acelerómetro triaxial · ${widget.snapshot.cadenceSpm > 0 ? '${widget.snapshot.cadenceSpm} zancadas/min' : 'Sin zancadas'}',
              value: widget.snapshot.accelMagnitude.toStringAsFixed(2),
              unit: 'm/s²',
              statusLabel: widget.snapshot.activityState,
              samples: widget.snapshot.accelHistory,
              chartTint: FitPalette.heartRed,
              available: widget.snapshot.accelerometerAvailable,
            ),
            const SizedBox(height: 14),

            // Tarjeta ancha 2: Orientacion y Postura (Giroscopio RF-04)
            SensorChartCard(
              icon: Icons.screen_rotation_alt_rounded,
              iconColor: FitPalette.sleepLavender,
              title: 'Orientación y Postura',
              subtitle:
                  'Giroscopio · Inclinación ${widget.snapshot.tiltDegrees.toStringAsFixed(0)}°',
              value: widget.snapshot.gyroMagnitude.toStringAsFixed(2),
              unit: 'rad/s',
              statusLabel: widget.snapshot.postureLabel,
              samples: widget.snapshot.gyroHistory,
              chartTint: FitPalette.sleepLavender,
              available: widget.snapshot.gyroscopeAvailable,
            ),
          ],
        ),
      ),
    );
  }
}
