import 'package:bankapp/core/constants/app_constants.dart';
import 'package:bankapp/core/theme/app_colors.dart';
import 'package:bankapp/core/theme/app_colors_extended.dart';
import 'package:bankapp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsExtended.light.text5!, // Cursor color
        selectionHandleColor:
            AppColorsExtended.light.text6!, // Selection handle color
        selectionColor: AppColors.primaryGreen.withValues(
          alpha: 0.5,
        ), // Text selection color
      ),
      brightness: Brightness.light,
      // Ajout de votre thème personnalisé
      extensions: const <ThemeExtension<dynamic>>[AppColorsExtended.light],
      // Color scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        onPrimary: AppColors.onSurfaceDark,
        onSecondary: AppColors.onSurfaceLight,
        onError: AppColors.onSurfaceDark,
        surface:
            AppColorsExtended.light.background2!, // Default Scaffold background
        onSurface: AppColorsExtended.light.text1!,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColorsExtended.light.background2!,
        foregroundColor: AppColorsExtended.light.text2!,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h5,
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        color: AppColorsExtended.light.background1!,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsExtended.light.background2!,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColorsExtended.light.background3!,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsExtended.light.buttonBackground1!,
          foregroundColor: AppColorsExtended.light.buttonForeground1!,
          disabledBackgroundColor:
              AppColorsExtended.light.buttonBackgroundDisabled!,
          disabledForegroundColor:
              AppColorsExtended.light.buttonForegroundDisabled!,
          textStyle: AppTextStyles.buttonTextLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 34.sp, vertical: 20.sp),
          elevation: 0,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h4,
        headlineMedium: AppTextStyles.h5,
        headlineSmall: AppTextStyles.h6,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsExtended.light.buttonBackground1!,
        foregroundColor: AppColorsExtended.light.buttonForeground1!,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColorsExtended.light.text5!, // Cursor color
        selectionHandleColor:
            AppColorsExtended.light.text6!, // Selection handle color
        selectionColor: AppColors.primaryGreen.withValues(
          alpha: 0.5,
        ), // Text selection color
      ),
      extensions: const <ThemeExtension<dynamic>>[AppColorsExtended.dark],
      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        onPrimary: AppColors.onSurfaceDark,
        onSecondary: AppColors.onSurfaceLight,
        onError: AppColors.onSurfaceDark,
        surface:
            AppColorsExtended.dark.background2!, // Default Scaffold background
        onSurface: AppColorsExtended.dark.text1!,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColorsExtended.dark.background2!,
        foregroundColor: AppColorsExtended.dark.text2!,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.h5,
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        color: AppColorsExtended.dark.background1!,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsExtended.dark.background2!,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColorsExtended.dark.background3!,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsExtended.dark.buttonBackground1!,
          foregroundColor: AppColorsExtended.dark.buttonForeground1!,
          disabledBackgroundColor:
              AppColorsExtended.dark.buttonBackgroundDisabled!,
          disabledForegroundColor:
              AppColorsExtended.dark.buttonForegroundDisabled!,
          textStyle: AppTextStyles.buttonTextLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 20.sp),
          elevation: 0,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineLarge: AppTextStyles.h4,
        headlineMedium: AppTextStyles.h5,
        headlineSmall: AppTextStyles.h6,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorsExtended.dark.buttonBackground1!,
        foregroundColor: AppColorsExtended.dark.buttonForeground1!,
      ),
    );
  }
}
