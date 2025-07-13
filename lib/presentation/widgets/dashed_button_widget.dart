import 'package:flutter/material.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashedButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  final String? text;
  final IconData? icon;

  const DashedButtonWidget({
    super.key,
    required this.onTap,
    this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(),
        child: Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.containerDarkGray, size: 24.sp),
                SizedBox(width: 12.w),
              ],
              if (text != null)
                Text(
                  text!,
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.containerDarkGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.containerDarkGray
      ..strokeWidth = 2.w
      ..style = PaintingStyle.stroke;

    final double dashWidth = 8.0.w;
    final double dashSpace = 4.0.w;
    double startX = 0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(16.r),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
