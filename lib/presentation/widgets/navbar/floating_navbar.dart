import 'package:bankapp/core/constants/gradient_colors.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/presentation/widgets/bottom_sheets/add_transaction_bottom_sheet.dart';
import 'package:bankapp/presentation/widgets/navbar/astroid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingNavbar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkBackground; // true = fond foncé, false = fond clair

  const FloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isDarkBackground = true,
  });

  void _showAddTransactionBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const AddTransactionBottomSheet(),
    ).then((_) {
      // Les ViewModels MVVM avec Event Bus gèrent automatiquement la réactivité
      // Plus besoin d'invalidation manuelle
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Couleurs adaptatives selon le fond
    final navbarColor = isDarkBackground
        ? AppColors.surfaceBrightLight
        : AppColors.surfaceBrightDark;
    final activeIconColor = isDarkBackground
        ? AppColors.textDark100
        : AppColors.textLight100;
    final inactiveIconColor = activeIconColor.withValues(alpha: 0.2);

    return Positioned(
      bottom: 80.h,
      left: 65.w,
      right: 65.w,
      child: Container(
        height: 55,
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
              onTap: () => _showAddTransactionBottomSheet(context, ref),
              child: SizedBox(
                width: 50.w,
                height: 50.w,
                child: Center(
                  child: Astroid(
                    size: 32,
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
        height: 50.w,
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 28.sp,
            height: 28.sp,
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
