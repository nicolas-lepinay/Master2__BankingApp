import 'dart:ui';

import 'package:bankapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class GradientColors {
  // Couleurs primaires pour le dégradé animé
  static const List<Color> primaryColors = [
    Color(0xFFFF69B4), // Rose vif
    Color(0xFF8A2BE2), // Violet
    Color(0xFF00BFFF), // Bleu ciel
  ];

  // Couleurs secondaires pour le dégradé animé
  static const List<Color> secondaryColors = [
    Color(0xFFFF1493), // Rose profond
    Color(0xFF9370DB), // Violet medium
    Color(0xFF87CEEB), // Bleu ciel clair
  ];

  static List<Color> pink = [AppColors.primaryPink, AppColors.secondaryPink];

  // Durée de l'animation du dégradé
  static const Duration animationDuration = Duration(seconds: 2);
}
