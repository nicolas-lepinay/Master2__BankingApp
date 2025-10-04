# REFACTORING ICONS SYSTEM - Plan d'Architecture Complet

## Table des Matières

1. [Contexte et Problématique](#1-contexte-et-problématique)
2. [Solution Technique](#2-solution-technique)
3. [Architecture Détaillée](#3-architecture-détaillée)
4. [Phase 1 : Génération du Mapping Statique](#phase-1--génération-du-mapping-statique)
5. [Phase 2 : Service de Recherche](#phase-2--service-de-recherche)
6. [Phase 3 : Utilities de Mapping](#phase-3--utilities-de-mapping)
7. [Phase 4 : Refactoring ViewModels](#phase-4--refactoring-viewmodels)
8. [Phase 5 : Nettoyage Initialisation](#phase-5--nettoyage-initialisation)
9. [Phase 6 : Validation et Tests](#phase-6--validation-et-tests)
10. [Checklist de Déploiement](#10-checklist-de-déploiement)

---

## 1. Contexte et Problématique

### Problème Actuel

**Symptôme** : Le splash screen dure ~25 secondes à cause de l'initialisation des icônes.

**Cause Racine** : `IconsInitializationService.initializeInIsolate()` charge 41,701 `IconEntry` objects dans un Isolate :
```dart
// app_initialization_service.dart:100-136
await _iconsInitializationService.initializeInIsolate(
  timeout: const Duration(seconds: 30),
);
```

**Chaîne de Dépendances** :
1. App démarre → Splash screen
2. `AppInitializationService.initialize()` exécuté
3. Étape 2 (lignes 100-136) : Initialisation icônes (25 secondes)
4. Étape 3 (lignes 138-175) : Chargement catégories **BLOQUÉ** en attendant icônes
5. Les catégories nécessitent `IconDataUtils.idToIconData()` qui requiert `IconsRegistry.isInitialized == true`

### Cas d'Usage à Préserver

1. **Affichage des icônes de catégories** :
   - DB stocke : `icon: "Mdi.lockMinus"` (string)
   - `CategoryModel.toEntity()` convertit : `IconDataUtils.idToIconData(icon)` → `IconData`
   - Affichage dans UI : `Icon(category.icon)`

2. **Recherche d'icônes** :
   - `icon_test_screen.dart` : Écran de sélection d'icône
   - Recherche par mot-clé : "dog", "lock", "heart", etc.
   - Affichage résultats filtrés avec preview

### Objectifs du Refactoring

- ✅ **Performance** : 25s → 2s temps de démarrage (92% réduction)
- ✅ **Mémoire** : ~200 MB → ~50 MB (75% réduction)
- ✅ **Simplicité** : Map statique compilée (zero runtime initialization)
- ✅ **Maintenabilité** : Code généré auto-documenté avec format clair
- ✅ **Backward Compatibility** : Aucune (développement en cours, pas de migration)

---

## 2. Solution Technique

### Architecture Nouvelle

```
ANCIEN SYSTÈME (25s init):
┌─────────────────────────────────────────────────────────────┐
│ IconsInitializationService (Isolate background)             │
│  ↓                                                           │
│ SegmentedIconsRegistryData (41,701 IconEntry objects)       │
│  ↓                                                           │
│ IconsRegistry (Dynamic lookup avec family detection)        │
│  ↓                                                           │
│ IconDataUtils (idToIconData() conversion)                   │
└─────────────────────────────────────────────────────────────┘

NOUVEAU SYSTÈME (0s init):
┌─────────────────────────────────────────────────────────────┐
│ icon_mapping.dart (Map statique compilée)                   │
│  ↓                                                           │
│ IconSearchService (Filtrage simple sur clés)                │
│  ↓                                                           │
│ IconMappingUtils (Lookup O(1) direct)                       │
└─────────────────────────────────────────────────────────────┘
```

### Format des Icônes

**Ancien Format** (underscore) :
```dart
'bootstrap_circle': Bootstrap.circle,
'mdi_lock_minus': Mdi.lockMinus,
'fontawesome_shield_dog_solid': FontAwesome.shield_dog_solid,
```

**Nouveau Format** (dot notation) :
```dart
'Bootstrap.circle': Bootstrap.circle,
'Mdi.lockMinus': Mdi.lockMinus,
'FontAwesome.shield_dog_solid': FontAwesome.shield_dog_solid,
```

**Avantages du Format Dot** :
- Split par `.` pour séparer package du nom : `iconId.split('.')[1]`
- Recherche "ant" → Ne renvoie PAS toutes les icônes AntDesign, mais seulement celles avec "ant" dans le nom
- Recherche "boot" → Ne renvoie PAS toutes les icônes Bootstrap, mais seulement "bootstrap_fill", etc.
- Plus lisible et auto-documenté

### Stratégie de Recherche

**Recherche Simple** (sans keywords générés) :
```dart
static List<String> search(String query, {int limit = 100}) {
  final queryLower = query.toLowerCase();

  return IconMapping._icons.keys
      .where((iconId) {
        // Split par '.' : ['Bootstrap', 'circle']
        final parts = iconId.split('.');
        final iconName = parts.length > 1 ? parts[1] : iconId;

        // Chercher uniquement dans le nom de l'icône
        return iconName.toLowerCase().contains(queryLower);
      })
      .take(limit)
      .toList();
}
```

**Exemple de Recherche** :
- Query: `"dog"` → Résultat: `['FontAwesome.shield_dog_solid', 'FontAwesome.dog', ...]`
- Query: `"ant"` → Résultat: `['Bootstrap.elephant', 'Mdi.antenna', ...]` (PAS toutes les AntDesign icons)
- Query: `"lock"` → Résultat: `['Mdi.lockMinus', 'Mdi.lockPlus', 'Bootstrap.lock_fill', ...]`

---

## 3. Architecture Détaillée

### Structure de Dossiers

```
Claude_Flutter_V4/
├── tools/                          # ← BACKUP (ne pas toucher)
│   ├── generate_icons.dart
│   ├── generators/
│   └── ...
│
├── tools_v2/                       # ← NOUVEAU (génération V2)
│   ├── generate_icon_mapping.dart  # Script principal
│   └── icon_generator_v2/
│       ├── icon_extractor.dart     # Extraction depuis packages
│       ├── icon_formatter.dart     # Formatage entries
│       └── file_writer.dart        # Écriture fichier final
│
├── lib/
│   └── core/
│       ├── icons/                  # ← BACKUP (ne pas toucher)
│       │   ├── icons_registry.dart
│       │   ├── segmented_icons_registry.dart
│       │   └── ...
│       │
│       ├── icons_v2/               # ← NOUVEAU (système V2)
│       │   ├── icon_mapping.dart           # Map statique générée
│       │   └── icon_search_service.dart    # Service de recherche
│       │
│       └── utils/
│           ├── icon_data_utils.dart        # ← BACKUP (ne pas toucher)
│           └── icon_mapping_utils.dart     # ← NOUVEAU (utils V2)
│
└── prompts/
    └── REFACTORING.md              # ← CE FICHIER
```

### Fichiers à Créer

#### 1. `/tools_v2/generate_icon_mapping.dart`
- **Rôle** : Script principal de génération
- **Input** : Packages Flutter (bootstrap_icons, icons_plus, etc.)
- **Output** : `/lib/core/icons_v2/icon_mapping.dart`

#### 2. `/tools_v2/icon_generator_v2/icon_extractor.dart`
- **Rôle** : Extraction des IconData depuis 7 packages
- **Classes** : `IconExtractor`, `RawIconEntryV2`

#### 3. `/tools_v2/icon_generator_v2/icon_formatter.dart`
- **Rôle** : Formatage des entries au nouveau format
- **Méthode principale** : `formatIconEntry(RawIconEntryV2 entry) -> String`

#### 4. `/tools_v2/icon_generator_v2/file_writer.dart`
- **Rôle** : Écriture du fichier final avec imports et map
- **Méthode principale** : `writeIconMappingFile(Map<String, String> entries)`

#### 5. `/lib/core/icons_v2/icon_mapping.dart`
- **Rôle** : Map statique générée (READ-ONLY, auto-generated)
- **Taille** : ~2-3 MB, 41,701 entrées

#### 6. `/lib/core/icons_v2/icon_search_service.dart`
- **Rôle** : Service de recherche d'icônes
- **Méthodes** : `search()`, `searchSorted()`, `searchWithPackage()`

#### 7. `/lib/core/utils/icon_mapping_utils.dart`
- **Rôle** : Utilities de conversion IconData ↔ String
- **Méthodes** : `idToIconData()`, `iconDataToId()`, `getDisplayIcon()`

### Fichiers à Modifier

#### 1. `/lib/presentation/viewmodels/screens/icon_test_view_model.dart`
- **Changement** : Remplacer `IconsRegistry.searchIcons()` par `IconSearchService.search()`

#### 2. `/lib/core/services/app_initialization_service.dart`
- **Changement** : Supprimer Étape 2 (lignes 100-136) - Initialisation icônes
- **Impact** : Startup time 25s → 2s

#### 3. `/lib/data/models/category_model.dart`
- **Changement** : Remplacer `IconDataUtils.idToIconData()` par `IconMappingUtils.idToIconData()`

#### 4. `/lib/domain/entities/category.dart`
- **Changement** : Remplacer `IconDataUtils.getDisplayIcon()` par `IconMappingUtils.getDisplayIcon()`

---

## Phase 1 : Génération du Mapping Statique

### Fichier 1.1 : `/tools_v2/icon_generator_v2/icon_extractor.dart`

```dart
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:icons_plus/icons_plus.dart';
// ... autres imports

/// Classe représentant une icône brute extraite
class RawIconEntryV2 {
  final String packageName;      // 'Bootstrap', 'Mdi', 'FontAwesome', etc.
  final String iconName;          // 'circle', 'lockMinus', 'shield_dog_solid'
  final IconData iconData;        // L'objet IconData Flutter

  RawIconEntryV2({
    required this.packageName,
    required this.iconName,
    required this.iconData,
  });

  /// Génère l'ID au format "Package.iconName"
  String get iconId => '$packageName.$iconName';
}

/// Service d'extraction des icônes depuis les packages
class IconExtractor {
  /// Extrait toutes les icônes de tous les packages supportés
  static List<RawIconEntryV2> extractAllIcons() {
    final List<RawIconEntryV2> allIcons = [];

    allIcons.addAll(_extractBootstrapIcons());
    allIcons.addAll(_extractMdiIcons());
    allIcons.addAll(_extractFontAwesomeIcons());
    allIcons.addAll(_extractAntDesignIcons());
    allIcons.addAll(_extractPhosphorIcons());
    allIcons.addAll(_extractFluentIcons());
    allIcons.addAll(_extractOtherIcons());

    print('✅ Total icons extracted: ${allIcons.length}');
    return allIcons;
  }

  /// Extrait icônes Bootstrap (bootstrap_icons package)
  static List<RawIconEntryV2> _extractBootstrapIcons() {
    final List<RawIconEntryV2> icons = [];

    // Utiliser reflection ou liste hardcodée des icônes Bootstrap
    // Exemple avec liste hardcodée (à générer automatiquement)
    final bootstrapMap = {
      'circle': BootstrapIcons.circle,
      'circle_fill': BootstrapIcons.circle_fill,
      'heart': BootstrapIcons.heart,
      'heart_fill': BootstrapIcons.heart_fill,
      // ... TOUTES les icônes Bootstrap (~2000)
    };

    bootstrapMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'Bootstrap',
        iconName: name,
        iconData: iconData,
      ));
    });

    print('✅ Bootstrap icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait icônes Material Design Icons (icons_plus - Mdi)
  static List<RawIconEntryV2> _extractMdiIcons() {
    final List<RawIconEntryV2> icons = [];

    final mdiMap = {
      'lockMinus': Mdi.lockMinus,
      'lockPlus': Mdi.lockPlus,
      'lockOpenMinus': Mdi.lockOpenMinus,
      'lockOpenPlus': Mdi.lockOpenPlus,
      // ... TOUTES les icônes Mdi (~7000)
    };

    mdiMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'Mdi',
        iconName: name,
        iconData: iconData,
      ));
    });

    print('✅ Mdi icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait icônes FontAwesome (icons_plus - FontAwesome)
  static List<RawIconEntryV2> _extractFontAwesomeIcons() {
    final List<RawIconEntryV2> icons = [];

    final fontAwesomeMap = {
      'shield_dog_solid': FontAwesome.shield_dog_solid,
      'dog': FontAwesome.dog,
      // ... TOUTES les icônes FontAwesome (~2000)
    };

    fontAwesomeMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'FontAwesome',
        iconName: name,
        iconData: iconData,
      ));
    });

    print('✅ FontAwesome icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait icônes AntDesign (icons_plus - AntDesign)
  static List<RawIconEntryV2> _extractAntDesignIcons() {
    final List<RawIconEntryV2> icons = [];

    final antDesignMap = {
      'account_book_twotone': AntDesign.account_book_twotone,
      // ... TOUTES les icônes AntDesign (~1000)
    };

    antDesignMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'AntDesign',
        iconName: name,
        iconData: iconData,
      ));
    });

    print('✅ AntDesign icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait icônes Phosphor (phosphor_flutter package - 6 styles)
  static List<RawIconEntryV2> _extractPhosphorIcons() {
    final List<RawIconEntryV2> icons = [];

    // Phosphor a 6 styles : thin, light, regular, bold, fill, duotone
    // Format : PhosphorIconsBold.heart, PhosphorIconsThin.heart, etc.

    // Exemple pour style Bold
    final phosphorBoldMap = {
      'heart': PhosphorIconsBold.heart,
      // ... TOUTES les icônes Phosphor Bold (~8000)
    };

    phosphorBoldMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'PhosphorBold',
        iconName: name,
        iconData: iconData,
      ));
    });

    // Répéter pour les autres styles (Thin, Light, Regular, Fill, Duotone)
    // ...

    print('✅ Phosphor icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait icônes Fluent UI (fluentui_system_icons package)
  static List<RawIconEntryV2> _extractFluentIcons() {
    final List<RawIconEntryV2> icons = [];

    final fluentMap = {
      'access_time_24_regular': FluentIcons.access_time_24_regular,
      // ... TOUTES les icônes Fluent (~10000)
    };

    fluentMap.forEach((name, iconData) {
      icons.add(RawIconEntryV2(
        packageName: 'Fluent',
        iconName: name,
        iconData: iconData,
      ));
    });

    print('✅ Fluent icons extracted: ${icons.length}');
    return icons;
  }

  /// Extrait autres icônes (Lucide, Solar, Health, TDesign, etc.)
  static List<RawIconEntryV2> _extractOtherIcons() {
    final List<RawIconEntryV2> icons = [];

    // Lucide
    final lucideMap = {
      // ... icônes Lucide
    };

    // Solar (3 styles : bold, outline, broken)
    final solarBoldMap = {
      // ... icônes Solar Bold
    };

    // Health Icons
    final healthMap = {
      // ... icônes Health
    };

    // TDesign
    final tdesignMap = {
      // ... icônes TDesign
    };

    // Ajouter tous ces maps aux icons
    // ...

    print('✅ Other icons extracted: ${icons.length}');
    return icons;
  }
}
```

### Fichier 1.2 : `/tools_v2/icon_generator_v2/icon_formatter.dart`

```dart
import 'icon_extractor.dart';

/// Service de formatage des entries au format final
class IconFormatter {
  /// Formate une entry brute en ligne de code pour le fichier final
  ///
  /// Input:  RawIconEntryV2(packageName: 'Bootstrap', iconName: 'circle', iconData: ...)
  /// Output: "  'Bootstrap.circle': Bootstrap.circle,"
  static String formatIconEntry(RawIconEntryV2 entry) {
    final iconId = entry.iconId; // 'Bootstrap.circle'
    final packageName = entry.packageName;
    final iconName = entry.iconName;

    // Déterminer la classe et le champ depuis packageName
    final className = _getClassNameFromPackage(packageName);
    final fieldName = iconName;

    return "  '$iconId': $className.$fieldName,";
  }

  /// Mappe le nom de package vers la classe Flutter correspondante
  ///
  /// Exemples:
  /// - 'Bootstrap' → 'BootstrapIcons'
  /// - 'Mdi' → 'Mdi'
  /// - 'FontAwesome' → 'FontAwesome'
  /// - 'PhosphorBold' → 'PhosphorIconsBold'
  static String _getClassNameFromPackage(String packageName) {
    final classNameMap = {
      'Bootstrap': 'BootstrapIcons',
      'Mdi': 'Mdi',
      'FontAwesome': 'FontAwesome',
      'AntDesign': 'AntDesign',
      'PhosphorBold': 'PhosphorIconsBold',
      'PhosphorThin': 'PhosphorIconsThin',
      'PhosphorLight': 'PhosphorIconsLight',
      'PhosphorRegular': 'PhosphorIconsRegular',
      'PhosphorFill': 'PhosphorIconsFill',
      'PhosphorDuotone': 'PhosphorIconsDuotone',
      'Fluent': 'FluentIcons',
      'Lucide': 'LucideIcons',
      'SolarBold': 'SolarIconsBold',
      'SolarOutline': 'SolarIconsOutline',
      'SolarBroken': 'SolarIconsBroken',
      'Health': 'HealthIcons',
      'TDesign': 'TDesignIcons',
    };

    return classNameMap[packageName] ?? packageName;
  }

  /// Génère les imports nécessaires pour tous les packages
  static String generateImports() {
    return '''
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_flutter.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:health_icons/health_icons.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
''';
  }

  /// Génère le header du fichier avec documentation
  static String generateHeader() {
    return '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generator: tools_v2/generate_icon_mapping.dart
// Generated: ${DateTime.now().toIso8601String()}

/// Map statique contenant toutes les icônes disponibles
///
/// Format des clés: "Package.iconName" (ex: "Bootstrap.circle", "Mdi.lockMinus")
///
/// Total: ~41,701 icônes depuis 7 packages:
/// - Bootstrap Icons (~2,000)
/// - Material Design Icons (~7,000)
/// - FontAwesome (~2,000)
/// - AntDesign (~1,000)
/// - Phosphor (~8,000 x 6 styles = ~48,000 mais optimisé)
/// - Fluent UI (~10,000)
/// - Autres (Lucide, Solar, Health, TDesign) (~5,000)
///
/// **Performance**: O(1) lookup, zero runtime initialization
/// **Taille**: ~2-3 MB compilé
///
/// Usage:
/// ```dart
/// // Récupérer une icône
/// final icon = IconMapping.getIcon('Bootstrap.circle');
///
/// // Chercher des icônes
/// final results = IconMapping.search('dog');
/// ```
''';
  }

  /// Génère le début de la classe IconMapping
  static String generateClassStart() {
    return '''
class IconMapping {
  IconMapping._(); // Constructeur privé

  /// Map statique de toutes les icônes (41,701 entrées)
  static const Map<String, IconData> _icons = {
''';
  }

  /// Génère la fin de la classe avec méthode getIcon()
  static String generateClassEnd() {
    return '''
  };

  /// Récupère une icône par son ID
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName" (ex: "Bootstrap.circle")
  ///
  /// Retourne:
  /// - IconData si trouvée
  /// - null si non trouvée
  ///
  /// Performance: O(1)
  static IconData? getIcon(String iconId) {
    return _icons[iconId];
  }

  /// Vérifie si une icône existe
  static bool hasIcon(String iconId) {
    return _icons.containsKey(iconId);
  }

  /// Obtient toutes les clés (IDs d'icônes)
  static List<String> getAllIconIds() {
    return _icons.keys.toList();
  }

  /// Nombre total d'icônes
  static int get totalIcons => _icons.length;
}
''';
  }
}
```

### Fichier 1.3 : `/tools_v2/icon_generator_v2/file_writer.dart`

```dart
import 'dart:io';
import 'icon_extractor.dart';
import 'icon_formatter.dart';

/// Service d'écriture du fichier final icon_mapping.dart
class FileWriter {
  /// Chemin du fichier de sortie
  static const String outputPath =
      'lib/core/icons_v2/icon_mapping.dart';

  /// Écrit le fichier icon_mapping.dart avec toutes les icônes
  static Future<void> writeIconMappingFile(
    List<RawIconEntryV2> icons,
  ) async {
    print('📝 Writing icon_mapping.dart to $outputPath...');

    final buffer = StringBuffer();

    // 1. Header avec documentation
    buffer.writeln(IconFormatter.generateHeader());
    buffer.writeln();

    // 2. Imports
    buffer.writeln(IconFormatter.generateImports());
    buffer.writeln();

    // 3. Début de la classe et map
    buffer.writeln(IconFormatter.generateClassStart());

    // 4. Toutes les entries formatées
    for (final icon in icons) {
      buffer.writeln(IconFormatter.formatIconEntry(icon));
    }

    // 5. Fin de la classe avec méthodes
    buffer.writeln(IconFormatter.generateClassEnd());

    // 6. Écriture du fichier
    final file = File(outputPath);
    await file.create(recursive: true);
    await file.writeAsString(buffer.toString());

    print('✅ icon_mapping.dart written successfully!');
    print('   📊 Total icons: ${icons.length}');
    print('   📦 File size: ${(buffer.length / 1024 / 1024).toStringAsFixed(2)} MB');
  }
}
```

### Fichier 1.4 : `/tools_v2/generate_icon_mapping.dart`

```dart
import 'icon_generator_v2/icon_extractor.dart';
import 'icon_generator_v2/file_writer.dart';

/// Script principal de génération du mapping d'icônes V2
///
/// Usage:
/// ```bash
/// dart run tools_v2/generate_icon_mapping.dart
/// ```
///
/// Output:
/// - lib/core/icons_v2/icon_mapping.dart
Future<void> main() async {
  print('🚀 Icon Mapping Generator V2');
  print('=' * 60);

  // Étape 1: Extraction des icônes depuis tous les packages
  print('\n📦 Step 1: Extracting icons from packages...');
  final icons = IconExtractor.extractAllIcons();

  // Étape 2: Écriture du fichier icon_mapping.dart
  print('\n📝 Step 2: Writing icon_mapping.dart...');
  await FileWriter.writeIconMappingFile(icons);

  // Étape 3: Résumé
  print('\n' + '=' * 60);
  print('✅ Generation complete!');
  print('   📊 Total icons: ${icons.length}');
  print('   📁 Output: ${FileWriter.outputPath}');
  print('\n💡 Next steps:');
  print('   1. Run: flutter analyze');
  print('   2. Verify: lib/core/icons_v2/icon_mapping.dart');
  print('   3. Test: Search functionality in icon_test_screen.dart');
}
```

### Exemple de Fichier Généré : `/lib/core/icons_v2/icon_mapping.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generator: tools_v2/generate_icon_mapping.dart
// Generated: 2025-10-04T14:30:00.000Z

/// Map statique contenant toutes les icônes disponibles
///
/// Format des clés: "Package.iconName" (ex: "Bootstrap.circle", "Mdi.lockMinus")
///
/// Total: ~41,701 icônes depuis 7 packages
///
/// **Performance**: O(1) lookup, zero runtime initialization
/// **Taille**: ~2-3 MB compilé

import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_flutter.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:health_icons/health_icons.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class IconMapping {
  IconMapping._(); // Constructeur privé

  /// Map statique de toutes les icônes (41,701 entrées)
  static const Map<String, IconData> _icons = {
    // Bootstrap Icons (~2,000)
    'Bootstrap.circle': BootstrapIcons.circle,
    'Bootstrap.circle_fill': BootstrapIcons.circle_fill,
    'Bootstrap.heart': BootstrapIcons.heart,
    'Bootstrap.heart_fill': BootstrapIcons.heart_fill,
    // ... ~2,000 icônes Bootstrap

    // Material Design Icons (~7,000)
    'Mdi.lockMinus': Mdi.lockMinus,
    'Mdi.lockPlus': Mdi.lockPlus,
    'Mdi.lockOpenMinus': Mdi.lockOpenMinus,
    'Mdi.lockOpenPlus': Mdi.lockOpenPlus,
    // ... ~7,000 icônes Mdi

    // FontAwesome (~2,000)
    'FontAwesome.shield_dog_solid': FontAwesome.shield_dog_solid,
    'FontAwesome.dog': FontAwesome.dog,
    // ... ~2,000 icônes FontAwesome

    // AntDesign (~1,000)
    'AntDesign.account_book_twotone': AntDesign.account_book_twotone,
    // ... ~1,000 icônes AntDesign

    // Phosphor Bold (~8,000)
    'PhosphorBold.heart': PhosphorIconsBold.heart,
    // ... ~8,000 icônes Phosphor Bold

    // Fluent UI (~10,000)
    'Fluent.access_time_24_regular': FluentIcons.access_time_24_regular,
    // ... ~10,000 icônes Fluent

    // Autres packages (~5,000)
    // Lucide, Solar, Health, TDesign...
  };

  /// Récupère une icône par son ID
  static IconData? getIcon(String iconId) {
    return _icons[iconId];
  }

  /// Vérifie si une icône existe
  static bool hasIcon(String iconId) {
    return _icons.containsKey(iconId);
  }

  /// Obtient toutes les clés (IDs d'icônes)
  static List<String> getAllIconIds() {
    return _icons.keys.toList();
  }

  /// Nombre total d'icônes
  static int get totalIcons => _icons.length;
}
```

---

## Phase 2 : Service de Recherche

### Fichier 2.1 : `/lib/core/icons_v2/icon_search_service.dart`

```dart
import 'package:flutter/material.dart';
import 'icon_mapping.dart';

/// Service de recherche d'icônes (stratégie simple sans keywords)
///
/// Recherche directement dans les clés de la map IconMapping._icons
/// en splitant par '.' pour isoler le nom de l'icône du package.
///
/// **Exemples de Recherche**:
/// - Query: "dog" → Résultat: ['FontAwesome.shield_dog_solid', 'FontAwesome.dog']
/// - Query: "ant" → Résultat: ['Bootstrap.elephant', 'Mdi.antenna'] (PAS toutes les AntDesign)
/// - Query: "lock" → Résultat: ['Mdi.lockMinus', 'Mdi.lockPlus', 'Bootstrap.lock_fill']
class IconSearchService {
  IconSearchService._(); // Constructeur privé

  /// Recherche d'icônes par mot-clé (simple, rapide, efficace)
  ///
  /// Paramètres:
  /// - [query]: Mot-clé à chercher (ex: "dog", "lock", "heart")
  /// - [limit]: Nombre maximum de résultats (défaut: 100)
  ///
  /// Retourne:
  /// - Liste d'IDs d'icônes correspondant au critère
  ///
  /// Algorithme:
  /// 1. Convertir query en minuscules
  /// 2. Pour chaque clé de IconMapping._icons:
  ///    - Split par '.' pour obtenir [package, iconName]
  ///    - Chercher query dans iconName uniquement
  /// 3. Limiter aux [limit] premiers résultats
  ///
  /// Performance: O(n) où n = nombre total d'icônes (~41,701)
  /// Temps estimé: ~50ms pour parcourir toutes les icônes
  static List<String> search(String query, {int limit = 100}) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final results = <String>[];

    // Parcourir toutes les clés de la map
    for (final iconId in IconMapping.getAllIconIds()) {
      // Split par '.' : ['Bootstrap', 'circle']
      final parts = iconId.split('.');
      final iconName = parts.length > 1 ? parts[1] : iconId;

      // Chercher uniquement dans le nom de l'icône (pas le package)
      if (iconName.toLowerCase().contains(queryLower)) {
        results.add(iconId);

        // Limiter les résultats
        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Recherche avec tri par pertinence
  ///
  /// Même algorithme que search() mais avec tri:
  /// 1. Correspondance exacte (iconName == query)
  /// 2. Commence par query (iconName.startsWith(query))
  /// 3. Contient query (iconName.contains(query))
  ///
  /// Paramètres:
  /// - [query]: Mot-clé à chercher
  /// - [limit]: Nombre maximum de résultats (défaut: 100)
  ///
  /// Retourne:
  /// - Liste d'IDs triée par pertinence
  static List<String> searchSorted(String query, {int limit = 100}) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final exactMatches = <String>[];
    final startMatches = <String>[];
    final containsMatches = <String>[];

    // Parcourir toutes les icônes
    for (final iconId in IconMapping.getAllIconIds()) {
      final parts = iconId.split('.');
      final iconName = parts.length > 1 ? parts[1] : iconId;
      final iconNameLower = iconName.toLowerCase();

      // Catégoriser par pertinence
      if (iconNameLower == queryLower) {
        exactMatches.add(iconId);
      } else if (iconNameLower.startsWith(queryLower)) {
        startMatches.add(iconId);
      } else if (iconNameLower.contains(queryLower)) {
        containsMatches.add(iconId);
      }
    }

    // Combiner et limiter
    final results = [
      ...exactMatches,
      ...startMatches,
      ...containsMatches,
    ];

    return results.take(limit).toList();
  }

  /// Recherche avec filtre de package optionnel
  ///
  /// Permet de chercher uniquement dans un package spécifique.
  ///
  /// Paramètres:
  /// - [query]: Mot-clé à chercher
  /// - [packageFilter]: Nom du package (ex: "Bootstrap", "Mdi", "FontAwesome")
  /// - [limit]: Nombre maximum de résultats (défaut: 100)
  ///
  /// Exemples:
  /// ```dart
  /// // Chercher "heart" uniquement dans Bootstrap
  /// final results = IconSearchService.searchWithPackage('heart', packageFilter: 'Bootstrap');
  /// // → ['Bootstrap.heart', 'Bootstrap.heart_fill']
  /// ```
  static List<String> searchWithPackage(
    String query, {
    String? packageFilter,
    int limit = 100,
  }) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final packageFilterLower = packageFilter?.toLowerCase();
    final results = <String>[];

    for (final iconId in IconMapping.getAllIconIds()) {
      final parts = iconId.split('.');

      if (parts.length < 2) continue;

      final packageName = parts[0];
      final iconName = parts[1];

      // Filtrer par package si spécifié
      if (packageFilterLower != null &&
          packageName.toLowerCase() != packageFilterLower) {
        continue;
      }

      // Chercher dans le nom de l'icône
      if (iconName.toLowerCase().contains(queryLower)) {
        results.add(iconId);

        if (results.length >= limit) break;
      }
    }

    return results;
  }

  /// Obtient l'IconData depuis un ID
  ///
  /// Wrapper autour de IconMapping.getIcon() pour cohérence API.
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName"
  ///
  /// Retourne:
  /// - IconData si trouvée
  /// - null si non trouvée
  static IconData? getIconData(String iconId) {
    return IconMapping.getIcon(iconId);
  }

  /// Obtient les packages disponibles
  ///
  /// Extrait tous les noms de packages uniques depuis les clés.
  ///
  /// Retourne:
  /// - Liste des packages disponibles (ex: ['Bootstrap', 'Mdi', 'FontAwesome', ...])
  static List<String> getAvailablePackages() {
    final packages = <String>{};

    for (final iconId in IconMapping.getAllIconIds()) {
      final parts = iconId.split('.');
      if (parts.isNotEmpty) {
        packages.add(parts[0]);
      }
    }

    return packages.toList()..sort();
  }

  /// Compte le nombre d'icônes par package
  ///
  /// Retourne:
  /// - Map<packageName, count> avec statistiques
  ///
  /// Exemple:
  /// ```dart
  /// final stats = IconSearchService.getPackageStats();
  /// // {'Bootstrap': 2000, 'Mdi': 7000, 'FontAwesome': 2000, ...}
  /// ```
  static Map<String, int> getPackageStats() {
    final stats = <String, int>{};

    for (final iconId in IconMapping.getAllIconIds()) {
      final parts = iconId.split('.');
      if (parts.isNotEmpty) {
        final packageName = parts[0];
        stats[packageName] = (stats[packageName] ?? 0) + 1;
      }
    }

    return stats;
  }
}
```

---

## Phase 3 : Utilities de Mapping

### Fichier 3.1 : `/lib/core/utils/icon_mapping_utils.dart`

```dart
import 'package:flutter/material.dart';
import 'package:bankapp/core/icons_v2/icon_mapping.dart';

/// Utilities pour conversion IconData ↔ String (V2)
///
/// Remplace icon_data_utils.dart avec approche statique (zero initialization).
///
/// **Format des IDs**: "Package.iconName" (ex: "Bootstrap.circle", "Mdi.lockMinus")
///
/// **Usage**:
/// ```dart
/// // String → IconData
/// final icon = IconMappingUtils.idToIconData('Mdi.lockMinus');
///
/// // IconData → String (reverse lookup)
/// final iconId = IconMappingUtils.iconDataToId(Mdi.lockMinus);
///
/// // Icône de fallback
/// final displayIcon = IconMappingUtils.getDisplayIcon(icon);
/// ```
class IconMappingUtils {
  IconMappingUtils._(); // Constructeur privé

  /// Icône par défaut (fallback)
  static const IconData _defaultIcon = Icons.help_outline;

  /// Convertit un ID string en IconData
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName" (ex: "Mdi.lockMinus")
  ///
  /// Retourne:
  /// - IconData si trouvée dans IconMapping
  /// - null si iconId est null/vide ou non trouvée
  ///
  /// Performance: O(1) lookup dans map statique
  ///
  /// Exemples:
  /// ```dart
  /// idToIconData('Mdi.lockMinus') → Mdi.lockMinus
  /// idToIconData('Bootstrap.circle') → Bootstrap.circle
  /// idToIconData('invalid_id') → null
  /// idToIconData(null) → null
  /// ```
  static IconData? idToIconData(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;

    return IconMapping.getIcon(iconId);
  }

  /// Convertit un IconData en ID string (reverse lookup)
  ///
  /// ⚠️ ATTENTION: Cette opération est O(n) car nécessite de parcourir
  /// toute la map pour trouver la clé correspondante.
  ///
  /// À utiliser uniquement pour des cas ponctuels (ex: debug, logs).
  /// Pour un usage intensif, conserver l'ID string directement.
  ///
  /// Paramètres:
  /// - [iconData]: L'IconData à convertir
  ///
  /// Retourne:
  /// - String ID si trouvé (ex: "Mdi.lockMinus")
  /// - null si iconData est null ou non trouvé
  ///
  /// Performance: O(n) où n = nombre total d'icônes (~41,701)
  /// Temps estimé: ~100ms pour parcourir toute la map
  ///
  /// Exemples:
  /// ```dart
  /// iconDataToId(Mdi.lockMinus) → 'Mdi.lockMinus'
  /// iconDataToId(Bootstrap.circle) → 'Bootstrap.circle'
  /// iconDataToId(customIcon) → null
  /// ```
  static String? iconDataToId(IconData? iconData) {
    if (iconData == null) return null;

    // Reverse lookup: parcourir toute la map
    for (final entry in IconMapping.getAllIconIds()) {
      if (IconMapping.getIcon(entry) == iconData) {
        return entry;
      }
    }

    return null;
  }

  /// Obtient une icône d'affichage avec fallback
  ///
  /// Garantit de toujours retourner une IconData valide pour l'UI.
  ///
  /// Paramètres:
  /// - [iconData]: IconData optionnelle
  ///
  /// Retourne:
  /// - iconData si non-null
  /// - _defaultIcon (Icons.help_outline) si null
  ///
  /// Usage typique dans entities:
  /// ```dart
  /// // category.dart
  /// IconData get displayIcon => IconMappingUtils.getDisplayIcon(icon);
  /// ```
  static IconData getDisplayIcon(IconData? iconData) {
    return iconData ?? _defaultIcon;
  }

  /// Vérifie si un ID d'icône est valide
  ///
  /// Paramètres:
  /// - [iconId]: ID à vérifier
  ///
  /// Retourne:
  /// - true si l'icône existe dans IconMapping
  /// - false sinon
  ///
  /// Performance: O(1)
  static bool isValidIconId(String? iconId) {
    if (iconId == null || iconId.isEmpty) return false;

    return IconMapping.hasIcon(iconId);
  }

  /// Extrait le nom du package depuis un ID
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName"
  ///
  /// Retourne:
  /// - Nom du package (ex: "Bootstrap", "Mdi")
  /// - null si format invalide
  ///
  /// Exemples:
  /// ```dart
  /// getPackageName('Mdi.lockMinus') → 'Mdi'
  /// getPackageName('Bootstrap.circle') → 'Bootstrap'
  /// getPackageName('invalid') → null
  /// ```
  static String? getPackageName(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;

    final parts = iconId.split('.');
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Extrait le nom de l'icône depuis un ID
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName"
  ///
  /// Retourne:
  /// - Nom de l'icône (ex: "lockMinus", "circle")
  /// - null si format invalide
  ///
  /// Exemples:
  /// ```dart
  /// getIconName('Mdi.lockMinus') → 'lockMinus'
  /// getIconName('Bootstrap.circle') → 'circle'
  /// getIconName('invalid') → null
  /// ```
  static String? getIconName(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;

    final parts = iconId.split('.');
    return parts.length > 1 ? parts[1] : null;
  }

  /// Construit un ID depuis package et nom
  ///
  /// Paramètres:
  /// - [packageName]: Nom du package (ex: "Mdi", "Bootstrap")
  /// - [iconName]: Nom de l'icône (ex: "lockMinus", "circle")
  ///
  /// Retourne:
  /// - ID formaté "Package.iconName"
  ///
  /// Exemples:
  /// ```dart
  /// buildIconId('Mdi', 'lockMinus') → 'Mdi.lockMinus'
  /// buildIconId('Bootstrap', 'circle') → 'Bootstrap.circle'
  /// ```
  static String buildIconId(String packageName, String iconName) {
    return '$packageName.$iconName';
  }
}
```

---

## Phase 4 : Refactoring ViewModels

### Fichier 4.1 : `/lib/presentation/viewmodels/screens/icon_test_view_model.dart`

**AVANT** (utilise IconsRegistry):
```dart
import 'package:bankapp/core/icons/icons_registry.dart';

class IconTestViewModel extends ChangeNotifier {
  List<IconEntry> _searchResults = [];
  List<IconEntry> get searchResults => _searchResults;

  void searchIcons(String query) {
    _searchResults = IconsRegistry.searchIcons(
      query: query,
      limit: 100,
    );
    notifyListeners();
  }
}
```

**APRÈS** (utilise IconSearchService):
```dart
import 'package:bankapp/core/icons_v2/icon_search_service.dart';
import 'package:flutter/material.dart';

/// ViewModel pour l'écran de test d'icônes
///
/// Utilise IconSearchService (V2) pour recherche sans initialisation.
class IconTestViewModel extends ChangeNotifier {
  // ========================================================================
  // STATE
  // ========================================================================

  /// Résultats de recherche (liste d'IDs d'icônes)
  List<String> _searchResults = [];
  List<String> get searchResults => _searchResults;

  /// Query de recherche actuelle
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  /// Package sélectionné pour filtrage (null = tous les packages)
  String? _selectedPackage;
  String? get selectedPackage => _selectedPackage;

  /// Mode de tri (true = tri par pertinence, false = ordre simple)
  bool _sortByRelevance = true;
  bool get sortByRelevance => _sortByRelevance;

  // ========================================================================
  // SEARCH METHODS
  // ========================================================================

  /// Recherche d'icônes par mot-clé
  ///
  /// Paramètres:
  /// - [query]: Mot-clé de recherche
  ///
  /// Met à jour _searchResults et notifie les listeners.
  void searchIcons(String query) {
    _currentQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    // Recherche avec ou sans tri par pertinence
    if (_sortByRelevance) {
      _searchResults = IconSearchService.searchSorted(
        query,
        limit: 100,
      );
    } else {
      _searchResults = IconSearchService.search(
        query,
        limit: 100,
      );
    }

    // Filtrer par package si sélectionné
    if (_selectedPackage != null) {
      _searchResults = _searchResults
          .where((iconId) => iconId.startsWith('$_selectedPackage.'))
          .toList();
    }

    notifyListeners();
  }

  /// Filtre par package
  ///
  /// Paramètres:
  /// - [packageName]: Nom du package (null = tous)
  ///
  /// Re-exécute la recherche avec le filtre appliqué.
  void setPackageFilter(String? packageName) {
    _selectedPackage = packageName;

    // Re-exécuter la recherche avec le nouveau filtre
    searchIcons(_currentQuery);
  }

  /// Toggle du mode de tri
  void toggleSortMode() {
    _sortByRelevance = !_sortByRelevance;

    // Re-exécuter la recherche avec le nouveau tri
    searchIcons(_currentQuery);
  }

  // ========================================================================
  // ICON DATA HELPERS
  // ========================================================================

  /// Obtient l'IconData depuis un ID de résultat
  ///
  /// Paramètres:
  /// - [iconId]: ID au format "Package.iconName"
  ///
  /// Retourne:
  /// - IconData si trouvée
  /// - Icons.help_outline si non trouvée (fallback)
  IconData getIconDataForResult(String iconId) {
    return IconSearchService.getIconData(iconId) ?? Icons.help_outline;
  }

  /// Obtient tous les packages disponibles
  ///
  /// Retourne:
  /// - Liste des noms de packages triée
  List<String> getAvailablePackages() {
    return IconSearchService.getAvailablePackages();
  }

  /// Obtient les statistiques par package
  ///
  /// Retourne:
  /// - Map<packageName, count>
  Map<String, int> getPackageStats() {
    return IconSearchService.getPackageStats();
  }

  // ========================================================================
  // SELECTION
  // ========================================================================

  /// Icône sélectionnée (ID)
  String? _selectedIconId;
  String? get selectedIconId => _selectedIconId;

  /// Sélectionne une icône
  ///
  /// Paramètres:
  /// - [iconId]: ID de l'icône sélectionnée
  void selectIcon(String iconId) {
    _selectedIconId = iconId;
    notifyListeners();
  }

  /// Réinitialise la sélection
  void clearSelection() {
    _selectedIconId = null;
    notifyListeners();
  }

  /// Obtient l'IconData de l'icône sélectionnée
  IconData? getSelectedIconData() {
    if (_selectedIconId == null) return null;
    return IconSearchService.getIconData(_selectedIconId!);
  }
}
```

### Fichier 4.2 : `/lib/presentation/screens/icon_test_screen.dart`

**Modifications nécessaires** (ajustements UI pour afficher IDs au lieu d'IconEntry) :

```dart
// AVANT
ListView.builder(
  itemCount: viewModel.searchResults.length,
  itemBuilder: (context, index) {
    final iconEntry = viewModel.searchResults[index];
    return ListTile(
      leading: Icon(iconEntry.iconData),
      title: Text(iconEntry.name),
      subtitle: Text(iconEntry.id),
      onTap: () => viewModel.selectIcon(iconEntry.id),
    );
  },
);

// APRÈS
ListView.builder(
  itemCount: viewModel.searchResults.length,
  itemBuilder: (context, index) {
    final iconId = viewModel.searchResults[index]; // String ID
    final iconData = viewModel.getIconDataForResult(iconId);

    // Extraire nom d'affichage depuis ID
    final parts = iconId.split('.');
    final packageName = parts.isNotEmpty ? parts[0] : '';
    final iconName = parts.length > 1 ? parts[1] : iconId;

    return ListTile(
      leading: Icon(iconData),
      title: Text(iconName), // Nom de l'icône
      subtitle: Text(packageName), // Nom du package
      onTap: () => viewModel.selectIcon(iconId),
    );
  },
);
```

---

## Phase 5 : Nettoyage Initialisation

### Fichier 5.1 : `/lib/core/services/app_initialization_service.dart`

**AVANT** (lignes 100-136) :
```dart
// ========================================================================
// ÉTAPE 2: Icons Initialization in Isolate (0.15-0.35)
// CRITIQUE: DOIT être terminé AVANT le chargement des catégories
// ========================================================================

_updateProgress(0.15, 'Initialisation des icônes en background...');

_iconsInitializationService.onProgressUpdate = (iconProgress, iconStep) {
  final mappedProgress = 0.15 + (iconProgress * 0.20);
  _updateProgress(mappedProgress, iconStep);
};

try {
  await _iconsInitializationService.initializeInIsolate(
    timeout: const Duration(seconds: 30),
  );
  completedSteps.add('Icons initialized in isolate (non-blocking)');
} on IconsInitializationException catch (e) {
  AppLogger.error(
    'AppInitializationService',
    'initialize',
    'Icons initialization failed',
    e,
  );

  return InitializationResult.failure(
    error: InitializationError.iconsInitialization,
    errorMessage: e.message,
    userMessage: e.userFriendlyMessage,
    originalException: e,
    duration: stopwatch.elapsed,
    completedSteps: completedSteps,
  );
}

_updateProgress(0.35, 'Icônes initialisées (Isolate terminé)');
```

**APRÈS** (SUPPRIMÉ - aucune initialisation nécessaire) :
```dart
// ========================================================================
// ÉTAPE 2: Icons - NO INITIALIZATION NEEDED (V2)
// ========================================================================
//
// ✅ Icons V2 utilise une map statique compilée dans icon_mapping.dart
// ✅ Aucune initialisation runtime nécessaire (zero overhead)
// ✅ Les catégories peuvent être chargées immédiatement
//
// Performance gain: -25 secondes au démarrage
// ========================================================================

_updateProgress(0.15, 'Icons prêtes (compiled map)');
completedSteps.add('Icons ready (static map, zero initialization)');
```

**Ajustement des progressions** (renuméroter les étapes) :
```dart
// Nouvelle séquence sans initialisation icônes:
// 1. User preferences (0.0-0.15)     ← INCHANGÉ
// 2. Icons ready (0.15)               ← NOUVEAU (instant)
// 3. Base data loading (0.15-0.65)    ← DÉCALÉ (avant: 0.35-0.75)
// 4. Cache initialization (0.65-0.70) ← DÉCALÉ (avant: 0.75-0.80)
// 5. Exchange rates (0.70-0.80)       ← DÉCALÉ (avant: 0.80-0.90)
// 6. Finalization (0.80-1.0)          ← DÉCALÉ (avant: 0.90-1.0)
```

**Code complet de la nouvelle séquence** :
```dart
try {
  // ========================================================================
  // ÉTAPE 1: User Preferences (0.0-0.15)
  // ========================================================================
  _updateProgress(0.05, 'Chargement des préférences utilisateur...');
  await _userPreferencesService.init();
  completedSteps.add('User preferences loaded');
  _updateProgress(0.15, 'Préférences chargées');

  // ========================================================================
  // ÉTAPE 2: Icons Ready (0.15)
  // NO INITIALIZATION - Map statique compilée
  // ========================================================================
  completedSteps.add('Icons ready (static map, zero initialization)');

  // ========================================================================
  // ÉTAPE 3: Load Base Data (0.15-0.65)
  // Les catégories peuvent être chargées IMMÉDIATEMENT
  // ========================================================================
  _updateProgress(0.20, 'Chargement des comptes...');
  final accounts = await _accountDataSource.getAllAccounts();
  completedSteps.add('Accounts loaded: ${accounts.length}');

  _updateProgress(0.30, 'Chargement des transactions...');
  final transactions = await _transactionDataSource.getAllTransactions();
  completedSteps.add('Transactions loaded: ${transactions.length}');

  _updateProgress(0.40, 'Chargement des catégories...');
  // ✅ CategoryModel.toEntity() utilise désormais IconMappingUtils.idToIconData()
  // ✅ Aucune attente nécessaire, map statique déjà disponible
  final categories = await _categoryDataSource.getAllCategories();
  completedSteps.add('Categories loaded: ${categories.length}');

  _updateProgress(0.50, 'Chargement des contreparties...');
  final counterparties = await _counterpartyDataSource.getAllCounterparties();
  completedSteps.add('Counterparties loaded: ${counterparties.length}');

  _updateProgress(0.55, 'Chargement des transactions suivies...');
  final followedTransactions = await _transactionDataSource.getAllFollowedTransactions();
  completedSteps.add('Followed transactions loaded: ${followedTransactions.length}');

  _updateProgress(0.60, 'Chargement des taux de change...');
  final exchangeRates = _exchangeRateLocalDataSource != null
      ? await _exchangeRateLocalDataSource.getAllRates()
      : <ExchangeRateModel>[];
  completedSteps.add('Exchange rates loaded: ${exchangeRates.length}');

  // ========================================================================
  // ÉTAPE 4: Cache Initialization (0.65-0.70)
  // ========================================================================
  _updateProgress(0.65, 'Initialisation du cache...');
  await _cacheManager.initialize(
    accounts: accounts,
    transactions: transactions,
    categories: categories,
    counterparties: counterparties,
    followedTransactions: followedTransactions,
    exchangeRates: exchangeRates,
  );

  if (!_cacheManager.isInitialized) {
    throw CacheInitializationException('Cache initialization failed');
  }

  completedSteps.add('Cache initialized successfully');
  _updateProgress(0.70, 'Cache initialisé');

  // ========================================================================
  // ÉTAPE 5: Exchange Rates (0.70-0.80)
  // ========================================================================
  if (_smartExchangeRateService != null) {
    _updateProgress(0.75, 'Synchronisation des taux de change...');
    try {
      await _smartLoadExchangeRates();
      completedSteps.add('Exchange rates synchronized');
    } catch (e) {
      AppLogger.warning(
        'AppInitializationService',
        'initialize',
        'Exchange rates synchronization failed (non-blocking)',
        error: e,
      );
      completedSteps.add('Exchange rates failed (non-critical)');
    }
  }

  _updateProgress(0.80, 'Finalisation...');

  // ========================================================================
  // ÉTAPE 6: Finalization (0.80-1.0)
  // ========================================================================
  stopwatch.stop();
  _updateProgress(1.0, 'Initialisation terminée');

  AppLogger.info(
    'AppInitializationService',
    'initialize',
    '✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms',
  );

  return InitializationResult.success(
    duration: stopwatch.elapsed,
    completedSteps: completedSteps,
  );
} catch (error, stackTrace) {
  // ... error handling
}
```

### Fichier 5.2 : `/lib/data/models/category_model.dart`

**AVANT** :
```dart
import 'package:bankapp/core/utils/icon_data_utils.dart';

domain.Category toEntity() {
  return domain.Category(
    id: id,
    label: label,
    level: level,
    parentId: parentId,
    icon: IconDataUtils.idToIconData(icon), // ← ANCIEN
    iconColor: ColorUtils.fromHex(iconColor),
  );
}
```

**APRÈS** :
```dart
import 'package:bankapp/core/utils/icon_mapping_utils.dart';

domain.Category toEntity() {
  return domain.Category(
    id: id,
    label: label,
    level: level,
    parentId: parentId,
    icon: IconMappingUtils.idToIconData(icon), // ← NOUVEAU
    iconColor: ColorUtils.fromHex(iconColor),
  );
}
```

### Fichier 5.3 : `/lib/domain/entities/category.dart`

**AVANT** :
```dart
import 'package:bankapp/core/utils/icon_data_utils.dart';

final IconData? icon;
IconData get displayIcon => IconDataUtils.getDisplayIcon(icon);
```

**APRÈS** :
```dart
import 'package:bankapp/core/utils/icon_mapping_utils.dart';

final IconData? icon;
IconData get displayIcon => IconMappingUtils.getDisplayIcon(icon);
```

### Fichier 5.4 : Suppression de `_iconsInitializationService` du constructeur

**AVANT** (`app_initialization_service.dart:43-62`) :
```dart
AppInitializationService({
  required CacheManager cacheManager,
  required AccountLocalDataSource accountDataSource,
  required TransactionLocalDataSource transactionDataSource,
  required CategoryLocalDataSource categoryDataSource,
  required CounterpartyLocalDataSource counterpartyDataSource,
  required UserPreferencesService userPreferencesService,
  ExchangeRateLocalDataSource? exchangeRateLocalDataSource,
  SmartExchangeRateService? smartExchangeRateService,
  IconsInitializationService? iconsInitializationService, // ← SUPPRIMER
}) : _cacheManager = cacheManager,
     _accountDataSource = accountDataSource,
     _transactionDataSource = transactionDataSource,
     _categoryDataSource = categoryDataSource,
     _counterpartyDataSource = counterpartyDataSource,
     _userPreferencesService = userPreferencesService,
     _exchangeRateLocalDataSource = exchangeRateLocalDataSource,
     _smartExchangeRateService = smartExchangeRateService,
     _iconsInitializationService =
         iconsInitializationService ?? IconsInitializationService(); // ← SUPPRIMER
```

**APRÈS** :
```dart
AppInitializationService({
  required CacheManager cacheManager,
  required AccountLocalDataSource accountDataSource,
  required TransactionLocalDataSource transactionDataSource,
  required CategoryLocalDataSource categoryDataSource,
  required CounterpartyLocalDataSource counterpartyDataSource,
  required UserPreferencesService userPreferencesService,
  ExchangeRateLocalDataSource? exchangeRateLocalDataSource,
  SmartExchangeRateService? smartExchangeRateService,
  // IconsInitializationService SUPPRIMÉ - plus nécessaire
}) : _cacheManager = cacheManager,
     _accountDataSource = accountDataSource,
     _transactionDataSource = transactionDataSource,
     _categoryDataSource = categoryDataSource,
     _counterpartyDataSource = counterpartyDataSource,
     _userPreferencesService = userPreferencesService,
     _exchangeRateLocalDataSource = exchangeRateLocalDataSource,
     _smartExchangeRateService = smartExchangeRateService;
     // _iconsInitializationService SUPPRIMÉ
```

**Supprimer aussi le champ** (ligne 37) :
```dart
// SUPPRIMER cette ligne:
final IconsInitializationService _iconsInitializationService;
```

---

## Phase 6 : Validation et Tests

### 6.1 : Checklist de Validation

#### ✅ Étape 1 : Génération du Mapping

**Commande** :
```bash
dart run tools_v2/generate_icon_mapping.dart
```

**Vérifications** :
- [ ] Script s'exécute sans erreur
- [ ] Fichier `lib/core/icons_v2/icon_mapping.dart` créé
- [ ] Taille du fichier : ~2-3 MB
- [ ] Nombre d'icônes : ~41,701
- [ ] Format des clés : `Package.iconName` (ex: `'Bootstrap.circle': BootstrapIcons.circle,`)
- [ ] Imports corrects en haut du fichier

**Commande de vérification** :
```bash
flutter analyze lib/core/icons_v2/icon_mapping.dart
```

**Résultat attendu** :
```
Analyzing lib/core/icons_v2/icon_mapping.dart...
No issues found!
```

#### ✅ Étape 2 : Compilation du Code

**Commande** :
```bash
flutter analyze
```

**Vérifications** :
- [ ] Aucune erreur de compilation
- [ ] Aucun warning critique
- [ ] Tous les imports résolus

**Si erreurs** :
- Vérifier les imports dans `icon_mapping.dart`
- Vérifier que tous les packages sont dans `pubspec.yaml`
- Vérifier les noms de classes (Bootstrap → BootstrapIcons, etc.)

#### ✅ Étape 3 : Test de Recherche d'Icônes

**Test 1 : Recherche simple**
```dart
// Dans icon_test_screen.dart ou console
final results = IconSearchService.search('dog');
print('Results for "dog": ${results.length}');
// Attendu: 5-10 résultats contenant "dog" dans le nom

final icons = results.map((id) => IconSearchService.getIconData(id)).toList();
// Attendu: Liste d'IconData valides
```

**Test 2 : Recherche triée**
```dart
final results = IconSearchService.searchSorted('lock');
print('Results for "lock": $results');
// Attendu: ['Mdi.lock', 'Mdi.lockMinus', 'Mdi.lockPlus', 'Bootstrap.lock_fill', ...]
// Ordre: Exact > StartsWith > Contains
```

**Test 3 : Recherche avec filtre package**
```dart
final results = IconSearchService.searchWithPackage('heart', packageFilter: 'Bootstrap');
print('Bootstrap hearts: $results');
// Attendu: ['Bootstrap.heart', 'Bootstrap.heart_fill']
```

**Test 4 : Packages disponibles**
```dart
final packages = IconSearchService.getAvailablePackages();
print('Packages: $packages');
// Attendu: ['AntDesign', 'Bootstrap', 'Fluent', 'FontAwesome', 'Mdi', 'PhosphorBold', ...]
```

#### ✅ Étape 4 : Test de Conversion IconData ↔ String

**Test 1 : String → IconData**
```dart
final icon1 = IconMappingUtils.idToIconData('Mdi.lockMinus');
print('Icon1: $icon1'); // Attendu: IconData(U+0F033)

final icon2 = IconMappingUtils.idToIconData('Bootstrap.circle');
print('Icon2: $icon2'); // Attendu: IconData valide

final icon3 = IconMappingUtils.idToIconData('InvalidId');
print('Icon3: $icon3'); // Attendu: null

final icon4 = IconMappingUtils.idToIconData(null);
print('Icon4: $icon4'); // Attendu: null
```

**Test 2 : Validation d'ID**
```dart
print(IconMappingUtils.isValidIconId('Mdi.lockMinus')); // true
print(IconMappingUtils.isValidIconId('Bootstrap.circle')); // true
print(IconMappingUtils.isValidIconId('InvalidId')); // false
print(IconMappingUtils.isValidIconId(null)); // false
```

**Test 3 : Extraction package/nom**
```dart
print(IconMappingUtils.getPackageName('Mdi.lockMinus')); // 'Mdi'
print(IconMappingUtils.getIconName('Mdi.lockMinus')); // 'lockMinus'

print(IconMappingUtils.buildIconId('Bootstrap', 'circle')); // 'Bootstrap.circle'
```

**Test 4 : Fallback icon**
```dart
final displayIcon = IconMappingUtils.getDisplayIcon(null);
print('Fallback: $displayIcon'); // Attendu: Icons.help_outline
```

#### ✅ Étape 5 : Test de Chargement des Catégories

**Vérification dans initial_data.dart** :
```dart
// Les catégories utilisent le nouveau format
CategoriesCompanion(
  label: const Value('fixedExpenses'),
  level: const Value(2),
  parentId: Value(expensesCategoryId),
  icon: const Value('Mdi.lockMinus'), // ✅ Format V2
),
```

**Test de conversion Model → Entity** :
```dart
// Dans category_model.dart
final categoryModel = CategoryModel(
  id: 1,
  label: 'fixedExpenses',
  level: 2,
  parentId: 1,
  icon: 'Mdi.lockMinus',
  iconColor: '#FF0000',
);

final categoryEntity = categoryModel.toEntity();
print('Icon: ${categoryEntity.icon}'); // Attendu: IconData valide (Mdi.lockMinus)
print('Display Icon: ${categoryEntity.displayIcon}'); // Attendu: IconData valide
```

#### ✅ Étape 6 : Test du Temps de Démarrage

**Méthode 1 : Logs dans app_initialization_service.dart**
```dart
// Déjà présent (ligne 236):
AppLogger.info(
  'AppInitializationService',
  'initialize',
  '✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms',
);
```

**Commande** :
```bash
flutter run --release
```

**Vérification dans les logs** :
```
[AppInitializationService] initialize: ✅ App initialization completed in 2000ms
```

**Attendu** :
- **AVANT** : ~25,000ms (25 secondes)
- **APRÈS** : ~2,000ms (2 secondes)
- **Gain** : 92% de réduction

**Méthode 2 : Mesure manuelle avec chronomètre**
- Lancer l'app en mode release
- Chronométrer depuis splash screen jusqu'à écran principal
- Attendu : 2-3 secondes maximum

#### ✅ Étape 7 : Test de l'Écran icon_test_screen.dart

**Scénario 1 : Recherche basique**
1. Ouvrir `icon_test_screen.dart`
2. Taper "dog" dans la barre de recherche
3. Vérifier que les résultats s'affichent
4. Vérifier que les icônes sont correctement rendues

**Scénario 2 : Sélection d'icône**
1. Chercher "lock"
2. Sélectionner "Mdi.lockMinus"
3. Vérifier que l'icône est bien sélectionnée
4. Vérifier que `viewModel.selectedIconId == 'Mdi.lockMinus'`

**Scénario 3 : Filtre par package**
1. Chercher "heart"
2. Sélectionner package "Bootstrap"
3. Vérifier que seuls les résultats Bootstrap apparaissent
4. Désélectionner le filtre
5. Vérifier que tous les résultats réapparaissent

**Scénario 4 : Mode de tri**
1. Chercher "circle"
2. Activer tri par pertinence
3. Vérifier que "Bootstrap.circle" apparaît en premier (exact match)
4. Vérifier que "Bootstrap.circle_fill" apparaît ensuite (starts with)
5. Vérifier que "Mdi.circle_outline" apparaît plus bas (contains)

#### ✅ Étape 8 : Test de Régression

**Cas 1 : Affichage des catégories dans l'app**
1. Lancer l'app
2. Naviguer vers écran des catégories
3. Vérifier que toutes les icônes s'affichent correctement
4. Vérifier "Dépenses fixes" → Icône Mdi.lockMinus
5. Vérifier "Revenus fixes" → Icône Mdi.lockPlus

**Cas 2 : Création de catégorie avec icône**
1. Créer une nouvelle catégorie
2. Sélectionner une icône via icon_test_screen.dart
3. Sauvegarder
4. Vérifier que l'icône s'affiche dans la liste

**Cas 3 : Modification de catégorie**
1. Éditer une catégorie existante
2. Changer l'icône
3. Sauvegarder
4. Vérifier que la nouvelle icône s'affiche

#### ✅ Étape 9 : Test de Performance

**Mesure 1 : Lookup performance**
```dart
final stopwatch = Stopwatch()..start();

for (int i = 0; i < 1000; i++) {
  IconMapping.getIcon('Mdi.lockMinus');
}

stopwatch.stop();
print('1000 lookups in ${stopwatch.elapsedMicroseconds}µs');
// Attendu: <1000µs (1ms) → ~1µs par lookup
```

**Mesure 2 : Search performance**
```dart
final stopwatch = Stopwatch()..start();

final results = IconSearchService.search('heart');

stopwatch.stop();
print('Search completed in ${stopwatch.elapsedMilliseconds}ms');
// Attendu: <100ms pour parcourir 41,701 icônes
```

**Mesure 3 : Memory usage**
- Ouvrir DevTools
- Observer heap size avant/après chargement icon_mapping.dart
- Attendu : ~50 MB (vs ~200 MB avec ancien système)

#### ✅ Étape 10 : Cleanup Final

**Vérifications** :
- [ ] Dossier `/tools` intact (backup)
- [ ] Dossier `/lib/core/icons` intact (backup)
- [ ] Fichier `icon_data_utils.dart` intact (backup)
- [ ] Nouveaux dossiers `/tools_v2` et `/lib/core/icons_v2` créés
- [ ] Nouveau fichier `icon_mapping_utils.dart` créé
- [ ] Aucune référence à `IconsRegistry` dans le code actif
- [ ] Aucune référence à `IconDataUtils` dans le code actif (remplacé par `IconMappingUtils`)
- [ ] Aucune référence à `IconsInitializationService` dans `app_initialization_service.dart`

**Commande finale** :
```bash
flutter analyze
flutter test
flutter build apk --release
```

**Attendu** :
- ✅ Aucune erreur
- ✅ Tous les tests passent
- ✅ Build réussit

---

## 10. Checklist de Déploiement

### Phase 1 : Préparation
- [ ] Backup complet du projet
- [ ] Créer branche Git : `git checkout -b feature/icons-v2-refactoring`
- [ ] Commit état actuel : `git commit -m "Backup before icons V2 refactoring"`

### Phase 2 : Génération
- [ ] Créer `/tools_v2/icon_generator_v2/icon_extractor.dart`
- [ ] Créer `/tools_v2/icon_generator_v2/icon_formatter.dart`
- [ ] Créer `/tools_v2/icon_generator_v2/file_writer.dart`
- [ ] Créer `/tools_v2/generate_icon_mapping.dart`
- [ ] Exécuter : `dart run tools_v2/generate_icon_mapping.dart`
- [ ] Vérifier : `lib/core/icons_v2/icon_mapping.dart` créé et valide
- [ ] Commit : `git commit -m "Add icons V2 generation scripts and generated mapping"`

### Phase 3 : Services
- [ ] Créer `/lib/core/icons_v2/icon_search_service.dart`
- [ ] Créer `/lib/core/utils/icon_mapping_utils.dart`
- [ ] Tester les méthodes de recherche (voir Étape 3 validation)
- [ ] Tester les méthodes de conversion (voir Étape 4 validation)
- [ ] Commit : `git commit -m "Add icons V2 search service and mapping utils"`

### Phase 4 : Refactoring
- [ ] Modifier `/lib/presentation/viewmodels/screens/icon_test_view_model.dart`
- [ ] Modifier `/lib/presentation/screens/icon_test_screen.dart`
- [ ] Tester icon_test_screen.dart (voir Étape 7 validation)
- [ ] Commit : `git commit -m "Refactor icon test screen to use icons V2"`

### Phase 5 : Nettoyage Initialisation
- [ ] Modifier `/lib/core/services/app_initialization_service.dart` :
  - [ ] Supprimer Étape 2 (Icons Initialization)
  - [ ] Supprimer champ `_iconsInitializationService`
  - [ ] Supprimer paramètre constructeur `IconsInitializationService`
  - [ ] Ajuster progressions (0.15-0.35 → 0.15)
- [ ] Modifier `/lib/data/models/category_model.dart` :
  - [ ] Remplacer `IconDataUtils` par `IconMappingUtils`
- [ ] Modifier `/lib/domain/entities/category.dart` :
  - [ ] Remplacer `IconDataUtils` par `IconMappingUtils`
- [ ] Commit : `git commit -m "Remove icons initialization from app startup"`

### Phase 6 : Tests et Validation
- [ ] Exécuter : `flutter analyze` (aucune erreur)
- [ ] Tester temps de démarrage (voir Étape 6 validation)
- [ ] Tester affichage catégories (voir Étape 8 validation)
- [ ] Tester recherche icônes (voir Étape 7 validation)
- [ ] Tester performance (voir Étape 9 validation)
- [ ] Commit : `git commit -m "Validate icons V2 system - all tests passed"`

### Phase 7 : Cleanup et Documentation
- [ ] Vérifier que `/tools`, `/lib/core/icons`, `icon_data_utils.dart` sont intacts (backup)
- [ ] Mettre à jour `_README.md` avec nouvelle architecture
- [ ] Documenter le nouveau système dans `_README.md`
- [ ] Commit : `git commit -m "Update documentation for icons V2"`

### Phase 8 : Merge et Release
- [ ] Créer Pull Request
- [ ] Review du code
- [ ] Merge dans `main` : `git checkout main && git merge feature/icons-v2-refactoring`
- [ ] Tag de version : `git tag v2.0.0-icons-refactoring`
- [ ] Push : `git push origin main --tags`

### Phase 9 : Monitoring Post-Déploiement
- [ ] Surveiller crashlytics/analytics pour erreurs liées aux icônes
- [ ] Surveiller performance du démarrage dans production
- [ ] Recueillir feedback utilisateurs sur temps de chargement

---

## Résumé Technique

### Avant Refactoring
```
📊 Statistiques AVANT:
- Temps démarrage : ~25 secondes
- Mémoire : ~200 MB
- Initialisation : IconsInitializationService (Isolate background)
- Architecture : Dynamic registry avec IconEntry objects
- Format IDs : underscore (bootstrap_circle, mdi_lock_minus)
- Recherche : Keywords générés + segmentation par famille
```

### Après Refactoring
```
📊 Statistiques APRÈS:
- Temps démarrage : ~2 secondes (-92%)
- Mémoire : ~50 MB (-75%)
- Initialisation : AUCUNE (map statique compilée)
- Architecture : Static map Map<String, IconData>
- Format IDs : dot notation (Bootstrap.circle, Mdi.lockMinus)
- Recherche : Filtrage simple sur clés (split par '.')
```

### Gains de Performance
```
✅ Startup time : 25s → 2s (92% réduction)
✅ Memory usage : 200 MB → 50 MB (75% réduction)
✅ Lookup time : 0.1ms → 0.01ms (10x plus rapide)
✅ Code complexity : High → Low (simplicité accrue)
✅ Maintainability : Medium → High (code généré auto-documenté)
```

---

## Annexe : Commandes Utiles

### Génération
```bash
# Générer icon_mapping.dart
dart run tools_v2/generate_icon_mapping.dart

# Analyser le fichier généré
flutter analyze lib/core/icons_v2/icon_mapping.dart
```

### Tests
```bash
# Analyse complète
flutter analyze

# Tests unitaires
flutter test

# Tests de performance
flutter run --profile

# Build release
flutter build apk --release
```

### Debug
```bash
# Activer logs détaillés
flutter run --verbose

# Observer DevTools
flutter run --dart-define=DEBUG_ICONS=true
```

### Git
```bash
# Créer branche refactoring
git checkout -b feature/icons-v2-refactoring

# Commit étapes
git add .
git commit -m "Phase X: Description"

# Merge dans main
git checkout main
git merge feature/icons-v2-refactoring
```

---

**FIN DU PLAN D'ARCHITECTURE**

Ce document doit permettre de réimplémenter le refactoring complet dans une future session sans contexte préalable. Tous les noms de fichiers, classes, méthodes et variables sont spécifiés avec précision.
