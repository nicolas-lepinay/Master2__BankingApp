/// Générateur de registry statique pour les icônes
///
/// Ce module génère le fichier Dart statique contenant toutes les icônes
/// enrichies, optimisé pour des recherches rapides dans l'application.
library;

import 'dart:io';

import 'models.dart';

/// Générateur principal pour créer le registry statique
class IconRegistryGenerator {
  /// Génère le fichier registry Dart complet
  void generateRegistry(Map<String, List<EnrichedIcon>> iconSets) {
    print('🚀 Génération du registry statique...');

    final buffer = StringBuffer();

    // 1. Header du fichier
    _writeHeader(buffer, iconSets);

    // 2. Imports nécessaires
    _writeImports(buffer);

    // 3. Classe principale du registry
    _writeRegistryClass(buffer, iconSets);

    // 4. Écrire le fichier
    _writeToFile(buffer.toString(), iconSets);

    print('✅ Registry généré avec succès!');
  }

  /// Écrit l'en-tête du fichier généré
  void _writeHeader(
    StringBuffer buffer,
    Map<String, List<EnrichedIcon>> iconSets,
  ) {
    final now = DateTime.now();
    buffer.writeln('// 🤖 FICHIER GÉNÉRÉ AUTOMATIQUEMENT - NE PAS MODIFIER');
    buffer.writeln(
      '// Généré le ${now.day}/${now.month}/${now.year} à ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
    buffer.writeln('// Source: icons_plus package via script de génération');
    buffer.writeln('// Nombre total d\'icônes: ${_countTotalIcons(iconSets)}');
    buffer.writeln('//');
    buffer.writeln('// ⚠️  Ce fichier est généré automatiquement.');
    buffer.writeln(
      '// ⚠️  Toute modification manuelle sera perdue lors de la prochaine génération.',
    );
    buffer.writeln(
      '// ⚠️  Pour modifier les icônes, modifiez le script dans tools/',
    );
    buffer.writeln();
  }

  /// Écrit les imports nécessaires
  void _writeImports(StringBuffer buffer) {
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:icons_plus/icons_plus.dart';");
    buffer.writeln("import 'icon_entry.dart';");
    buffer.writeln();
  }

  /// Écrit la classe principale du registry
  void _writeRegistryClass(
    StringBuffer buffer,
    Map<String, List<EnrichedIcon>> iconSets,
  ) {
    final totalIcons = _countTotalIcons(iconSets);

    buffer.writeln(
      '/// Registry statique contenant toutes les icônes d\'icons_plus',
    );
    buffer.writeln(
      '/// avec métadonnées enrichies pour la recherche intelligente.',
    );
    buffer.writeln('class GeneratedIconsRegistry {');
    buffer.writeln('  GeneratedIconsRegistry._(); // Constructeur privé');
    buffer.writeln();

    // Map principale des icônes
    buffer.writeln(
      '  /// Map principale contenant toutes les icônes indexées par ID',
    );
    buffer.writeln('  static const Map<String, IconEntry> _icons = {');

    var processedIcons = 0;
    for (final entry in iconSets.entries) {
      final setName = entry.key;
      final icons = entry.value;

      buffer.writeln(
        '    // ═══ ${setName.toUpperCase()} (${icons.length} icônes) ═══',
      );

      for (final icon in icons) {
        _writeIconEntry(buffer, icon);
        processedIcons++;

        // Progress indicator pour les gros sets
        if (processedIcons % 1000 == 0) {
          print('   📊 Généré $processedIcons/$totalIcons icônes...');
        }
      }

      buffer.writeln();
    }

    buffer.writeln('  };');
    buffer.writeln();

    // Méthodes d'accès
    _writeAccessMethods(buffer, iconSets, totalIcons);

    // Méthodes de recherche
    _writeSearchMethods(buffer);

    // Statistiques
    _writeStatistics(buffer, iconSets);

    buffer.writeln('}');
  }

  /// Écrit une entrée d'icône individuelle
  void _writeIconEntry(StringBuffer buffer, EnrichedIcon icon) {
    buffer.writeln("    '${icon.id}': IconEntry(");
    buffer.writeln("      id: '${icon.id}',");
    buffer.writeln("      name: '${_escapeString(icon.name)}',");
    buffer.writeln("      category: '${icon.category}',");
    buffer.writeln("      keywords: ${_formatStringList(icon.keywords)},");
    buffer.writeln("      iconData: ${icon.className}.${icon.fieldName},");

    if (icon.style != null) {
      buffer.writeln("      style: '${icon.style}',");
    }

    buffer.writeln("      tags: ${_formatStringList(icon.tags)},");
    buffer.writeln("    ),");
  }

  /// Écrit les méthodes d'accès principales
  void _writeAccessMethods(
    StringBuffer buffer,
    Map<String, List<EnrichedIcon>> iconSets,
    int totalIcons,
  ) {
    buffer.writeln('  /// Accès à toutes les icônes (${totalIcons} icônes)');
    buffer.writeln('  static Map<String, IconEntry> get allIcons => _icons;');
    buffer.writeln();

    buffer.writeln('  /// Obtient une icône par son ID');
    buffer.writeln('  static IconEntry? getIconById(String id) => _icons[id];');
    buffer.writeln();

    buffer.writeln('  /// Vérifie si une icône existe');
    buffer.writeln(
      '  static bool hasIcon(String id) => _icons.containsKey(id);',
    );
    buffer.writeln();

    // Méthodes par set
    buffer.writeln('  /// Obtient toutes les icônes d\'un set spécifique');
    buffer.writeln('  static List<IconEntry> getIconsBySet(String setName) {');
    buffer.writeln('    final prefix = setName.toLowerCase() + \'_\';');
    buffer.writeln(
      '    return _icons.values.where((icon) => icon.id.startsWith(prefix)).toList();',
    );
    buffer.writeln('  }');
    buffer.writeln();

    // Sets disponibles
    buffer.writeln('  /// Liste des sets d\'icônes disponibles');
    buffer.writeln('  static List<String> get availableSets => [');
    for (final setName in iconSets.keys) {
      buffer.writeln("    '${setName.toLowerCase()}',");
    }
    buffer.writeln('  ];');
    buffer.writeln();
  }

  /// Écrit les méthodes de recherche
  void _writeSearchMethods(StringBuffer buffer) {
    buffer.writeln(
      '  /// Recherche d\'icônes avec filtrage et tri intelligent',
    );
    buffer.writeln('  static List<IconEntry> searchIcons({');
    buffer.writeln('    required String query,');
    buffer.writeln('    String? category,');
    buffer.writeln('    String? style,');
    buffer.writeln('    String? setName,');
    buffer.writeln('    int limit = 50,');
    buffer.writeln('  }) {');
    buffer.writeln('    if (query.isEmpty) return [];');
    buffer.writeln();
    buffer.writeln('    final queryLower = query.toLowerCase();');
    buffer.writeln('    var results = _icons.values.where((icon) {');
    buffer.writeln('      // Filtrage par catégorie');
    buffer.writeln(
      '      if (category != null && icon.category != category) return false;',
    );
    buffer.writeln();
    buffer.writeln('      // Filtrage par style');
    buffer.writeln(
      '      if (style != null && icon.style != style) return false;',
    );
    buffer.writeln();
    buffer.writeln('      // Filtrage par set');
    buffer.writeln('      if (setName != null) {');
    buffer.writeln('        final prefix = setName.toLowerCase() + \'_\';');
    buffer.writeln('        if (!icon.id.startsWith(prefix)) return false;');
    buffer.writeln('      }');
    buffer.writeln();
    buffer.writeln('      // Recherche dans les métadonnées');
    buffer.writeln('      final searchableText = [');
    buffer.writeln('        icon.name,');
    buffer.writeln('        icon.category,');
    buffer.writeln('        ...icon.keywords,');
    buffer.writeln('        ...icon.tags,');
    buffer.writeln('      ].map((s) => s.toLowerCase()).join(\' \');');
    buffer.writeln();
    buffer.writeln('      return searchableText.contains(queryLower);');
    buffer.writeln('    }).toList();');
    buffer.writeln();
    buffer.writeln('    // Tri par pertinence');
    buffer.writeln('    results.sort((a, b) {');
    buffer.writeln(
      '      final aPriority = _getSearchPriority(a, queryLower);',
    );
    buffer.writeln(
      '      final bPriority = _getSearchPriority(b, queryLower);',
    );
    buffer.writeln('      return bPriority.compareTo(aPriority);');
    buffer.writeln('    });');
    buffer.writeln();
    buffer.writeln('    return results.take(limit).toList();');
    buffer.writeln('  }');
    buffer.writeln();

    // Méthode de calcul de priorité
    buffer.writeln('  /// Calcule la priorité de recherche pour le tri');
    buffer.writeln(
      '  static int _getSearchPriority(IconEntry icon, String query) {',
    );
    buffer.writeln('    // Correspondance exacte du nom = priorité maximale');
    buffer.writeln('    if (icon.name.toLowerCase() == query) return 1000;');
    buffer.writeln();
    buffer.writeln('    // Nom commence par la requête = haute priorité');
    buffer.writeln(
      '    if (icon.name.toLowerCase().startsWith(query)) return 500;',
    );
    buffer.writeln();
    buffer.writeln('    // Mot-clé exact = priorité moyenne');
    buffer.writeln(
      '    if (icon.keywords.any((k) => k.toLowerCase() == query)) return 300;',
    );
    buffer.writeln();
    buffer.writeln('    // Catégorie ou tag = priorité faible');
    buffer.writeln('    if (icon.category.toLowerCase() == query ||');
    buffer.writeln(
      '        icon.tags.any((t) => t.toLowerCase() == query)) return 200;',
    );
    buffer.writeln();
    buffer.writeln('    // Contient la requête = priorité minimale');
    buffer.writeln('    return 100;');
    buffer.writeln('  }');
    buffer.writeln();

    // Méthodes par catégorie
    buffer.writeln('  /// Obtient toutes les icônes d\'une catégorie');
    buffer.writeln(
      '  static List<IconEntry> getIconsByCategory(String category) {',
    );
    buffer.writeln(
      '    return _icons.values.where((icon) => icon.category == category).toList();',
    );
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Obtient la liste des catégories disponibles');
    buffer.writeln('  static List<String> get availableCategories {');
    buffer.writeln(
      '    final categories = _icons.values.map((icon) => icon.category).toSet().toList();',
    );
    buffer.writeln('    categories.sort();');
    buffer.writeln('    return categories;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// Écrit les statistiques du registry
  void _writeStatistics(
    StringBuffer buffer,
    Map<String, List<EnrichedIcon>> iconSets,
  ) {
    final totalIcons = _countTotalIcons(iconSets);

    buffer.writeln('  /// Statistiques du registry');
    buffer.writeln('  static Map<String, dynamic> get statistics => {');
    buffer.writeln("    'totalIcons': $totalIcons,");
    buffer.writeln("    'totalSets': ${iconSets.length},");
    buffer.writeln("    'iconsBySet': {");

    for (final entry in iconSets.entries) {
      buffer.writeln(
        "      '${entry.key.toLowerCase()}': ${entry.value.length},",
      );
    }

    buffer.writeln("    },");
    buffer.writeln("    'generatedAt': '${DateTime.now().toIso8601String()}',");
    buffer.writeln("  };");
    buffer.writeln();

    buffer.writeln('  /// Affiche les statistiques du registry');
    buffer.writeln('  static void printStatistics() {');
    buffer.writeln("    print('📊 Statistiques du registry d\\'icônes:');");
    buffer.writeln("    print('   🎯 Total: $totalIcons icônes');");
    buffer.writeln("    print('   📦 Sets: ${iconSets.length}');");
    buffer.writeln("    statistics['iconsBySet'].forEach((set, count) {");
    buffer.writeln("      print('   📋 \$set: \$count icônes');");
    buffer.writeln("    });");
    buffer.writeln('  }');
    buffer.writeln();
  }

  /// Écrit le fichier sur le disque
  void _writeToFile(String content, Map<String, List<EnrichedIcon>> iconSets) {
    final outputPath = 'lib/core/icons/generated_icons_registry.dart';
    final outputFile = File(outputPath);

    // Créer le dossier si nécessaire
    outputFile.parent.createSync(recursive: true);

    // Écrire le contenu
    outputFile.writeAsStringSync(content);

    final totalIcons = _countTotalIcons(iconSets);
    final fileSize = (content.length / 1024).toStringAsFixed(1);

    print('📁 Fichier généré: $outputPath');
    print('📊 Taille: ${fileSize}KB');
    print('🎯 Contenu: $totalIcons icônes dans ${iconSets.length} sets');
  }

  /// Formate une liste de chaînes pour le code Dart
  String _formatStringList(List<String> items) {
    if (items.isEmpty) return 'const []';

    final formatted = items
        .map((item) => "'${_escapeString(item)}'")
        .join(', ');
    return 'const [$formatted]';
  }

  /// Échappe les caractères spéciaux dans une chaîne
  String _escapeString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Compte le nombre total d'icônes
  int _countTotalIcons(Map<String, List<EnrichedIcon>> iconSets) {
    return iconSets.values
        .map((icons) => icons.length)
        .fold(0, (a, b) => a + b);
  }
}
