/// Interface principale pour accéder au registry d'icônes dans l'application
///
/// Cette interface simplifie l'accès au registry généré et fournit des
/// méthodes de recherche optimisées avec gestion d'erreurs.
library;

import 'package:flutter/material.dart';

import 'generated_icons_registry.dart';
import 'icon_entry.dart';

/// Interface principale pour l'accès aux icônes
class IconsRegistry {
  IconsRegistry._(); // Constructeur privé

  /// Recherche d'icônes avec filtrage et tri intelligent
  static List<IconEntry> searchIcons({
    required String query,
    String? category,
    String? style,
    String? setName,
    int limit = 50,
  }) {
    try {
      return GeneratedIconsRegistry.searchIcons(
        query: query,
        category: category,
        style: style,
        setName: setName,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'icônes: $e');
      return [];
    }
  }

  /// Recherche avec résultat détaillé et métriques
  static SearchResult searchWithMetrics({
    required String query,
    String? category,
    String? style,
    String? setName,
    int limit = 50,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final results = GeneratedIconsRegistry.searchIcons(
        query: query,
        category: category,
        style: style,
        setName: setName,
        limit: limit * 2, // Récupérer plus pour calculer le total
      );

      stopwatch.stop();

      // Séparer les résultats affichés du total
      final displayedResults = results.take(limit).toList();

      return SearchResult(
        icons: displayedResults,
        query: query,
        totalResults: results.length,
        searchTimeMs: stopwatch.elapsedMilliseconds,
        appliedFilters: {
          'category': category,
          'style': style,
          'setName': setName,
        },
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('Erreur lors de la recherche détaillée: $e');

      return SearchResult(
        icons: [],
        query: query,
        totalResults: 0,
        searchTimeMs: stopwatch.elapsedMilliseconds,
        appliedFilters: {
          'category': category,
          'style': style,
          'setName': setName,
        },
      );
    }
  }

  /// Obtient une icône par son ID
  static IconEntry? getIconById(String id) {
    try {
      return GeneratedIconsRegistry.getIconById(id);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'icône $id: $e');
      return null;
    }
  }

  /// Vérifie si une icône existe
  static bool hasIcon(String id) {
    try {
      return GeneratedIconsRegistry.hasIcon(id);
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'icône $id: $e');
      return false;
    }
  }

  /// Obtient toutes les icônes d'une catégorie
  static List<IconEntry> getIconsByCategory(String category) {
    try {
      return GeneratedIconsRegistry.getIconsByCategory(category);
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération de la catégorie $category: $e',
      );
      return [];
    }
  }

  /// Obtient toutes les icônes d'un set
  static List<IconEntry> getIconsBySet(String setName) {
    try {
      return GeneratedIconsRegistry.getIconsBySet(setName);
    } catch (e) {
      debugPrint('Erreur lors de la récupération du set $setName: $e');
      return [];
    }
  }

  /// Liste des catégories disponibles avec compteurs
  static List<IconCategory> getAvailableCategories() {
    try {
      final categories = GeneratedIconsRegistry.availableCategories;
      return categories.map((categoryId) {
        final icons = getIconsByCategory(categoryId);
        return IconCategory(
          id: categoryId,
          name: _getCategoryDisplayName(categoryId),
          description: _getCategoryDescription(categoryId),
          iconCount: icons.length,
          representativeIcon: icons.isNotEmpty ? icons.first.iconData : null,
          color: _getCategoryColor(categoryId),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  /// Liste des sets disponibles avec compteurs
  static List<IconSet> getAvailableSets() {
    try {
      final sets = GeneratedIconsRegistry.availableSets;
      return sets.map((setId) {
        final icons = getIconsBySet(setId);
        return IconSet(
          id: setId,
          name: _getSetDisplayName(setId),
          description: _getSetDescription(setId),
          iconCount: icons.length,
          source: 'icons_plus package',
          version: '5.0.0',
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des sets: $e');
      return [];
    }
  }

  /// Statistiques globales du registry
  static Map<String, dynamic> getStatistics() {
    try {
      return GeneratedIconsRegistry.statistics;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Affiche les statistiques dans la console (debug)
  static void printStatistics() {
    try {
      GeneratedIconsRegistry.printStatistics();
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage des statistiques: $e');
    }
  }

  /// Suggestions d'icônes basées sur une icône existante
  static List<IconEntry> getSuggestions(IconEntry icon, {int limit = 10}) {
    try {
      // Rechercher des icônes similaires par catégorie et mots-clés
      final categoryIcons = getIconsByCategory(
        icon.category,
      ).where((i) => i.id != icon.id).take(limit ~/ 2).toList();

      // Rechercher par mots-clés
      final keywordIcons = <IconEntry>[];
      for (final keyword in icon.keywords.take(3)) {
        final results = searchIcons(query: keyword, limit: 3);
        keywordIcons.addAll(
          results.where(
            (i) => i.id != icon.id && !categoryIcons.any((ci) => ci.id == i.id),
          ),
        );
      }

      final suggestions = [
        ...categoryIcons,
        ...keywordIcons.take(limit - categoryIcons.length),
      ];
      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('Erreur lors de la génération de suggestions: $e');
      return [];
    }
  }

  /// Icônes populaires/favorites (basé sur des critères prédéfinis)
  static List<IconEntry> getPopularIcons({int limit = 20}) {
    try {
      // Icônes essentielles les plus couramment utilisées
      const popularNames = [
        'home',
        'user',
        'heart',
        'star',
        'search',
        'menu',
        'close',
        'add',
        'edit',
        'delete',
        'save',
        'share',
        'download',
        'upload',
        'settings',
        'phone',
        'email',
        'calendar',
        'clock',
        'location',
      ];

      final popularIcons = <IconEntry>[];
      for (final name in popularNames) {
        final results = searchIcons(query: name, limit: 1);
        if (results.isNotEmpty) {
          popularIcons.add(results.first);
        }
      }

      return popularIcons.take(limit).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des icônes populaires: $e');
      return [];
    }
  }

  /// Noms d'affichage des catégories
  static String _getCategoryDisplayName(String categoryId) {
    const displayNames = {
      'essential': 'Essentiel',
      'navigation': 'Navigation',
      'business': 'Business',
      'tech': 'Technologie',
      'communication': 'Communication',
      'transport': 'Transport',
      'media': 'Média',
      'files': 'Fichiers',
      'tools': 'Outils',
      'social': 'Social',
      'shopping': 'Shopping',
      'health': 'Santé',
      'weather': 'Météo',
      'security': 'Sécurité',
      'modern': 'Moderne',
      'general': 'Général',
      'interface': 'Interface',
      'mobile': 'Mobile',
      'gaming': 'Gaming',
      'minimal': 'Minimal',
      'other': 'Autre',
    };

    return displayNames[categoryId] ?? categoryId;
  }

  /// Descriptions des catégories
  static String _getCategoryDescription(String categoryId) {
    const descriptions = {
      'essential': 'Icônes de base indispensables',
      'navigation': 'Navigation et déplacement',
      'business': 'Business et finance',
      'tech': 'Technologie et développement',
      'communication': 'Communication et réseaux',
      'transport': 'Transport et voyage',
      'media': 'Média et divertissement',
      'files': 'Fichiers et documents',
      'tools': 'Outils et configuration',
      'social': 'Réseaux sociaux',
      'shopping': 'Commerce et achats',
      'health': 'Santé et médical',
      'weather': 'Météo et climat',
      'security': 'Sécurité et protection',
      'modern': 'Design moderne',
      'general': 'Usage général',
      'interface': 'Interface utilisateur',
      'mobile': 'Applications mobiles',
      'gaming': 'Jeux et divertissement',
      'minimal': 'Design minimaliste',
      'other': 'Autres icônes',
    };

    return descriptions[categoryId] ?? 'Catégorie $categoryId';
  }

  /// Couleurs associées aux catégories
  static Color _getCategoryColor(String categoryId) {
    const colors = {
      'essential': Colors.blue,
      'navigation': Colors.purple,
      'business': Colors.green,
      'tech': Colors.cyan,
      'communication': Colors.orange,
      'transport': Colors.red,
      'media': Colors.pink,
      'files': Colors.amber,
      'tools': Colors.grey,
      'social': Colors.indigo,
      'shopping': Colors.teal,
      'health': Colors.lightGreen,
      'weather': Colors.lightBlue,
      'security': Colors.deepOrange,
      'modern': Colors.deepPurple,
      'general': Colors.blueGrey,
      'interface': Colors.brown,
      'mobile': Colors.lime,
      'gaming': Colors.deepOrange,
      'minimal': Colors.black87,
    };

    return colors[categoryId] ?? Colors.grey;
  }

  /// Noms d'affichage des sets
  static String _getSetDisplayName(String setId) {
    const displayNames = {
      'antdesign': 'Ant Design',
      'bootstrap': 'Bootstrap',
      'boxicons': 'BoxIcons',
      'clarity': 'Clarity',
      'evaicons': 'Eva Icons',
      'fontawesome': 'Font Awesome',
      'heroicons': 'Hero Icons',
      'iconsax': 'Iconsax',
      'ionicons': 'Ion Icons',
      'lineawesome': 'Line Awesome',
      'mingcute': 'MingCute',
      'octicons': 'OctIcons',
      'pixelarticons': 'Pixel Art Icons',
      'teenyicons': 'Teeny Icons',
      'zondicons': 'Zond Icons',
    };

    return displayNames[setId] ?? setId;
  }

  /// Descriptions des sets
  static String _getSetDescription(String setId) {
    const descriptions = {
      'antdesign': 'Icônes du système de design Ant Design',
      'bootstrap': 'Icônes officielles de Bootstrap',
      'boxicons': 'Collection d\'icônes BoxIcons',
      'clarity': 'Icônes du système Clarity de VMware',
      'evaicons': 'Icônes Eva élégantes',
      'fontawesome': 'Icônes Font Awesome populaires',
      'heroicons': 'Icônes Hero par les créateurs de Tailwind',
      'iconsax': 'Collection d\'icônes Iconsax moderne',
      'ionicons': 'Icônes Ion pour applications mobiles',
      'lineawesome': 'Alternative ligne à Font Awesome',
      'mingcute': 'Icônes MingCute minimalistes',
      'octicons': 'Icônes officielles de GitHub',
      'pixelarticons': 'Icônes pixel art rétro',
      'teenyicons': 'Icônes Teeny ultra-petites',
      'zondicons': 'Icônes Zond simples et nettes',
    };

    return descriptions[setId] ?? 'Set d\'icônes $setId';
  }
}
