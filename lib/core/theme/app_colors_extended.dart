import 'package:flutter/material.dart';
import 'package:bankapp/core/theme/app_colors.dart';

@immutable
class AppColorsExtended extends ThemeExtension<AppColorsExtended> {
  const AppColorsExtended({
    required this.background1,
    required this.background2,
    required this.background3,
    required this.text100,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
    required this.textCredit,
    required this.textDebit,
    required this.buttonBackground,
    required this.inputBackground,
    required this.inputBorder,
  });

  final Color? background1;
  final Color? background2;
  final Color? background3;
  final Color? text100;
  final Color? text2;
  final Color? text3;
  final Color? text4;
  final Color? text5;
  final Color? textCredit;
  final Color? textDebit;
  final Color? buttonBackground;
  final Color? inputBackground;
  final Color? inputBorder;

  @override
  AppColorsExtended copyWith({
    Color? background1,
    Color? background2,
    Color? background3,
    Color? text100,
    Color? text2,
    Color? text3,
    Color? text4,
    Color? text5,
    Color? textCredit,
    Color? textDebit,
    Color? buttonBackground,
    Color? inputBackground,
    Color? inputBorder,
  }) {
    return AppColorsExtended(
      background1: background1 ?? this.background1,
      background2: background2 ?? this.background2,
      background3: background3 ?? this.background3,
      text100: text100 ?? this.text100,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      text4: text4 ?? this.text4,
      text5: text5 ?? this.text5,
      textCredit: textCredit ?? this.textCredit,
      textDebit: textDebit ?? this.textDebit,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
    );
  }

  @override
  AppColorsExtended lerp(covariant AppColorsExtended? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColorsExtended(
      background1: Color.lerp(background1, other.background1, t),
      background2: Color.lerp(background2, other.background2, t),
      background3: Color.lerp(background3, other.background3, t),
      text100: Color.lerp(text100, other.text100, t),
      text2: Color.lerp(text2, other.text2, t),
      text3: Color.lerp(text3, other.text3, t),
      text4: Color.lerp(text4, other.text4, t),
      text5: Color.lerp(text5, other.text5, t),
      textCredit: Color.lerp(textCredit, other.textCredit, t),
      textDebit: Color.lerp(textDebit, other.textDebit, t),
      buttonBackground: Color.lerp(buttonBackground, other.buttonBackground, t),
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t),
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t),
    );
  }

  static const light = AppColorsExtended(
    // 🧇 Surfaces
    background1: AppColors.backgroundLight1,
    background2: AppColors.ultraLight,
    background3: AppColors.lightest,
    // ✍️ Typography
    text100: AppColors.textDark100,
    text2: AppColors.darker,
    text3: AppColors.dark,
    text4: AppColors.neutral,
    text5: AppColors.light,
    textCredit: AppColors.creditColorLight,
    textDebit: AppColors.debitColorLight,
    // 🧃 Widgets
    buttonBackground: AppColors.buttonLight,
    inputBackground: AppColors.backgroundLight1,
    inputBorder: AppColors.borderLight,
  );

  static const dark = AppColorsExtended(
    // 🧇 Surfaces
    background1: AppColors.backgroundDark1,
    background2: AppColors.ultraDark,
    background3: AppColors.darkest,
    // ✍️ Typography
    text100: AppColors.textLight100,
    text2: AppColors.lighter,
    text3: AppColors.light,
    text4: AppColors.neutral,
    text5: AppColors.dark,
    textCredit: AppColors.creditColorDark,
    textDebit: AppColors.debitColorDark,
    // 🧃 Widgets
    buttonBackground: AppColors.buttonDark,
    inputBackground: AppColors.backgroundDark1,
    inputBorder: AppColors.borderDark,
  );
}
