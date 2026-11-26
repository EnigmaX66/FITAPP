import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/sensor_snapshot.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/workout_map_widget.dart';

/// Pestana "Deporte": Mapa GPS en tiempo real, ubicacion, trazado de ruta e historial (RF-05, RF-06).
class DeporteTab extends StatelessWidget {
  const DeporteTab({
    super.key,
    required this.user,
    required this.snapshot,
    required this.running,
    required this.activityType,
    required this.onActivityChanged,
    required this.elapsed,
    required this.workoutSteps,
    required this.distanceMeters,
    required this.speedKmh,
    required this.calories,
    required this.route,
    required this.currentLocation,
    required this.statusMessage,
    required this.history,
    required this.stats,
    required this.onToggleWorkout,
    required this.onLocateMe,
    required this.onInspectSession,
  });

  final UserProfile user;
  final SensorSnapshot snapshot;
  final bool running;
  final String activityType;
  final ValueChanged<String> onActivityChanged;
  final Duration elapsed;
  final int workoutSteps;
  final double distanceMeters;
  final double speedKmh;
  final double calories;
  final List<LatLng> route;
  final LatLng? currentLocation;
  final String statusMessage;
  final List<WorkoutSession> history;
  final AggregateStats? stats;
  final VoidCallback onToggleWorkout;
  final VoidCallback onLocateMe;
  final ValueChanged<WorkoutSession> onInspectSession;

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FitPalette.surfaceDark : Colors.white;
    final border = isDark ? FitPalette.borderDark : FitPalette.borderLight;

    final distValue = user.useImperialUnits
        ? (distanceMeters / 1609.34)
        : (distanceMeters / 1000.0);
    final distUnit = user.useImperialUnits ? 'mi' : 'km';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // Selector de modalidad deportiva
        Row(
          children: [
            const Expanded(
              child: Text(
                'Deporte y Mapa GPS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onLocateMe,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Mi ubicación'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Caminata', 'Carrera', 'Ciclismo'].map((mode) {
            final selected = activityType == mode;
            return ChoiceChip(
              label: Text(mode),
              selected: selected,
              selectedColor: accent.withValues(alpha: 0.22),
              labelStyle: TextStyle(
                color: selected ? accent : null,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(color: selected ? accent : border),
              onSelected: running ? null : (_) => onActivityChanged(mode),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Mapa interactivo GPS
        WorkoutMapWidget(
          route: route,
          currentLocation: currentLocation,
          accentColor: accent,
          height: 295,
          onLocatePressed: onLocateMe,
        ),
        const SizedBox(height: 10),

        // Barra de estado de GPS / sensores
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                running ? Icons.sensors_rounded : Icons.info_outline_rounded,
                size: 18,
                color: running ? FitPalette.green : accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Metricas en tiempo real del entrenamiento
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatPill(
                    label: 'Tiempo',
                    value: _formatDuration(elapsed),
                  ),
                  _StatPill(
                    label: 'Distancia',
                    value: '${distValue.toStringAsFixed(2)} $distUnit',
                  ),
                  _StatPill(
                    label: 'Velocidad',
                    value: '${speedKmh.toStringAsFixed(1)} km/h',
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatPill(label: 'Pasos sesión', value: '$workoutSteps'),
                  _StatPill(
                    label: 'Calorías',
                    value: '${calories.toStringAsFixed(0)} kcal',
                  ),
                  _StatPill(
                    label: 'Estado',
                    value: snapshot.activityState,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _ModernGpsActionButton(
          running: running,
          accent: accent,
          onTap: onToggleWorkout,
        ),
        const SizedBox(height: 22),

        // Resumen acumulado + historial local (RF-06)
        Row(
          children: [
            const Text(
              'Historial y Estadísticas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (stats != null)
              Text(
                '${stats!.sessionsCount} sesiones',
                style: TextStyle(fontSize: 12.5, color: FitPalette.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (stats != null && stats!.sessionsCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(
                  label: 'Total km',
                  value: (stats!.totalDistanceMeters / 1000).toStringAsFixed(2),
                ),
                _StatPill(
                  label: 'Total pasos',
                  value: '${stats!.totalSteps}',
                ),
                _StatPill(
                  label: 'Total kcal',
                  value: stats!.totalCalories.toStringAsFixed(0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Text(
              'Aún no has guardado recorridos. Presiona "Iniciar entrenamiento GPS" para registrar tu primera ruta.',
              style: TextStyle(color: FitPalette.textMuted, fontSize: 13),
            ),
          )
        else
          ...history.take(8).map(
                (s) => Card(
                  color: cardBg,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: border),
                  ),
                  child: ListTile(
                    onTap: () => onInspectSession(s),
                    leading: CircleAvatar(
                      backgroundColor: accent.withValues(alpha: 0.16),
                      child: Icon(Icons.route_rounded, color: accent),
                    ),
                    title: Text(
                      '${s.activityType} · ${(s.distanceMeters / 1000).toStringAsFixed(2)} km',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${s.steps} pasos · ${_formatDuration(s.duration)} · ${s.startedAt.day}/${s.startedAt.month}/${s.startedAt.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: FitPalette.textMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: FitPalette.textMuted),
        ),
      ],
    );
  }
}

class _ModernGpsActionButton extends StatefulWidget {
  const _ModernGpsActionButton({
    required this.running,
    required this.accent,
    required this.onTap,
  });

  final bool running;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ModernGpsActionButton> createState() => _ModernGpsActionButtonState();
}

class _ModernGpsActionButtonState extends State<_ModernGpsActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.running ? FitPalette.heartRed : widget.accent;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.running
                    ? [
                        FitPalette.heartRed.withValues(alpha: 0.92),
                        const Color(0xFFB83838),
                      ]
                    : [
                        baseColor.withValues(alpha: 0.24),
                        const Color(0xFF172133),
                      ],
              ),
              border: Border.all(
                color: baseColor.withValues(alpha: widget.running ? 0.9 : 0.72),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: _pressed ? 0.14 : 0.24),
                  blurRadius: _pressed ? 8 : 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.running
                        ? Colors.white.withValues(alpha: 0.18)
                        : baseColor.withValues(alpha: 0.22),
                  ),
                  child: Icon(
                    widget.running
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.running ? Colors.white : baseColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.running
                      ? 'Finalizar y guardar recorrido'
                      : 'Iniciar entrenamiento GPS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: widget.running ? Colors.white : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
