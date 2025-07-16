import 'dart:math' as math;

import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdjustableStarPainter extends CustomPainter {
  final Color color;
  final double curvature; // 0.0 = carré, 1.0 = très courbé
  final Gradient? gradient; // Nouveau paramètre pour le dégradé

  AdjustableStarPainter({
    this.color = Colors.black,
    this.curvature = 0.3,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Utiliser le dégradé si disponible, sinon la couleur solide
    if (gradient != null) {
      paint.shader = gradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else {
      paint.color = color;
    }

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Calculer l'intensité de la courbure
    final curveIntensity = radius * curvature;

    // Point de départ (haut)
    path.moveTo(center.dx, center.dy - radius);

    // Courbe vers la droite
    path.quadraticBezierTo(
      center.dx + curveIntensity,
      center.dy - curveIntensity,
      center.dx + radius,
      center.dy,
    );

    // Courbe vers le bas
    path.quadraticBezierTo(
      center.dx + curveIntensity,
      center.dy + curveIntensity,
      center.dx,
      center.dy + radius,
    );

    // Courbe vers la gauche
    path.quadraticBezierTo(
      center.dx - curveIntensity,
      center.dy + curveIntensity,
      center.dx - radius,
      center.dy,
    );

    // Courbe vers le haut pour fermer
    path.quadraticBezierTo(
      center.dx - curveIntensity,
      center.dy - curveIntensity,
      center.dx,
      center.dy - radius,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AdjustableStarPainter &&
        (oldDelegate.color != color ||
            oldDelegate.curvature != curvature ||
            oldDelegate.gradient != gradient);
  }
}

class AdjustableStarWidget extends StatelessWidget {
  final double size;
  final Color color;
  final double curvature;
  final Gradient? gradient; // Nouveau paramètre

  const AdjustableStarWidget({
    Key? key,
    this.size = 100.0,
    this.color = Colors.black,
    this.curvature = 0.3,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size.w, size.h),
      painter: AdjustableStarPainter(
        color: color,
        curvature: curvature,
        gradient: gradient,
      ),
    );
  }
}

// Widget avec dégradé animé
class Astroid extends StatelessWidget {
  final double size;
  final double curvature;
  final List<Color> primaryColors;
  final List<Color> secondaryColors;
  final Duration duration;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const Astroid({
    super.key,
    this.size = 100.0,
    this.curvature = 0.25,
    this.primaryColors = const [Colors.pink, Colors.pinkAccent, Colors.white],
    this.secondaryColors = const [Colors.blue, Colors.blueAccent, Colors.white],
    this.duration = const Duration(seconds: 5),
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: StarClipper(curvature: curvature),
      child: SizedBox(
        width: size.w,
        height: size.h,
        child: AnimateGradient(
          primaryColors: primaryColors,
          secondaryColors: secondaryColors,
          duration: duration,
          child: Container(),
        ),
      ),
    );
  }
}

// Clipper pour utiliser avec AnimateGradient
class StarClipper extends CustomClipper<Path> {
  final double curvature;

  StarClipper({this.curvature = 0.3});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final curveIntensity = radius * curvature;

    path.moveTo(center.dx, center.dy - radius);

    path.quadraticBezierTo(
      center.dx + curveIntensity,
      center.dy - curveIntensity,
      center.dx + radius,
      center.dy,
    );

    path.quadraticBezierTo(
      center.dx + curveIntensity,
      center.dy + curveIntensity,
      center.dx,
      center.dy + radius,
    );

    path.quadraticBezierTo(
      center.dx - curveIntensity,
      center.dy + curveIntensity,
      center.dx - radius,
      center.dy,
    );

    path.quadraticBezierTo(
      center.dx - curveIntensity,
      center.dy - curveIntensity,
      center.dx,
      center.dy - radius,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is StarClipper && oldClipper.curvature != curvature;
  }
}
