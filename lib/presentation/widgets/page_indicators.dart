import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PageIndicators extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final double width;
  final double height;
  final double spacing;

  const PageIndicators({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    this.width = 27.0,
    this.height = 3.0,
    this.spacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppColorsExtended>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: spacing.w / 2),
          width: width.w,
          height: height.h,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? appTheme
                      .text4 // Actif : couleur principale
                : appTheme.text6, // Inactif : couleur secondaire
            borderRadius: BorderRadius.circular(1.r),
          ),
        ),
      ),
    );
  }
}
