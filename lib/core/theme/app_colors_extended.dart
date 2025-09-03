import 'package:bankapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

@immutable
class AppColorsExtended extends ThemeExtension<AppColorsExtended> {
  const AppColorsExtended({
    required this.background1,
    required this.background2,
    required this.background3,
    required this.backgroundInvert,

    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.text5,
    required this.text6,
    required this.textInvert,
    required this.textCredit,
    required this.textDebit,

    required this.buttonBackground1,
    required this.buttonBackground2,
    required this.buttonBackgroundDisabled,

    required this.buttonForeground1,
    required this.buttonForeground2,
    required this.buttonForegroundDisabled,
  });

  final Color? background1;
  final Color? background2;
  final Color? background3;
  final Color? backgroundInvert;

  final Color? text1;
  final Color? text2;
  final Color? text3;
  final Color? text4;
  final Color? text5;
  final Color? text6;
  final Color? textInvert;

  final Color? textCredit;
  final Color? textDebit;

  final Color? buttonBackground1;
  final Color? buttonBackground2;
  final Color? buttonBackgroundDisabled;

  final Color? buttonForeground1;
  final Color? buttonForeground2;
  final Color? buttonForegroundDisabled;

  @override
  AppColorsExtended copyWith({
    Color? background1,
    Color? background2,
    Color? background3,
    Color? backgroundInvert,

    Color? text1,
    Color? text2,
    Color? text3,
    Color? text4,
    Color? text5,
    Color? text6,
    Color? textInvert,

    Color? textCredit,
    Color? textDebit,

    Color? buttonBackground1,
    Color? buttonBackground2,
    Color? buttonBackgroundDisabled,

    Color? buttonForeground1,
    Color? buttonForeground2,
    Color? buttonForegroundDisabled,
  }) {
    return AppColorsExtended(
      background1: background1 ?? this.background1,
      background2: background2 ?? this.background2,
      background3: background3 ?? this.background3,
      backgroundInvert: backgroundInvert ?? this.backgroundInvert,

      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      text4: text4 ?? this.text4,
      text5: text5 ?? this.text5,
      text6: text6 ?? this.text6,
      textInvert: textInvert ?? this.textInvert,

      textCredit: textCredit ?? this.textCredit,
      textDebit: textDebit ?? this.textDebit,
      buttonBackground1: buttonBackground1 ?? this.buttonBackground1,
      buttonBackground2: buttonBackground2 ?? this.buttonBackground2,
      buttonBackgroundDisabled:
          buttonBackgroundDisabled ?? this.buttonBackgroundDisabled,

      buttonForeground1: buttonForeground1 ?? this.buttonForeground1,
      buttonForeground2: buttonForeground2 ?? this.buttonForeground2,
      buttonForegroundDisabled:
          buttonForegroundDisabled ?? this.buttonForegroundDisabled,
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
      backgroundInvert: Color.lerp(backgroundInvert, other.backgroundInvert, t),
      text1: Color.lerp(text1, other.text1, t),
      text2: Color.lerp(text2, other.text2, t),
      text3: Color.lerp(text3, other.text3, t),
      text4: Color.lerp(text4, other.text4, t),
      text5: Color.lerp(text5, other.text5, t),
      text6: Color.lerp(text6, other.text6, t),
      textInvert: Color.lerp(textInvert, other.textInvert, t),
      textCredit: Color.lerp(textCredit, other.textCredit, t),
      textDebit: Color.lerp(textDebit, other.textDebit, t),
      buttonBackground1: Color.lerp(
        buttonBackground1,
        other.buttonBackground1,
        t,
      ),
      buttonBackground2: Color.lerp(
        buttonBackground2,
        other.buttonBackground2,
        t,
      ),
      buttonBackgroundDisabled: Color.lerp(
        buttonBackgroundDisabled,
        other.buttonBackgroundDisabled,
        t,
      ),
      buttonForeground1: Color.lerp(
        buttonForeground1,
        other.buttonForeground1,
        t,
      ),
      buttonForeground2: Color.lerp(
        buttonForeground2,
        other.buttonForeground2,
        t,
      ),
      buttonForegroundDisabled: Color.lerp(
        buttonForegroundDisabled,
        other.buttonForegroundDisabled,
        t,
      ),
    );
  }

  static const light = AppColorsExtended(
    // 🧇 Surfaces
    background1: AppColors.surfaceBrightLight,
    background2: AppColors.surfaceLight,
    background3: AppColors.surfaceDimLight,
    backgroundInvert: AppColors.surfaceDark,
    // ✍️ Typography
    text1: AppColors.textDark100,
    text2: AppColors.textDark50,
    text3: AppColors.textDark25,
    text4: AppColors.textDefaultGray,
    text5: AppColors.textLight25,
    text6: AppColors.textLight50,
    textInvert: AppColors.textLight100,
    textCredit: AppColors.creditColorLight,
    textDebit: AppColors.debitColorLight,
    // 🧃 Widgets
    buttonBackground1: AppColors.surfaceBrightDark,
    buttonBackground2: AppColors.surfaceBrightLight,
    buttonBackgroundDisabled: AppColors.surfaceDimLight,

    buttonForeground1: AppColors.textLight100,
    buttonForeground2: AppColors.textDark100,
    buttonForegroundDisabled: AppColors.defaultGray,
  );

  static const dark = AppColorsExtended(
    // 🧇 Surfaces
    background1: AppColors.surfaceBrightDark,
    background2: AppColors.surfaceDark,
    background3: AppColors.surfaceDimDarker,
    backgroundInvert: AppColors.surfaceLight,
    // ✍️ Typography
    text1: AppColors.textLight100,
    text2: AppColors.textLight50,
    text3: AppColors.textLight25,
    text4: AppColors.textDefaultGray,
    text5: AppColors.textDark25,
    text6: AppColors.textDark50,
    textInvert: AppColors.textDark100,
    textCredit: AppColors.creditColorDark,
    textDebit: AppColors.debitColorDark,
    // 🧃 Widgets
    buttonBackground1: AppColors.surfaceBrightLight,
    buttonBackground2: AppColors.surfaceBrightDark,
    buttonBackgroundDisabled: AppColors.surfaceDimDark,
    buttonForeground1: AppColors.textDark100,
    buttonForeground2: AppColors.textLight100,
    buttonForegroundDisabled: AppColors.textDark12,
  );
}
