import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/constants/gradient_colors.dart';
import 'package:bankapp/presentation/widgets/astroid.dart';
import 'package:bankapp/presentation/widgets/add_transaction_bottom_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FloatingNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkBackground; // true = fond foncé, false = fond clair

  const FloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDarkBackground = true,
  });

  void _showAddTransactionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs adaptatives selon le fond
    final navbarColor = isDarkBackground
        ? AppColors.white
        : AppColors.containerBlack;
    final activeIconColor = isDarkBackground
        ? AppColors.textDark
        : AppColors.textLight;
    final inactiveIconColor = activeIconColor.withValues(alpha: 0.3);

    return Positioned(
      bottom: 80.h,
      left: 60.w,
      right: 60.w,
      child: Container(
        height: 55.h,
        decoration: BoxDecoration(
          color: navbarColor,
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icône Home
            _buildNavItem(
              iconPath: 'assets/icons/system/home.svg',
              index: 0,
              isActive: currentIndex == 0,
              activeColor: activeIconColor,
              inactiveColor: inactiveIconColor,
            ),

            // Icône App (Menu)
            _buildNavItem(
              iconPath: 'assets/icons/system/app.svg',
              index: 1,
              isActive: currentIndex == 1,
              activeColor: activeIconColor,
              inactiveColor: inactiveIconColor,
            ),

            // Icône centrale (Astroïde) - Déclencheur de la BottomSheet
            GestureDetector(
              onTap: () => _showAddTransactionBottomSheet(context),
              child: SizedBox(
                width: 50.w,
                height: 50.h,
                child: Center(
                  child: Astroid(
                    size: 30.w,
                    curvature: 0.25,
                    primaryColors: GradientColors.primaryColors,
                    secondaryColors: GradientColors.secondaryColors,
                    duration: GradientColors.animationDuration,
                  ),
                ),
              ),
            ),

            // Icône Chart (Statistiques)
            _buildNavItem(
              iconPath: 'assets/icons/system/chart.svg',
              index: 2,
              isActive: currentIndex == 2,
              activeColor: activeIconColor,
              inactiveColor: inactiveIconColor,
            ),

            // Icône Settings
            _buildNavItem(
              iconPath: 'assets/icons/system/settings.svg',
              index: 3,
              isActive: currentIndex == 3,
              activeColor: activeIconColor,
              inactiveColor: inactiveIconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required int index,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 50.w,
        height: 50.h,
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 26.sp,
            height: 26.sp,
            colorFilter: ColorFilter.mode(
              isActive ? activeColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
