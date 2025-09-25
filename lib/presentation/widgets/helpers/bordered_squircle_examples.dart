import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bordered_squircle.dart';

/// Exemples d'utilisation du BorderedSquircle
///
/// Ce fichier contient des exemples pratiques d'utilisation
/// du widget BorderedSquircle avec différentes configurations
class BorderedSquircleExamples {
  /// Squircle simple sans bordure
  static Widget basicSquircle({required Widget child}) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9,
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: child,
      ),
    );
  }

  /// Squircle avec bordure fine
  static Widget thinBorderSquircle({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9,
        backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
        border: BorderSide(color: borderColor ?? Colors.grey, width: 1.0),
        child: child,
      ),
    );
  }

  /// Squircle avec bordure épaisse (sélectionné)
  static Widget thickBorderSquircle({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9,
        backgroundColor: backgroundColor ?? Colors.pink.withValues(alpha: 0.15),
        border: BorderSide(color: borderColor ?? Colors.pink, width: 2.0),
        child: child,
      ),
    );
  }

  /// Squircle avec bordure pointillée (concept - non implémenté)
  /// Note: Flutter ne supporte pas les bordures pointillées nativement
  /// Cet exemple montre comment on pourrait l'étendre à l'avenir
  static Widget dashedBorderSquircle({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    // Pour l'instant, utilise une bordure continue
    // TODO: Implémenter les bordures pointillées via CustomPainter
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9,
        backgroundColor:
            backgroundColor ?? Colors.orange.withValues(alpha: 0.1),
        border: BorderSide(color: borderColor ?? Colors.orange, width: 1.5),
        child: child,
      ),
    );
  }

  /// Squircle adaptatif selon l'état (sélectionné ou non)
  static Widget adaptiveSquircle({
    required Widget child,
    required bool isSelected,
    Color? selectedBackgroundColor,
    Color? selectedBorderColor,
    Color? defaultBackgroundColor,
  }) {
    return SizedBox(
      width: 50.r,
      height: 50.r,
      child: BorderedSquircle(
        n: 2.9,
        backgroundColor: isSelected
            ? (selectedBackgroundColor ?? Colors.pink.withValues(alpha: 0.15))
            : (defaultBackgroundColor ?? Colors.grey.withValues(alpha: 0.1)),
        border: isSelected
            ? BorderSide(color: selectedBorderColor ?? Colors.pink, width: 2.0)
            : null, // Pas de bordure si non sélectionné
        child: child,
      ),
    );
  }

  /// Différentes valeurs de 'n' pour différentes formes
  static Widget shapesDemo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cercle (n=2)
        SizedBox(
          width: 40.r,
          height: 40.r,
          child: BorderedSquircle(
            n: 2.0,
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            border: const BorderSide(color: Colors.blue, width: 1.0),
            child: const Icon(Icons.circle, size: 20),
          ),
        ),

        // Squircle doux (n=2.9)
        SizedBox(
          width: 40.r,
          height: 40.r,
          child: BorderedSquircle(
            n: 2.9,
            backgroundColor: Colors.green.withValues(alpha: 0.2),
            border: const BorderSide(color: Colors.green, width: 1.0),
            child: const Icon(Icons.square, size: 20),
          ),
        ),

        // Squircle plus carré (n=4)
        SizedBox(
          width: 40.r,
          height: 40.r,
          child: BorderedSquircle(
            n: 4.0,
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            border: const BorderSide(color: Colors.orange, width: 1.0),
            child: const Icon(Icons.crop_square, size: 20),
          ),
        ),
      ],
    );
  }
}
