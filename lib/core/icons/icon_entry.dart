/// Structures de données pour les icônes dans l'application
/// 
/// Ce fichier contient les modèles utilisés par l'application pour
/// manipuler les icônes avec métadonnées enrichies.
library;

import 'package:flutter/material.dart';

/// Entrée d'icône avec métadonnées complètes pour la recherche
@immutable
class IconEntry {
  /// Identifiant unique de l'icône (ex: "bootstrap_heart_fill")
  final String id;
  
  /// Nom d'affichage nettoyé (ex: "heart")
  final String name;
  
  /// Catégorie de l'icône (ex: "essential", "business")
  final String category;
  
  /// Mots-clés pour la recherche (ex: ["heart", "love", "cœur"])
  final List<String> keywords;
  
  /// Données de l'icône Flutter
  final IconData iconData;
  
  /// Style de l'icône (ex: "fill", "outline")
  final String? style;
  
  /// Tags additionnels (ex: ["health", "medical"])
  final List<String> tags;

  const IconEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.keywords,
    required this.iconData,
    this.style,
    this.tags = const [],
  });

  /// Vérifie si l'icône correspond à une recherche
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    
    final searchTerms = query.toLowerCase().split(' ').where((term) => term.isNotEmpty);
    final searchableText = [
      name,
      category,
      ...keywords,
      ...tags,
      style ?? '',
    ].map((s) => s.toLowerCase()).join(' ');
    
    return searchTerms.every((term) => searchableText.contains(term));
  }

  /// Calcule la priorité de recherche pour le tri des résultats
  int getSearchPriority(String query) {
    if (query.isEmpty) return 0;
    
    final queryLower = query.toLowerCase();
    
    // Correspondance exacte du nom = priorité maximale
    if (name.toLowerCase() == queryLower) return 1000;
    
    // Nom commence par la requête = haute priorité  
    if (name.toLowerCase().startsWith(queryLower)) return 500;
    
    // Mot-clé exact = priorité moyenne-haute
    if (keywords.any((k) => k.toLowerCase() == queryLower)) return 300;
    
    // Catégorie exacte = priorité moyenne
    if (category.toLowerCase() == queryLower) return 250;
    
    // Tag exact = priorité moyenne-faible
    if (tags.any((t) => t.toLowerCase() == queryLower)) return 200;
    
    // Style exact = priorité faible
    if (style?.toLowerCase() == queryLower) return 150;
    
    // Contient la requête = priorité minimale
    return 100;
  }

  /// Extrait le nom du set d'icônes depuis l'ID
  String get setName {
    final parts = id.split('_');
    return parts.isNotEmpty ? parts.first : 'unknown';
  }

  /// Vérifie si l'icône appartient à un set spécifique
  bool belongsToSet(String setName) {
    return id.startsWith('${setName.toLowerCase()}_');
  }

  /// Retourne une version avec des métadonnées mises à jour
  IconEntry copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? keywords,
    IconData? iconData,
    String? style,
    List<String>? tags,
  }) {
    return IconEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      iconData: iconData ?? this.iconData,
      style: style ?? this.style,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IconEntry(id: $id, name: $name, category: $category)';
}

/// Catégorie d'icônes avec métadonnées
@immutable
class IconCategory {
  /// Identifiant de la catégorie
  final String id;
  
  /// Nom d'affichage de la catégorie
  final String name;
  
  /// Description de la catégorie
  final String description;
  
  /// Nombre d'icônes dans cette catégorie
  final int iconCount;
  
  /// Icône représentative de la catégorie
  final IconData? representativeIcon;
  
  /// Couleur associée à la catégorie
  final Color? color;

  const IconCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCount,
    this.representativeIcon,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IconCategory(id: $id, name: $name, iconCount: $iconCount)';
}

/// Set d'icônes avec informations
@immutable
class IconSet {
  /// Identifiant du set
  final String id;
  
  /// Nom d'affichage du set
  final String name;
  
  /// Description du set
  final String description;
  
  /// Nombre d'icônes dans ce set
  final int iconCount;
  
  /// URL ou information sur la source
  final String? source;
  
  /// Version du set
  final String? version;

  const IconSet({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCount,
    this.source,
    this.version,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconSet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'IconSet(id: $id, name: $name, iconCount: $iconCount)';
}

/// Résultat de recherche avec métadonnées
@immutable
class SearchResult {
  /// Icônes trouvées
  final List<IconEntry> icons;
  
  /// Requête de recherche
  final String query;
  
  /// Nombre total de résultats (avant limitation)
  final int totalResults;
  
  /// Durée de la recherche en millisecondes
  final int searchTimeMs;
  
  /// Filtres appliqués
  final Map<String, String?> appliedFilters;

  const SearchResult({
    required this.icons,
    required this.query,
    required this.totalResults,
    required this.searchTimeMs,
    this.appliedFilters = const {},
  });

  /// Vérifie si la recherche a des résultats
  bool get hasResults => icons.isNotEmpty;
  
  /// Vérifie si les résultats sont tronqués
  bool get isTruncated => icons.length < totalResults;
  
  /// Nombre de résultats affichés
  int get displayedResults => icons.length;

  @override
  String toString() => 'SearchResult(query: "$query", results: ${icons.length}/$totalResults, time: ${searchTimeMs}ms)';
}