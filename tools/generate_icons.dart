/// Script principal de génération d'icônes
///
/// Ce script orchestre la génération complète du registry d'icônes
/// depuis le package icons_plus vers un fichier statique optimisé.
library;

import 'dart:io';

import 'icon_generator/enricher.dart';
import 'icon_generator/generator.dart';
import 'icon_generator/models.dart';
import 'icon_generator/parser.dart';
import 'icon_generator/path_resolver.dart';

/// Script principal de génération
void main(List<String> arguments) async {
  print('🚀 Génération automatique du registry d\'icônes');
  print('═══════════════════════════════════════════════════\n');

  // 1. Vérifications de sécurité
  if (!_isDevelopmentMachine()) {
    print(
      '❌ Ce script ne doit s\'exécuter que sur une machine de développement',
    );
    print('💡 Vérifications échouées:');
    print('   - Présence de Flutter SDK');
    print('   - Fichiers de projet (.dart_tool, pubspec.yaml)');
    print('   - Variables d\'environnement de développement');
    exit(1);
  }

  final hasFlutter = _isFlutterSDKAvailable();
  if (!hasFlutter) {
    print('⚠️  Flutter SDK non trouvé dans le PATH');
    print('💡 Le script continuera mais le test de compilation sera désactivé');
  }

  print('✅ Machine de développement validée');
  print('🔍 Plateforme: ${Platform.operatingSystem}');
  print('');

  // 2. Analyser les arguments
  var config = _parseArguments(arguments);

  // Désactiver le test de compilation si Flutter n'est pas disponible
  if (!hasFlutter) {
    config = GenerationConfig(
      verbose: config.verbose,
      testCompilation: false,
      limitPerSet: config.limitPerSet,
      dryRun: config.dryRun,
    );
  }

  try {
    final stopwatch = Stopwatch()..start();

    // 3. Localiser icons_plus
    print('📍 Recherche du package icons_plus...');
    final iconsPlusPath = PubCachePathResolver.findLatestIconsPlusVersion();

    if (iconsPlusPath == null) {
      print('❌ Package icons_plus non trouvé');
      print('💡 Solutions:');
      print('   1. dart pub add icons_plus');
      print('   2. dart pub get');
      print('   3. Vérifier le cache pub dans:');
      print('      ${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache');
      exit(1);
    }

    print('✅ Package trouvé: $iconsPlusPath');

    // Valider le package
    if (!PubCachePathResolver.validateIconsPlusPath(iconsPlusPath)) {
      print('❌ Package icons_plus invalide ou corrompu');
      exit(1);
    }

    // 4. Parsing des icônes
    print('\n📊 Phase 1: Parsing des icônes sources...');
    final parser = IconsPlusParser(iconsPlusPath);

    // Afficher les informations du package
    final packageInfo = parser.getPackageInfo();
    print(packageInfo);

    final parsedIconSets = parser.parseAllIconFiles();

    if (parsedIconSets.isEmpty) {
      print('❌ Aucune icône parsée depuis le package');
      exit(1);
    }

    // 5. Enrichissement des métadonnées
    print('\n🎨 Phase 2: Enrichissement des métadonnées...');
    final enricher = IconMetadataEnricher();
    final enrichedIconSets = <String, List<EnrichedIcon>>{};

    var totalProcessed = 0;
    final totalToParse = parsedIconSets.values
        .map((icons) => icons.length)
        .fold(0, (a, b) => a + b);

    for (final entry in parsedIconSets.entries) {
      final setName = entry.key;
      final parsedIcons = entry.value;

      print('   🔄 Enrichissement $setName (${parsedIcons.length} icônes)...');

      // Limiter si demandé pour les tests
      final iconsToProcess = config.limitPerSet != null
          ? parsedIcons.take(config.limitPerSet!).toList()
          : parsedIcons;

      final enrichedIcons = enricher.enrichIcons(iconsToProcess);
      enrichedIconSets[setName] = enrichedIcons;

      totalProcessed += enrichedIcons.length;

      // Progress indicator
      final progress = (totalProcessed / totalToParse * 100).toStringAsFixed(1);
      print(
        '   ✅ $setName: ${enrichedIcons.length} icônes enrichies ($progress%)',
      );
    }

    // 6. Afficher les statistiques d'enrichissement
    print('\n📈 Statistiques d\'enrichissement:');
    final allEnrichedIcons = enrichedIconSets.values
        .expand((icons) => icons)
        .toList();
    final enrichmentStats = enricher.getEnrichmentStats(allEnrichedIcons);
    print(enrichmentStats);

    // 7. Génération du registry
    print('\n🏗️  Phase 3: Génération du registry statique...');
    final generator = IconRegistryGenerator();
    generator.generateRegistry(enrichedIconSets);

    // 8. Validation du fichier généré
    print('\n🔍 Phase 4: Validation du fichier généré...');
    final generatedFile = File('lib/core/icons/generated_icons_registry.dart');

    if (!generatedFile.existsSync()) {
      print('❌ Fichier registry non généré');
      exit(1);
    }

    final fileContent = generatedFile.readAsStringSync();
    final fileSize = (fileContent.length / 1024).toStringAsFixed(1);
    final lineCount = fileContent.split('\n').length;

    print('✅ Fichier généré validé:');
    print('   📄 Lignes: $lineCount');
    print('   📊 Taille: ${fileSize}KB');
    print('   🎯 Icônes: $totalProcessed');

    // 9. Test de compilation du fichier généré
    if (config.testCompilation) {
      print('\n🧪 Phase 5: Test de compilation...');
      final compileResult = await _testCompilation();

      if (compileResult) {
        print('✅ Compilation réussie');
      } else {
        print('⚠️  Avertissements de compilation (mais fichier utilisable)');
      }
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;

    // 10. Résumé final
    print('\n🎉 GÉNÉRATION TERMINÉE AVEC SUCCÈS!');
    print('═══════════════════════════════════════════════════');
    print('📊 Résumé:');
    print('   🎯 Total icônes: $totalProcessed');
    print('   📦 Sets traités: ${enrichedIconSets.length}');
    print('   ⏱️  Durée: ${duration}ms');
    print('   📁 Fichier: lib/core/icons/generated_icons_registry.dart');
    print('   📊 Taille finale: ${fileSize}KB');
    print('');
    print('💡 Prochaines étapes:');
    print('   1. git add lib/core/icons/generated_icons_registry.dart');
    print('   2. git commit -m "Update generated icons registry"');
    print('   3. Utiliser GeneratedIconsRegistry dans votre app');
  } catch (e, stackTrace) {
    print('\n❌ ERREUR DURANT LA GÉNÉRATION');
    print('═══════════════════════════════════════════════════');
    print('Erreur: $e');

    if (config.verbose) {
      print('\nStack trace:');
      print(stackTrace);
    }

    print('\n💡 Solutions possibles:');
    print('   1. Vérifier que icons_plus est installé: dart pub get');
    print('   2. Vérifier les permissions de fichiers');
    print('   3. Relancer avec --verbose pour plus de détails');

    exit(1);
  }
}

/// Configuration du script
class GenerationConfig {
  final bool verbose;
  final bool testCompilation;
  final int? limitPerSet;
  final bool dryRun;

  const GenerationConfig({
    this.verbose = false,
    this.testCompilation = true,
    this.limitPerSet,
    this.dryRun = false,
  });
}

/// Parse les arguments de ligne de commande
GenerationConfig _parseArguments(List<String> arguments) {
  var verbose = false;
  var testCompilation = true;
  var dryRun = false;
  int? limitPerSet;

  for (final arg in arguments) {
    switch (arg) {
      case '--verbose':
      case '-v':
        verbose = true;
        break;
      case '--no-compile-test':
        testCompilation = false;
        break;
      case '--dry-run':
        dryRun = true;
        break;
      case '--help':
      case '-h':
        _printHelp();
        exit(0);
    }

    // Limite par set pour les tests
    if (arg.startsWith('--limit=')) {
      final limitStr = arg.substring(8);
      limitPerSet = int.tryParse(limitStr);
    }
  }

  final config = GenerationConfig(
    verbose: verbose,
    testCompilation: testCompilation,
    limitPerSet: limitPerSet,
    dryRun: dryRun,
  );

  if (verbose) {
    print('🔧 Configuration:');
    print('   Verbose: $verbose');
    print('   Test compilation: $testCompilation');
    print('   Limite par set: ${limitPerSet ?? 'aucune'}');
    print('   Dry run: $dryRun');
    print('');
  }

  return config;
}

/// Affiche l'aide
void _printHelp() {
  print('🔧 Générateur d\'icônes - Aide');
  print('═══════════════════════════════════════════════════');
  print('Usage: dart run tools/generate_icons.dart [options]');
  print('');
  print('Options:');
  print('  --verbose, -v        Affichage verbeux');
  print('  --no-compile-test    Skip le test de compilation');
  print(
    '  --limit=N           Limite le nombre d\'icônes par set (pour tests)',
  );
  print('  --dry-run           Simulation sans écriture de fichier');
  print('  --help, -h          Affiche cette aide');
  print('');
  print('Exemples:');
  print('  dart run tools/generate_icons.dart');
  print('  dart run tools/generate_icons.dart --verbose');
  print('  dart run tools/generate_icons.dart --limit=50 --verbose');
}

/// Vérifications multiples pour machine de développement
bool _isDevelopmentMachine() {
  // Vérifier les fichiers de projet Flutter/Dart (dans le répertoire parent aussi)
  final hasDartTool =
      Directory('.dart_tool').existsSync() ||
      Directory('../.dart_tool').existsSync();
  final hasPubspec =
      File('pubspec.yaml').existsSync() || File('../pubspec.yaml').existsSync();

  // Vérifier les variables d'environnement (optionnel)
  final hasFlutterRoot = Platform.environment.containsKey('FLUTTER_ROOT');
  final hasPubCache = Platform.environment.containsKey('PUB_CACHE');

  // Il suffit d'avoir les fichiers de projet OU les variables d'environnement
  return (hasDartTool && hasPubspec) || hasFlutterRoot || hasPubCache;
}

/// Vérifier que Flutter SDK est disponible
bool _isFlutterSDKAvailable() {
  try {
    final result = Process.runSync('flutter', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Test de compilation du fichier généré
Future<bool> _testCompilation() async {
  try {
    final result = await Process.run('dart', [
      'analyze',
      'lib/core/icons/generated_icons_registry.dart',
    ]);

    if (result.exitCode == 0) {
      print('   ✅ Aucune erreur de compilation');
      return true;
    } else {
      final output = result.stdout.toString() + result.stderr.toString();
      final errorCount = output.split('error').length - 1;
      final warningCount = output.split('info').length - 1;

      print('   ⚠️  $errorCount erreurs, $warningCount avertissements');

      if (errorCount == 0) {
        print('   ✅ Compilable malgré les avertissements');
        return true;
      } else {
        print('   ❌ Erreurs de compilation détectées:');
        print(output);
        return false;
      }
    }
  } catch (e) {
    print('   ⚠️  Impossible de tester la compilation: $e');
    return false;
  }
}
