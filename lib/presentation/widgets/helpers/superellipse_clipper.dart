import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clipper superellipse (squircle complet dans le cadre du rect)
/// n = 2  -> ellipse/cercle
/// n ≈ 3-6 -> squircle doux (4 est un bon point de départ)
class SuperellipseClipper extends CustomClipper<Path> {
  final double n; // exponent (>= 2.0)
  final int steps; // nombres de segments (plus = plus lisse)

  SuperellipseClipper({this.n = 4.0, this.steps = 256})
    : assert(n >= 2.0),
      assert(steps >= 16);

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    return _superellipsePath(rect, n, steps);
  }

  @override
  bool shouldReclip(covariant SuperellipseClipper oldClipper) {
    return oldClipper.n != n || oldClipper.steps != steps;
  }
}

/// Construit un path de superellipse qui occupe entièrement [rect].
Path _superellipsePath(Rect rect, double n, int steps) {
  final cx = rect.center.dx;
  final cy = rect.center.dy;
  final a = rect.width / 2; // demi-largeur
  final b = rect.height / 2; // demi-hauteur

  // Paramétrisation standard :
  // x(t) = a * sign(cos t) * |cos t|^(2/n)
  // y(t) = b * sign(sin t) * |sin t|^(2/n)
  // t ∈ [0, 2π]
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
