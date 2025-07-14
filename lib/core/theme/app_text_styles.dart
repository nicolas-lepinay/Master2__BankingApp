import 'package:flutter/material.dart';
import 'package:bankapp/core/theme/app_colors.dart';

class AppTextStyles {
  // Font families
  static const String defaultFontFamily = 'Outfit'; // Police primaire
  static const String pacificoFontFamily = 'Pacifico';
  static const String overpassMonoFontFamily = 'OverpassMono';
  static const String playfairFontFamily = 'Playfair';

  // V2 Design System Text Styles

  // Welcome message avec Pacifico
  static const TextStyle welcomeMessage = TextStyle(
    fontFamily: pacificoFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceLight,
  );

  // Card account name avec Outfit
  static const TextStyle cardAccountName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: AppColors.onSurfaceDark,
  );

  // Card account name avec Outfit (Dark)
  static TextStyle cardAccountNameDark = cardAccountName.copyWith(
    color: AppColors.onSurfaceLight,
  );

  // Card balance label
  static const TextStyle cardBalanceLabel = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceDark,
    letterSpacing: 1.2,
  );

  // Card balance amount avec Overpass Mono
  static const TextStyle cardBalanceAmount = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurfaceDark,
  );

  // Card balance amount avec Overpass Mono (Dark)
  static TextStyle cardBalanceAmountDark = cardBalanceAmount.copyWith(
    color: AppColors.onSurfaceLight,
  );

  // Card balance real amount (smaller)
  static const TextStyle cardBalanceRealAmount = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  // Card balance real amount (smaller) (Dark)
  static TextStyle cardBalanceRealAmountDark = cardBalanceRealAmount.copyWith(
    color: AppColors.onSurfaceLight,
  );

  // Section headers avec Playfair
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle sectionHeaderDark = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceLight,
  );

  // Section headers medium
  static const TextStyle sectionHeaderMedium = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle sectionHeaderMediumDark = TextStyle(
    fontFamily: playfairFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction amounts (format spécial sans décimales si entier)
  static const TextStyle transactionAmountLarge = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  static const TextStyle transactionAmountMedium = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction amount for perspective list
  static const TextStyle transactionAmountPerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction balance in perspective list
  static const TextStyle transactionBalancePerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDarkGray,
  );

  // Transaction name/counterparty in perspective list
  static const TextStyle transactionNamePerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceLight,
  );

  // Transaction category in perspective list
  static const TextStyle transactionCategoryPerspective = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
  );

  // Followed transactions styles
  static const TextStyle followedTransactionName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle followedTransactionDate = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
  );

  static const TextStyle followedTransactionAmount = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Styles spécialisés V1 (mis à jour avec nouvelles polices)
  static const TextStyle accountName = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle accountBalance = TextStyle(
    fontFamily: overpassMonoFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurfaceDark,
  );

  static const TextStyle transactionAmount = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle transactionBalance = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle transactionTitle = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle transactionDescription = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle dateHeader = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w300,
  );

  static const TextStyle buttonTextSmall = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  // Search bar placeholder text
  static const TextStyle searchPlaceholder = TextStyle(
    fontFamily: defaultFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}
