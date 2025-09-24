import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'superellipse_clipper.dart';

/// Widget pour créer un squircle avec bordure optionnelle
///
/// Combine le SuperellipseClipper existant avec un CustomPainter
/// pour dessiner la bordure selon la même forme mathématique
class BorderedSquircle extends StatelessWidget {
  final Widget child;
  final double n;
  final int steps;
  final Color? backgroundColor;
  final BorderSide? border;

  const BorderedSquircle({
    super.key,
    required this.child,
    this.n = 2.9,
    this.steps = 256,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: border != null
          ? _SuperellipseBorderPainter(
              n: n,
              steps: steps,
              borderSide: border!,
            )
          : null,
      child: ClipPath(
        clipper: SuperellipseClipper(n: n, steps: steps),
        child: Container(
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }
}

/// CustomPainter pour dessiner la bordure du squircle
class _SuperellipseBorderPainter extends CustomPainter {
  final double n;
  final int steps;
  final BorderSide borderSide;

  const _SuperellipseBorderPainter({
    required this.n,
    required this.steps,
    required this.borderSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderSide.color
      ..strokeWidth = borderSide.width
      ..style = PaintingStyle.stroke;

    // Utiliser la même logique mathématique que SuperellipseClipper
    final rect = Offset.zero & size;
    final path = _createSuperellipsePath(rect, n, steps);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SuperellipseBorderPainter oldDelegate) {
    return oldDelegate.n != n ||
           oldDelegate.steps != steps ||
           oldDelegate.borderSide != borderSide;
  }

  /// Construit un path de superellipse identique à SuperellipseClipper
  Path _createSuperellipsePath(Rect rect, double n, int steps) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final a = rect.width / 2; // demi-largeur
    final b = rect.height / 2; // demi-hauteur

    // Même paramétrisation que SuperellipseClipper
    double sgn(double v) => v < 0 ? -1 : 1;

    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;
      final ct = math.cos(t);
      final st = math.sin(t);

      final x = a * sgn(ct) * math.pow(ct.abs(), 2.0 / n);
      final y = b * sgn(st) * math.pow(st.abs(), 2.0 / n);

      final px = cx + x;
      final py = cy + y;

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }
}