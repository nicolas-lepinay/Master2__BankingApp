/// Parser pour extraire les icônes depuis le code source d'icons_plus
///
/// Ce module analyse les fichiers Dart d'icons_plus et extrait toutes les
/// déclarations IconData pour les convertir en modèles exploitables.
library;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'models.dart';

/// Parser principal pour analyser les fichiers d'icônes
class IconsPlusParser {
  /// Chemin vers le package icons_plus
  final String packagePath;

  /// Pattern RegExp pour capturer les déclarations d'icônes
  static final RegExp _iconPattern = RegExp(
    r'static\s+const\s+(\w+)\s*=\s*\w*IconData\(0x([0-9a-fA-F]+)',
    multiLine: true,
  );

  const IconsPlusParser(this.packagePath);

  /// Parse un fichier source d'icônes et extrait toutes les IconData
  List<ParsedIcon> parseIconFile(String filePath) {
    print('🔍 Parsing: ${path.basename(filePath)}');

    try {
      final fileContent = File(filePath).readAsStringSync();
      final icons = <ParsedIcon>[];

      final matches = _iconPattern.allMatches(fileContent);

      for (final match in matches) {
        final iconName = match.group(1)!; // ex: "heart_fill"
        final codePoint = match.group(2)!; // ex: "f1a3"

        final className = _extractClassNameFromPath(filePath);

        icons.add(
          ParsedIcon(
            name: iconName,
            codePoint: codePoint,
            fontFamily: className,
            className: className,
          ),
        );
      }

      print('   ✅ ${icons.length} icônes extraites');
      return icons;
    } catch (e) {
      print('   ❌ Erreur de parsing: $e');
      return [];
    }
  }

  /// Parse tous les fichiers d'icônes du package
  Map<String, List<ParsedIcon>> parseAllIconFiles() {
    print('🚀 Début du parsing du package icons_plus...');
    print('📁 Chemin: $packagePath');

    final iconSets = <String, List<ParsedIcon>>{};

    // Analyser le dossier src/ du package icons_plus
    final srcDir = Directory(
      '$packagePath${Platform.pathSeparator}lib${Platform.pathSeparator}src',
    );

    if (!srcDir.existsSync()) {
      print('❌ Dossier src non trouvé: ${srcDir.path}');
      return iconSets;
    }

    print('📂 Scanning: ${srcDir.path}');

    try {
      final dartFiles = srcDir
          .listSync()
          .where((file) => file is File && file.path.endsWith('.dart'))
          .cast<File>()
          .toList();

      print('📊 ${dartFiles.length} fichiers .dart détectés');

      for (final file in dartFiles) {
        final className = _extractClassNameFromPath(file.path);
        final icons = parseIconFile(file.path);

        if (icons.isNotEmpty) {
          iconSets[className] = icons;
        }
      }

      // Afficher le résumé
      final totalIcons = iconSets.values
          .map((icons) => icons.length)
          .fold(0, (a, b) => a + b);
      print('\n📈 Résumé du parsing:');
      print('   📦 Sets traités: ${iconSets.length}');
      print('   🎯 Total icônes: $totalIcons');

      for (final entry in iconSets.entries) {
        print('   📋 ${entry.key}: ${entry.value.length} icônes');
      }
    } catch (e) {
      print('❌ Erreur lors du scanning: $e');
    }

    return iconSets;
  }

  /// Extrait le nom de la classe depuis le chemin du fichier
  String _extractClassNameFromPath(String filePath) {
    final fileName = path.basenameWithoutExtension(filePath);

    // Mapping spécifique pour les noms de classes d'icons_plus
    const classNameMapping = {
      'antdesign': 'AntDesign',
      'bootstrap': 'Bootstrap',
      'boxicons': 'BoxIcons',
      'clarity': 'Clarity',
      'evaicons': 'EvaIcons',
      'fontawesome': 'FontAwesome',
      'heroicons': 'HeroIcons',
      'iconsax': 'Iconsax',
      'ionicons': 'IonIcons',
      'lineawesome': 'LineAwesome',
      'mingcute': 'MingCute',
      'octicons': 'OctIcons',
      'pixelarticons': 'PixelArtIcons',
      'teenyicons': 'TeenyIcons',
      'zondicons': 'ZondIcons',
      'brand': 'Brand',
      'flag': 'Flag',
    };

    return classNameMapping[fileName] ??
        _capitalizeFirst(_snakeToCamel(fileName));
  }

  /// Convertit snake_case en CamelCase
  String _snakeToCamel(String input) {
    if (!input.contains('_')) {
      return input;
    }

    final parts = input.split('_');
    return parts.map((part) => _capitalizeFirst(part)).join('');
  }

  /// Met en majuscule la première lettre
  String _capitalizeFirst(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// Valide qu'un fichier contient des déclarations d'icônes
  bool validateIconFile(String filePath) {
    try {
      final content = File(filePath).readAsStringSync();

      // Vérifier qu'il y a au moins une déclaration IconData
      final hasIconData = content.contains('IconData(');

      // Vérifier qu'il y a des déclarations static const
      final hasStaticConst = content.contains('static const IconData');

      return hasIconData && hasStaticConst;
    } catch (e) {
      return false;
    }
  }

  /// Obtient des informations détaillées sur le package
  PackageInfo getPackageInfo() {
    final srcDir = Directory(
      '$packagePath${Platform.pathSeparator}lib${Platform.pathSeparator}src',
    );

    if (!srcDir.existsSync()) {
      return PackageInfo.empty();
    }

    final dartFiles = srcDir
        .listSync()
        .where((file) => file is File && file.path.endsWith('.dart'))
        .cast<File>()
        .toList();

    final validFiles = dartFiles
        .where((file) => validateIconFile(file.path))
        .toList();

    final setNames = validFiles
        .map((file) => _extractClassNameFromPath(file.path))
        .toList();

    return PackageInfo(
      packagePath: packagePath,
      totalFiles: dartFiles.length,
      validFiles: validFiles.length,
      setNames: setNames,
    );
  }
}

/// Informations sur le package icons_plus
class PackageInfo {
  final String packagePath;
  final int totalFiles;
  final int validFiles;
  final List<String> setNames;

  const PackageInfo({
    required this.packagePath,
    required this.totalFiles,
    required this.validFiles,
    required this.setNames,
  });

  factory PackageInfo.empty() => const PackageInfo(
    packagePath: '',
    totalFiles: 0,
    validFiles: 0,
    setNames: [],
  );

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('📦 Informations Package icons_plus:');
    buffer.writeln('   📁 Chemin: $packagePath');
    buffer.writeln('   📄 Fichiers totaux: $totalFiles');
    buffer.writeln('   ✅ Fichiers valides: $validFiles');
    buffer.writeln('   🎨 Sets disponibles: ${setNames.join(', ')}');
    return buffer.toString();
  }
}
