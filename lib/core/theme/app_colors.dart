import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF26C6DA);
  static const Color accent = Color(0xFF00ACC1);

  // Greyscale
  static const Color darkest = Color(0xFF232339);
  static const Color darker = Color(0xFF2E2E48);
  static const Color dark = Color(0xFF47516B);
  static const Color neutral = Color(0xFF79819A);
  static const Color light = Color(0xFFACB1C3);
  static const Color lighter = Color(0xFFD9DFE8);
  static const Color lightest = Color(0xFFE2E6EE);
  static const Color white = Color(0xFFFFFFFF);

  // Card colors
  static const Color cardDark = Color(0xFF2C2C54);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = darkest;
  static const Color textSecondary = neutral; // Grey caption
  static const Color textLight = white;
  static const Color textDark = darkest;

  // Transaction colors
  static const Color creditColor = Color(0xFF249689);
  static const Color debitColor = Color(0xFFEF4444);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Background colors
  static const Color backgroundLight = Color(0xFFEFF0F2);
  static const Color backgroundDark = darker;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333333);

  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3C3C3C);
}
