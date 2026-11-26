import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa interactivo OpenStreetMap con trazado de ruta, marcador en vivo y centrado.
class WorkoutMapWidget extends StatefulWidget {
  const WorkoutMapWidget({
    super.key,
    required this.route,
    this.currentLocation,
    required this.accentColor,
    this.height = 310,
    this.onLocatePressed,
  });

  final List<LatLng> route;
  final LatLng? currentLocation;
  final Color accentColor;
  final double height;
  final VoidCallback? onLocatePressed;

  @override
  State<WorkoutMapWidget> createState() => _WorkoutMapWidgetState();
}

class _WorkoutMapWidgetState extends State<WorkoutMapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant WorkoutMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPoint = widget.route.isNotEmpty
        ? widget.route.last
        : widget.currentLocation;
    final prevPoint = oldWidget.route.isNotEmpty
        ? oldWidget.route.last
        : oldWidget.currentLocation;

    if (nextPoint != null && nextPoint != prevPoint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(nextPoint, 16.5);
        } catch (_) {}
      });
    }
  }

  void _recenter() {
    final target = widget.route.isNotEmpty
        ? widget.route.last
        : widget.currentLocation;
    if (target != null) {
      try {
        _mapController.move(target, 16.5);
      } catch (_) {}
    }
    widget.onLocatePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activePoint = widget.route.isNotEmpty
        ? widget.route.last
        : widget.currentLocation;
    // Fallback geografico: UPFIM Hidalgo, Mexico si aun no hay senal GPS.
    final center = activePoint ?? const LatLng(20.2279, -99.0928);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: activePoint == null ? 13.0 : 16.5,
                backgroundColor: const Color(0xFF0D131E),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'mx.edu.upfim.fitness_app',
                  tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                    // Matriz dark-mode azul oscuro para integrar el mapa con FIT_PRO.
                    colorFilter: const ColorFilter.matrix([
                      -0.85, 0.0, 0.0, 0.0, 225.0,
                      0.0, -0.82, 0.0, 0.0, 232.0,
                      0.0, 0.0, -0.70, 0.0, 245.0,
                      0.0, 0.0, 0.0, 1.0, 0.0,
                    ]),
                    child: tileWidget,
                  ),
                ),
                if (widget.route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.route,
                        strokeWidth: 5.5,
                        color: widget.accentColor,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (widget.route.isNotEmpty)
                      Marker(
                        point: widget.route.first,
                        width: 34,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF39D96B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if (activePoint != null)
                      Marker(
                        point: activePoint,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.accentColor.withValues(alpha: 0.25),
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.accentColor,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Coordenadas en tiempo real arriba a la izquierda
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F131B).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF283042)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activePoint != null
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      size: 15,
                      color: activePoint != null
                          ? const Color(0xFF39D96B)
                          : const Color(0xFFF5B731),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activePoint != null
                          ? '${activePoint.latitude.toStringAsFixed(5)}, ${activePoint.longitude.toStringAsFixed(5)}'
                          : 'Buscando ubicación GPS...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Boton de centrar ubicacion
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'recenter_map_fab',
                onPressed: _recenter,
                backgroundColor: const Color(0xFF151A23),
                foregroundColor: widget.accentColor,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
