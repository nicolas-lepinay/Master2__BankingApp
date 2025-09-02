import 'package:bankapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  // Font families
  static const String defaultFontFamily = 'Outfit'; // Police primaire
  static const String pacificoFontFamily = 'Pacifico';
  static const String overpassMonoFontFamily = 'OverpassMono';
  static const String playfairFontFamily = 'Playfair';
  static const String robotoFontFamily = 'Roboto';

  // V2 Design System Text Styles

  // Welcome message avec Pacifico
  static TextStyle welcomeMessage = TextStyle(
    fontFamily: pacificoFontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark100,
  );

  // Card account name avec Outfit
  static TextStyle cardAccountName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.textLight100,
  );

  // Card account name avec Outfit (Dark)
  static TextStyle cardAccountNameDark = cardAccountName.copyWith(
    color: AppColors.textDark100,
  );

  // Card balance label
  static TextStyle cardBalanceLabel = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight100,
    letterSpacing: 1.2,
  );

  // Card balance amount avec Overpass Mono
  static TextStyle cardBalanceAmount = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 26.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight100,
  );

  // Card balance amount avec Overpass Mono (Dark)
  static TextStyle cardBalanceAmountDark = cardBalanceAmount.copyWith(
    color: AppColors.textDark100,
  );

  // Card balance real amount (smaller)
  static TextStyle cardBalanceRealAmount = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight100,
  );

  // Card balance real amount (smaller) (Dark)
  static TextStyle cardBalanceRealAmountDark = cardBalanceRealAmount.copyWith(
    color: AppColors.textDark100,
  );

  // Section headers avec Playfair
  static TextStyle sectionHeader = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w400,
  );

  // Section headers medium
  static TextStyle sectionHeaderMedium = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
  );

  // Transaction amounts (format spécial sans décimales si entier)
  static TextStyle transactionAmountLarge = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  static TextStyle transactionAmountMedium = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction amount for perspective list
  static TextStyle transactionAmountPerspective = TextStyle(
    fontFamily: robotoFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction name/counterparty in perspective list
  static TextStyle transactionNamePerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark50,
  );

  // Transaction category in perspective list
  static TextStyle transactionCategoryPerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark25,
  );

  // Followed transactions styles
  static TextStyle followedTransactionName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight100,
  );

  static TextStyle followedTransactionDate = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle followedTransactionAmount = TextStyle(
    fontFamily: robotoFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight100,
  );

  static TextStyle h1 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static TextStyle h2 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 28.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static TextStyle h3 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle h4 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle h5 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle h6 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle bodyLarge = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Styles spécialisés V1 (mis à jour avec nouvelles polices)
  static TextStyle accountName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  static TextStyle accountBalance = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurfaceDark,
  );

  static TextStyle transactionTitle = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle transactionDescription = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
  );

  static TextStyle dateHeader = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w400,
  );

  static TextStyle buttonTextSmall = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w300,
  );

  // Search bar placeholder text
  static TextStyle searchPlaceholder = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.4,
    height: 1.2,
  );
}
