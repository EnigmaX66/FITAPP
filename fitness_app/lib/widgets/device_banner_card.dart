import 'package:flutter/material.dart';

/// Tarjeta superior dark-mode de la pestana Dispositivo con ilustracion nocturna.
class DeviceBannerCard extends StatelessWidget {
  const DeviceBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF263549)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF151E2C),
                Color(0xFF112634),
                Color(0xFF112A28),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _NightParkPainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            size: 19,
                            color: Color(0xFF39D96B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA9B7CB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NightParkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Silueta urbana sutil en modo oscuro
    final cityPaint = Paint()..color = const Color(0xFF1D2D42).withValues(alpha: 0.85);
    final buildings = [
      Rect.fromLTWH(size.width * 0.06, size.height * 0.56, 18, 45),
      Rect.fromLTWH(size.width * 0.12, size.height * 0.46, 22, 55),
      Rect.fromLTWH(size.width * 0.19, size.height * 0.52, 16, 50),
      Rect.fromLTWH(size.width * 0.29, size.height * 0.44, 24, 60),
      Rect.fromLTWH(size.width * 0.50, size.height * 0.50, 20, 52),
      Rect.fromLTWH(size.width * 0.63, size.height * 0.42, 26, 62),
      Rect.fromLTWH(size.width * 0.74, size.height * 0.48, 18, 56),
    ];
    for (final b in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          b,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        cityPaint,
      );
    }

    // Colinas verde/esmeralda oscuro
    final hillBack = Path()
      ..moveTo(0, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.61,
        size.width * 0.6,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.63,
        size.width,
        size.height * 0.71,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hillBack,
      Paint()..color = const Color(0xFF17453A).withValues(alpha: 0.9),
    );

    final hillFront = Path()
      ..moveTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.75,
        size.width,
        size.height * 0.82,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hillFront,
      Paint()..color = const Color(0xFF1E5E4B).withValues(alpha: 0.88),
    );

    // Ciclista con acento luminoso
    final wheelPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final cx1 = size.width * 0.69;
    final cx2 = size.width * 0.76;
    final cy = size.height * 0.88;
    canvas.drawCircle(Offset(cx1, cy), 10, wheelPaint);
    canvas.drawCircle(Offset(cx2, cy), 10, wheelPaint);

    final framePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(cx1, cy), Offset((cx1 + cx2) / 2, cy - 11), framePaint);
    canvas.drawLine(Offset((cx1 + cx2) / 2, cy - 11), Offset(cx2, cy), framePaint);
    canvas.drawCircle(
      Offset((cx1 + cx2) / 2 - 2, cy - 22),
      4,
      Paint()..color = const Color(0xFF39D96B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
