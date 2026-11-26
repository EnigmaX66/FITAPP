import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionOverview {
  const PermissionOverview({
    required this.locationStatus,
    required this.activityStatus,
    required this.gpsServiceEnabled,
  });

  final PermissionStatus locationStatus;
  final PermissionStatus activityStatus;
  final bool gpsServiceEnabled;

  bool get allWorkoutPermissionsGranted =>
      locationStatus.isGranted && activityStatus.isGranted && gpsServiceEnabled;
}

/// Gestiona permisos en tiempo de ejecucion con dialogos informativos (RNF-02).
class PermissionsService {
  Future<PermissionOverview> getOverview() async {
    PermissionStatus loc = PermissionStatus.denied;
    PermissionStatus act = PermissionStatus.denied;
    bool gps = false;
    try {
      loc = await Permission.locationWhenInUse.status;
      act = await Permission.activityRecognition.status;
      gps = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      // Fallback defensivo en plataformas sin plugin nativo (e.g. tests).
    }
    return PermissionOverview(
      locationStatus: loc,
      activityStatus: act,
      gpsServiceEnabled: gps,
    );
  }

  Future<bool> requestWorkoutPermissions(BuildContext context) async {
    final current = await getOverview();
    if (current.allWorkoutPermissionsGranted) return true;

    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFFF6B1A)),
            SizedBox(width: 10),
            Expanded(child: Text('Permisos de FITPRO')),
          ],
        ),
        content: const Text(
          'Para rastrear tu ruta en el mapa, medir velocidad/distancia con GPS '
          'y contar tus pasos con el podómetro del dispositivo, FITPRO necesita:\n\n'
          '• Ubicación en uso (GPS)\n'
          '• Actividad física (Podómetro y movimiento)\n\n'
          'Tus datos se guardan solo de forma local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conceder permisos'),
          ),
        ],
      ),
    );

    if (proceed != true) return false;

    final results = await [
      Permission.locationWhenInUse,
      Permission.activityRecognition,
    ].request();

    final locStatus =
        results[Permission.locationWhenInUse] ?? PermissionStatus.denied;
    final actStatus =
        results[Permission.activityRecognition] ?? PermissionStatus.denied;

    if (locStatus.isPermanentlyDenied || actStatus.isPermanentlyDenied) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permiso bloqueado'),
            content: const Text(
              'Uno de los permisos fue denegado permanentemente. '
              'Ábrelo manualmente desde Ajustes de la aplicación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Abrir Ajustes'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    if (!locStatus.isGranted || !actStatus.isGranted) {
      return false;
    }

    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('GPS desactivado'),
          content: const Text(
            'El servicio de ubicación (GPS) del teléfono está apagado. '
            'Actívalo para ver tu ubicación y trazar la ruta en el mapa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openLocationSettings();
              },
              child: const Text('Activar GPS'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Future<bool> requestLocationOnly(BuildContext context) async {
    final loc = await Permission.locationWhenInUse.status;
    if (!loc.isGranted) {
      if (!context.mounted) return false;
      final res = await Permission.locationWhenInUse.request();
      if (!res.isGranted) return false;
    }
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled && context.mounted) {
      await Geolocator.openLocationSettings();
      return await Geolocator.isLocationServiceEnabled();
    }
    return gpsEnabled;
  }
}
