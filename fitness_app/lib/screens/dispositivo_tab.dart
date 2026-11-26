import 'package:flutter/material.dart';

import '../models/sensor_snapshot.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/device_banner_card.dart';

/// Pestana "Dispositivo": replica la vista de configuracion de dispositivo y diagnostico de sensores.
class DispositivoTab extends StatelessWidget {
  const DispositivoTab({
    super.key,
    required this.user,
    required this.snapshot,
    required this.onUpdateUser,
  });

  final UserProfile user;
  final SensorSnapshot snapshot;
  final ValueChanged<UserProfile> onUpdateUser;

  void _showSensorDiagnostics(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnóstico de Hardware FITPRO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _SensorStatusRow(
              name: 'Podómetro (STEP_COUNTER)',
              ok: snapshot.pedometerAvailable,
              detail: '${snapshot.steps} pasos detectados',
            ),
            _SensorStatusRow(
              name: 'Acelerómetro (ACCELEROMETER)',
              ok: snapshot.accelerometerAvailable,
              detail:
                  'X:${snapshot.accelX.toStringAsFixed(1)} Y:${snapshot.accelY.toStringAsFixed(1)} Z:${snapshot.accelZ.toStringAsFixed(1)}',
            ),
            _SensorStatusRow(
              name: 'Giroscopio (GYROSCOPE)',
              ok: snapshot.gyroscopeAvailable,
              detail:
                  '${snapshot.gyroMagnitude.toStringAsFixed(2)} rad/s · ${snapshot.postureLabel}',
            ),
            _SensorStatusRow(
              name: 'GPS (Location API)',
              ok: snapshot.gpsAvailable,
              detail: snapshot.gpsAvailable
                  ? 'Disponible para trazado en mapa'
                  : 'Pendiente de señal o permiso',
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? FitPalette.surfaceDark : Colors.white;
    final border = isDark ? FitPalette.borderDark : FitPalette.borderLight;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        DeviceBannerCard(
          title: 'Añadir dispositivo',
          subtitle: 'Empieza una nueva vida con los deportes inteligentes',
          onTap: () => _showSensorDiagnostics(context),
        ),
        const SizedBox(height: 14),

        // Grupo 1
        _SettingsCardGroup(
          cardBg: cardBg,
          border: border,
          children: [
            _DeviceTile(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: FitPalette.teal,
              title: 'Notificación de mensajes',
              trailingText: user.notificationsEnabled ? 'Activas' : 'Pausadas',
              onTap: () => onUpdateUser(
                user.copyWith(notificationsEnabled: !user.notificationsEnabled),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grupo 2
        _SettingsCardGroup(
          cardBg: cardBg,
          border: border,
          children: [
            _DeviceTile(
              icon: Icons.alarm_rounded,
              iconColor: FitPalette.blue,
              title: 'Alarma',
              trailingText: '07:00 AM',
              onTap: () => _showSimpleDialog(
                context,
                'Alarma inteligente FITPRO',
                'Recordatorio diario programado a las 07:00 AM para iniciar tu actividad física.',
              ),
            ),
            _DeviceTile(
              icon: Icons.accessibility_new_rounded,
              iconColor: FitPalette.teal,
              title: 'Recordatorio Sedentario',
              trailingText: user.sedentaryReminder ? 'Activo' : 'Inactivo',
              onTap: () => onUpdateUser(
                user.copyWith(sedentaryReminder: !user.sedentaryReminder),
              ),
            ),
            _DeviceTile(
              icon: Icons.straighten_rounded,
              iconColor: const Color(0xFF26C6DA),
              title: 'Configuración de la unidad',
              trailingText: user.useImperialUnits ? 'Mi / Lb' : 'Km / Kg',
              onTap: () => onUpdateUser(
                user.copyWith(useImperialUnits: !user.useImperialUnits),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grupo 3
        _SettingsCardGroup(
          cardBg: cardBg,
          border: border,
          children: [
            _DeviceTile(
              icon: Icons.vibration_rounded,
              iconColor: FitPalette.green,
              title: 'Choque y sensores físicos',
              trailingText: snapshot.isMoving ? 'Activo' : 'En espera',
              onTap: () => _showSensorDiagnostics(context),
            ),
            _DeviceTile(
              icon: Icons.wb_sunny_outlined,
              iconColor: FitPalette.teal,
              title: 'Luz de fondo y batería',
              trailingText: 'Eco 120ms',
              onTap: () => _showSimpleDialog(
                context,
                'Optimización de energía (RNF-01)',
                'FITPRO regula la lectura del acelerómetro y giroscopio a 120 ms '
                    'y cancela todos los listeners cuando sales o pausas la aplicación.',
              ),
            ),
            _DeviceTile(
              icon: Icons.screen_rotation_rounded,
              iconColor: FitPalette.pink,
              title: 'Activación de pantalla con giro de muñeca',
              trailingText: user.wristWakeEnabled ? 'Sí' : 'No',
              onTap: () => onUpdateUser(
                user.copyWith(wristWakeEnabled: !user.wristWakeEnabled),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grupo 4
        _SettingsCardGroup(
          cardBg: cardBg,
          border: border,
          children: [
            _DeviceTile(
              icon: Icons.cloud_upload_outlined,
              iconColor: FitPalette.orange,
              title: 'Actualización del firmware',
              trailingText: 'v1.0.0 PRO',
              onTap: () => _showSimpleDialog(
                context,
                'FITPRO Firmware & Módulos',
                'Versión instalada: FITPRO v1.0.0 (UPFIM 4TIG1).\n'
                    'Todos los módulos de biometría, sensores y GPS están actualizados.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsCardGroup extends StatelessWidget {
  const _SettingsCardGroup({
    required this.cardBg,
    required this.border,
    required this.children,
  });

  final Color cardBg;
  final Color border;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: 60, color: border),
          ],
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: iconColor,
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: TextStyle(fontSize: 12, color: FitPalette.textMuted),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: FitPalette.textMuted),
        ],
      ),
    );
  }
}

class _SensorStatusRow extends StatelessWidget {
  const _SensorStatusRow({
    required this.name,
    required this.ok,
    required this.detail,
  });

  final String name;
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: ok ? FitPalette.green : FitPalette.yellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: FitPalette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
