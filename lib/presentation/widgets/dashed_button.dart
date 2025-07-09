import 'package:flutter/material.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:bankapp/core/constants/app_constants.dart';

class DashedButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color dashColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const DashedButton({
    super.key,
    this.text,
    this.icon,
    this.dashColor = AppColors.dark,
    this.onTap,
    this.width,
    this.height = 60,
    this.borderRadius = 22,
    this.dashWidth = 7,
    this.dashSpace = 6,
    this.strokeWidth = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        //height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: dashColor,
            strokeWidth: strokeWidth,
            dashWidth: dashWidth,
            dashSpace: dashSpace,
            borderRadius: borderRadius,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
              vertical: AppConstants.mediumPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (text != null) ...[
                  Expanded(
                    child: Text(
                      text!,
                      style: AppTextStyles.buttonText.copyWith(
                        color: dashColor,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
                if (icon != null) ...[
                  if (text != null) const SizedBox(width: 12),
                  Icon(icon, color: dashColor, size: 26),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;

      while (distance < pathMetric.length) {
        final double length = draw ? dashWidth : dashSpace;
        final double endDistance = distance + length;

        if (draw) {
          final extractPath = pathMetric.extractPath(
            distance,
            endDistance > pathMetric.length ? pathMetric.length : endDistance,
          );
          canvas.drawPath(extractPath, paint);
        }

        distance = endDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
