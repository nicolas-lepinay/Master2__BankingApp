/// Un conteneur simple pour les tailles d'accroche calculées.
class SnapSizes {
  final double intermediate;
  final double max;

  SnapSizes({required this.intermediate, required this.max});
}

/// Calcule les positions d'accroche dynamiques en fonction de la hauteur de l'écran.
class DraggableSnapSizer {
  static SnapSizes calculateSnapSizes(double screenHeight) {
    // Points de données basés sur vos tests
    const double h1 = 997.34; // Pixel 8 Pro
    const double intermediate1 = 0.70;
    const double max1 = 0.85;

    const double h2 = 880.00; // Galaxy Z Flip 6
    const double intermediate2 = 0.65;
    const double max2 = 0.825;

    // Formule d'interpolation linéaire : y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
    // Nous l'utilisons pour trouver la taille correcte (y) pour la hauteur d'écran actuelle (x).

    // Calcul de la position intermédiaire
    final double calculatedIntermediate =
        intermediate2 +
        (screenHeight - h2) * (intermediate1 - intermediate2) / (h1 - h2);

    // Calcul de la position maximale
    final double calculatedMax =
        max2 + (screenHeight - h2) * (max1 - max2) / (h1 - h2);

    // On s'assure que les valeurs restent dans une plage raisonnable pour éviter
    // des résultats extrêmes sur des écrans très grands ou très petits.
    final double intermediate = calculatedIntermediate.clamp(0.60, 0.75);
    final double max = calculatedMax.clamp(0.80, 0.90);

    return SnapSizes(intermediate: intermediate, max: max);
  }
}
