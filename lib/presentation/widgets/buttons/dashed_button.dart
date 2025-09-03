import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashedButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final TextStyle? textStyle;
  final Color dashColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final double verticalPadding;
  final double horizontalPadding;

  const DashedButton({
    super.key,
    this.text,
    this.icon,
    this.textStyle,
    this.dashColor = AppColors.defaultGray,
    this.onTap,
    this.width,
    this.height = 60.0,
    this.borderRadius = 22.0,
    this.dashWidth = 7.0,
    this.dashSpace = 6.0,
    this.strokeWidth = 2.0,
    this.verticalPadding = AppConstants.mediumPadding,
    this.horizontalPadding = AppConstants.largePadding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: dashColor,
            strokeWidth: strokeWidth.w,
            dashWidth: dashWidth.w,
            dashSpace: dashSpace.w,
            borderRadius: borderRadius.r,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding.w,
              vertical: verticalPadding.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (text != null) ...[
                  Expanded(
                    child: Text(
                      text!,
                      style: AppTextStyles.buttonTextLarge.copyWith(
                        color: dashColor,
                        fontWeight:
                            (textStyle?.fontWeight ??
                            AppTextStyles.buttonTextLarge.fontWeight),
                        fontSize:
                            (textStyle?.fontSize ??
                                    AppTextStyles.buttonTextLarge.fontSize)!
                                .sp,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
                if (icon != null) ...[
                  if (text != null) SizedBox(width: 12.w),
                  Icon(
                    icon,
                    color: dashColor,
                    size:
                        ((textStyle?.fontSize ??
                                    AppTextStyles.buttonTextLarge.fontSize)! *
                                1.4)
                            .sp,
                  ),
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
