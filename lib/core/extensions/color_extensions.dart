import 'package:bankapp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

extension ColorContrast on Color {
  /// Retourne la couleur de texte optimale (noir ou blanc) pour maximiser le contraste en fonction de la luminosité de la couleur de fond
  Color get contrastingTextColorAuto {
    // Calculer la luminosité de la couleur (0.0 = noir, 1.0 = blanc)
    double luminance = computeLuminance();
    return luminance > 0.5 ? AppColors.textDark100 : AppColors.textLight100;
  }

  Brightness get contrastingBrightnesAuto {
    // Calculer la luminosité de la couleur (0.0 = noir, 1.0 = blanc)
    double luminance = computeLuminance();
    return luminance > 0.5 ? Brightness.dark : Brightness.light;
  }

  /// Retourne la couleur de texte avec opacité pour maximiser le contraste
  Color contrastingTextColorAutoWithOpacity(double opacity) {
    return contrastingTextColorAuto.withValues(alpha: opacity);
  }

  /// Méthode alternative pour une logique basée sur des couleurs spécifiques plutôt que sur la luminosité calculée
  Color get contrastingTextColor {
    const List<Color> specificColors = [
      AppColors.primaryGreen,
      AppColors.primaryTeal,
      AppColors.secondaryGreen,
    ];
    if (specificColors.contains(this)) {
      return AppColors.textDark100;
    }
    return AppColors.textLight100;
  }

  /// Éclaircit la couleur de [amount]%
  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Assombrit la couleur de [amount]%
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Atténue la couleur en fonction du thème actuel
  /// - Si mode clair → éclaircit
  /// - Si mode sombre → assombrit
  Color attenuate(BuildContext context, [double amount = .1]) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return darken(amount);
    } else {
      return lighten(amount);
    }
  }
}
