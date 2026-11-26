import 'package:flutter/material.dart';

/// Tarjeta compacta con icono circular, valor principal y curva decorativa inferior.
class WaveMetricCard extends StatelessWidget {
  const WaveMetricCard({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.value,
    required this.unit,
    required this.waveColor,
    required this.points,
  });

  final IconData icon;
  final Color iconBgColor;
  final String value;
  final String unit;
  final Color waveColor;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF171C26) : Colors.white;
    final muted = isDark ? const Color(0xFF8B94A7) : const Color(0xFF64748B);

    return Container(
      height: 126,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF222938) : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Curva inferior con gradiente sutil
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveCurvePainter(
                waveColor: waveColor,
                points: points,
                isDark: isDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: muted,
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

class _WaveCurvePainter extends CustomPainter {
  _WaveCurvePainter({
    required this.waveColor,
    required this.points,
    required this.isDark,
  });

  final Color waveColor;
  final List<double> points;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Domo suave de fondo como en el diseno original
    final domePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.34,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..close();

    final domePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height));
    canvas.drawPath(domePath, domePaint);

    final safePoints = points.length >= 2
        ? points
        : const [0.2, 0.55, 0.42, 0.78, 0.5, 0.85, 0.45];

    final path = Path();
    final stepX = size.width / (safePoints.length - 1);
    final baseY = size.height * 0.88;
    final ampY = size.height * 0.28;

    final coords = <Offset>[];
    for (var i = 0; i < safePoints.length; i++) {
      final norm = safePoints[i].clamp(0.0, 1.0);
      coords.add(Offset(i * stepX, baseY - norm * ampY));
    }

    path.moveTo(coords.first.dx, coords.first.dy);
    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Punto destacado en la curva
    final highlightIdx = (coords.length * 0.6).floor().clamp(0, coords.length - 1);
    final pt = coords[highlightIdx];
    canvas.drawCircle(
      pt,
      5.2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      pt,
      3.5,
      Paint()..color = waveColor,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveCurvePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor || oldDelegate.points != points;
}
