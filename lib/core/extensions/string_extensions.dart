extension StringExtension on String {
  String toCapitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  /// Nettoie un nom de Counterparty en supprimant les espaces inutiles
  /// et en normalisant les espaces multiples
  String cleanCounterpartyName() {
    return trim()                        // Supprimer espaces début/fin
        .replaceAll(RegExp(r'\s+'), ' '); // Remplacer espaces multiples par simple
  }

  /// Vérifie si la chaîne contient un autre texte (insensible à la casse)
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }
}
