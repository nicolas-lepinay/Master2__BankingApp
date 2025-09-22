/// Modèles de données pour la génération d'icônes
/// 
/// Ce fichier contient les structures de données utilisées par le système
/// de génération automatique d'icônes depuis le package icons_plus.
library;

/// Icône parsée depuis le code source d'icons_plus
class ParsedIcon {
  /// Nom de l'icône dans le code source (ex: "heart_fill")
  final String name;
  
  /// Code point hexadécimal (ex: "f1a3")
  final String codePoint;
  
  /// Famille de police (ex: "Bootstrap")
  final String fontFamily;
  
  /// Nom de la classe contenant l'icône (ex: "Bootstrap")
  final String className;

  const ParsedIcon({
    required this.name,
    required this.codePoint,
    required this.fontFamily,
    required this.className,
  });

  @override
  String toString() => 'ParsedIcon(name: $name, className: $className, codePoint: $codePoint)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedIcon &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          className == other.className;

  @override
  int get hashCode => name.hashCode ^ className.hashCode;
}

/// Icône enrichie avec métadonnées pour la recherche
class EnrichedIcon {
  /// Identifiant unique (ex: "bootstrap_heart_fill")
  final String id;
  
  /// Nom nettoyé pour affichage (ex: "heart")
  final String name;
  
  /// Catégorie inférée (ex: "essential")
  final String category;
  
  /// Mots-clés pour la recherche (ex: ["heart", "love", "cœur"])
  final List<String> keywords;
  
  /// Style de l'icône (ex: "fill", "outline")
  final String? style;
  
  /// Tags additionnels (ex: ["health", "medical"])
  final List<String> tags;
  
  /// Nom de la classe d'origine (ex: "Bootstrap")
  final String className;
  
  /// Nom du champ dans la classe (ex: "heart_fill")
  final String fieldName;
  
  /// Code point original
  final String codePoint;
  
  /// Famille de police
  final String fontFamily;

  const EnrichedIcon({
    required this.id,
    required this.name,
    required this.category,
    required this.keywords,
    required this.className,
    required this.fieldName,
    required this.codePoint,
    required this.fontFamily,
    this.style,
    this.tags = const [],
  });

  @override
  String toString() => 'EnrichedIcon(id: $id, name: $name, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrichedIcon &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Statistiques de génération
class GenerationStats {
  /// Nombre total d'icônes parsées
  final int totalParsed;
  
  /// Nombre d'icônes enrichies
  final int totalEnriched;
  
  /// Nombre de sets d'icônes traités
  final int totalSets;
  
  /// Répartition par set
  final Map<String, int> iconsBySet;
  
  /// Répartition par catégorie
  final Map<String, int> iconsByCategory;
  
  /// Durée de génération en millisecondes
  final int durationMs;

  const GenerationStats({
    required this.totalParsed,
    required this.totalEnriched,
    required this.totalSets,
    required this.iconsBySet,
    required this.iconsByCategory,
    required this.durationMs,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Statistiques de génération:');
    buffer.writeln('  📊 Total icônes: $totalEnriched');
    buffer.writeln('  📦 Sets traités: $totalSets');
    buffer.writeln('  ⏱️  Durée: ${durationMs}ms');
    buffer.writeln('  📈 Répartition par set:');
    iconsBySet.forEach((set, count) {
      buffer.writeln('     $set: $count icônes');
    });
    return buffer.toString();
  }
}