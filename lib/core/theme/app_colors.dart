import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (V1)
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF26C6DA);
  static const Color accent = Color(0xFF00ACC1);

  // V2 Design System Colors
  // Card colors for stacked cards
  static const Color cardPurple = Color(0xFF443EE3);
  static const Color cardPink = Color(0xFFFE68E8);
  static const Color cardGreen = Color(0xFFAFFF59);
  static const Color cardOrange = Color(0xFFEB6B25);
  static const Color cardPurple2 = Color(0xFF7952FC);
  static const Color cardRed = Color(0xFFE33E62);

  // Container colors
  static const Color containerBlack = Color(0xFF0E0E0C);
  static const Color containerDarkGray = Color(0xFF1F1F1F);
  static const Color containerLightGray = Color(0xFFF5F7FA);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textGray = Color(0xFF47516B);
  static const Color textDarkGray = Color(0xFF79819A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);

  // Transaction colors
  static const Color creditTransaction = Color(
    0xFF28A13A,
  ); // Vert pour les crédits
  static const Color negativeBalance = Color(
    0xFFC42F43,
  ); // Rouge pour solde négatif

  // Gradient colors for transaction list
  static const Color gradientPinkStart = Color(0xFFFE68E8);
  static const Color gradientPinkEnd = Color(0xFFFBA9ED);

  // Transaction item background
  static const Color transactionItemBg = Color(0xFFFFC4F9);

  // Legacy colors (V1 compatibility)
  static const Color cardDark = Color(0xFF2C2C54);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color creditColor = Color(0xFF4CAF50);
  static const Color debitColor = Color(0xFFC42F43);
  static const Color balanceColor = Color(0xFF26C6DA);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333333);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3C3C3C);

  // Greyscale
  static const Color darkest = Color(0xFF232339);
  static const Color darker = Color(0xFF2E2E48);
  static const Color dark = Color(0xFF47516B);
  static const Color neutral = Color(0xFF79819A);
  static const Color light = Color(0xFFACB1C3);
  static const Color lighter = Color(0xFFD9DFE8);
  static const Color lightest = Color(0xFFE2E6EE);
  static const Color white = Color(0xFFFFFFFF);
}
