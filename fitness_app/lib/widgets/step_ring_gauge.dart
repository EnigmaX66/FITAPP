import 'dart:math';

import 'package:flutter/material.dart';

/// Indicador circular de pasos estilo reloj deportivo con marcas radiales,
/// porcentajes y arco de progreso con degradado electrico.
class StepRingGauge extends StatelessWidget {
  const StepRingGauge({
    super.key,
    required this.steps,
    required this.goal,
    required this.accentColor,
  });

  final int steps;
  final int goal;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final innerBg = isDark ? const Color(0xFF1A202C) : const Color(0xFFEDF1F7);
    final ringTrack =
        isDark ? const Color(0xFF131822) : const Color(0xFFE2E8F0);
    final labelColor =
        isDark ? const Color(0xFF8B94A7) : const Color(0xFF64748B);

    return SizedBox(
      width: 248,
      height: 248,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(248, 248),
            painter: _StepRingPainter(
              progress: progress,
              accentColor: accentColor,
              ringTrack: ringTrack,
              tickColor: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.14),
            ),
          ),
          // Etiquetas cardinales
          Positioned(
            top: 32,
            child: Text('0%', style: TextStyle(fontSize: 11, color: labelColor)),
          ),
          Positioned(
            right: 26,
            child: Text('25%', style: TextStyle(fontSize: 11, color: labelColor)),
          ),
          Positioned(
            bottom: 32,
            child: Text('50%', style: TextStyle(fontSize: 11, color: labelColor)),
          ),
          Positioned(
            left: 26,
            child: Text('75%', style: TextStyle(fontSize: 11, color: labelColor)),
          ),
          // Circulo central
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: innerBg,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_run_rounded,
                  color: Color(0xFF00E5FF),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '$steps',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pasos',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRingPainter extends CustomPainter {
  _StepRingPainter({
    required this.progress,
    required this.accentColor,
    required this.ringTrack,
    required this.tickColor,
  });

  final double progress;
  final Color accentColor;
  final Color ringTrack;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;

    // 1. Marcas radiales exteriores
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const tickCount = 96;
    for (var i = 0; i < tickCount; i++) {
      final angle = (2 * pi * i) / tickCount - pi / 2;
      final p1 = Offset(
        center.dx + (outerRadius - 9) * cos(angle),
        center.dy + (outerRadius - 9) * sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 2. Pista oscura intermedia
    final trackRadius = outerRadius - 28;
    final trackPaint = Paint()
      ..color = ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    canvas.drawCircle(center, trackRadius, trackPaint);

    // Pista base sutil para el arco
    final arcRadius = trackRadius + 8;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    canvas.drawArc(
      arcRect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = const Color(0xFF232C3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    // 3. Arco de progreso con degradado (azul electrico -> cyan -> morado)
    if (progress > 0) {
      final sweep = max(0.06, 2 * pi * progress);
      final gradient = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        colors: [
          const Color(0xFF3B9EFF),
          const Color(0xFF00E5FF),
          const Color(0xFF8B5CF6),
          accentColor,
          const Color(0xFF3B9EFF),
        ],
        stops: const [0.0, 0.35, 0.7, 0.9, 1.0],
        transform: const GradientRotation(-pi / 2),
      );

      // Resplandor suave
      canvas.drawArc(
        arcRect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..shader = gradient.createShader(arcRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      canvas.drawArc(
        arcRect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..shader = gradient.createShader(arcRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }

    // 4. Cuatro puntos en diagonales
    final dotPaint = Paint()..color = const Color(0xFF3B9EFF);
    final dotRadius = trackRadius - 6;
    for (final deg in [45.0, 135.0, 225.0, 315.0]) {
      final rad = deg * pi / 180;
      final pt = Offset(
        center.dx + dotRadius * cos(rad),
        center.dy + dotRadius * sin(rad),
      );
      canvas.drawCircle(pt, 3.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.ringTrack != ringTrack;
}
