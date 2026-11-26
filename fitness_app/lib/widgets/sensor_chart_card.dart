import 'dart:math';

import 'package:flutter/material.dart';

/// Tarjeta ancha con grafico en tiempo real para acelerometro y giroscopio,
/// siguiendo la estetica de las tarjetas inferiores de la captura de Estado.
class SensorChartCard extends StatelessWidget {
  const SensorChartCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.statusLabel,
    required this.samples,
    required this.chartTint,
    this.available = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final String statusLabel;
  final List<double> samples;
  final Color chartTint;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171C26) : Colors.white;
    final muted = isDark ? const Color(0xFF8B94A7) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF222938) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: chartTint.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      available ? statusLabel : 'No disponible',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: available ? chartTint : muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 82,
            width: double.infinity,
            decoration: BoxDecoration(
              color: chartTint.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: _SparkAreaPainter(
                samples: samples,
                color: chartTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkAreaPainter extends CustomPainter {
  _SparkAreaPainter({required this.samples, required this.color});

  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final maxVal = max(1.0, samples.reduce(max));
    final stepX = size.width / (samples.length - 1);

    final coords = <Offset>[];
    for (var i = 0; i < samples.length; i++) {
      final x = i * stepX;
      final norm = (samples[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height - 12 - norm * (size.height - 24);
      coords.add(Offset(x, y));
    }

    // Curvas cubicas organicas y suaves entre puntos
    final line = Path()..moveTo(coords.first.dx, coords.first.dy);
    final fill = Path()
      ..moveTo(0, size.height)
      ..lineTo(coords.first.dx, coords.first.dy);

    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      line.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      fill.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    fill
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.44),
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkAreaPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.color != color;
}
