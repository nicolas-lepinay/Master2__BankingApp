import 'package:flutter/material.dart';

class AppColors {
  // === 👑 BRAND COLORS ===
  static const Color primary = primaryBlue;
  static const Color primaryDark = primaryBlue;
  static const Color secondary = primaryGreen;
  static const Color accent = primaryPink;

  // Card colors for stacked cards
  static const Color primaryBlue = Color(0xFF443EE3);
  static const Color primaryPink = Color(0xFFFE68E8);
  static const Color primaryGreen = Color(0xFFAFFF59);
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color primaryRed = Color(0xFFE33E62);
  static const Color primaryTeal = Color(0xFF01F5B0);
  static const Color primaryPurple = Color(0xFF7952FC);
  static const Color secondaryOrange = Color(0xFFFF3201);
  static const Color secondaryGreen = Color(0xFF1DF489);

  // Perspective ListView Colors
  static const Color secondaryPink = Color(0xFFFBA9ED);
  static const Color tertiaryPink = Color(0xFFFFC4F9);

  // Gradient colors for Perspective Transaction List
  static const Color gradientPinkStart = primaryPink;
  static const Color gradientPinkEnd = secondaryPink;

  // Perspective Transaction item background
  static const Color transactionItemBg = tertiaryPink;

  // === ️✏️ TYPOGRAPHY ===
  static const Color onSurfaceLight = Color(0xFF212121);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);

  // Special text
  static const Color creditColorLight = Color(0xFF28A13A);
  static const Color debitColorLight = Color(0xFFC42F43);
  static const Color creditColorDark = Color(0xFF97DAA1);
  static const Color debitColorDark = Color(0xFFE48995);

  // === 🧇 BACKGROUNDS ===
  static const Color backgroundLight1 = ultraLight;
  static const Color backgroundDark1 = Color(0xFF0E0E0C);

  static const Color buttonLight = Color(0xFF1F1F1F);
  static const Color buttonDark = backgroundLight1;

  // Greyscale
  static const Color ultraDark = Color(0xFF18181D);
  static const Color darkest = Color(0xFF232339);
  static const Color darker = Color(0xFF2E2E48);
  static const Color dark = Color(0xFF47516B);
  static const Color neutral = Color(0xFF79819A);
  static const Color light = Color(0xFFACB1C3);
  static const Color lighter = Color(0xFFD9DFE8);
  static const Color lightest = Color(0xFFE2E6EE);
  static const Color ultraLight = Color(0xFFF5F7FA);
  static const Color white = Color(0xFFFFFFFF);

  // Container colors
  static const Color containerBlack = Color(0xFF0E0E0C);
  static const Color containerDarkGray = Color(0xFF1F1F1F);
  static const Color containerLightGray = ultraLight;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textGray = Color(0xFF47516B);
  static const Color textDarkGray = Color(0xFF79819A);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color backgroundLight = ultraLight;
  static const Color backgroundDark = darkest;
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333333);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3C3C3C);

  // Greyscale
  static const Color dark100 = Color(0xFF0E0E0C); // Backgrounds
  static const Color dark87 = Color(0xFF18181D); // Bottom Sheets
  static const Color dark81 = Color(0xFF1C1C21); // Text Field
  static const Color dark75 = Color(0xFF1F1F1F); // Buttons
  static const Color dark50 = Color(0xFF2E2E48);
  static const Color dark25 = Color(0xFF47516B);
  static const Color dark12 = Color(0xFF616162);
  static const Color defaultGray = Color(0xFF79819A);
  static const Color light25 = Color(0xFFACB1C3);
  static const Color light50 = Color(0xFFD9DFE8);
  static const Color light75 = Color(0xFFE2E6EE);
  static const Color light87 = Color(0xFFF5F7FA); // Backgrounds, BottomSheets
  static const Color light100 = Color(0xFFFAFBFD); // Backgrounds

  // Typography
  static const Color textDark100 = dark100;
  static const Color textDark50 = dark50;
  static const Color textDark25 = dark25;
  static const Color textDark12 = dark12;
  static const Color textDefaultGray = defaultGray;
  static const Color textLight25 = light25;
  static const Color textLight50 = light50;
  static const Color textLight100 = light100;

  // Backgrounds
  static const Color surfaceBrightDark = dark100;
  static const Color surfaceDark = dark87;
  static const Color surfaceDimDarker = dark81;
  static const Color surfaceDimDark = dark75;

  static const Color surfaceBrightLight = light100;
  static const Color surfaceLight = light87;
  static const Color surfaceDimLight = light75;
}
