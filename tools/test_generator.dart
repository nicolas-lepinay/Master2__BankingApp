/// Test du générateur de registry
import 'dart:io';
import 'icon_generator/path_resolver.dart';
import 'icon_generator/parser.dart';
import 'icon_generator/enricher.dart';
import 'icon_generator/generator.dart';
import 'icon_generator/models.dart';

void main() {
  print('🧪 Test du générateur de registry\n');
  
  // 1. Obtenir un échantillon d'icônes
  final iconsPlusPath = PubCachePathResolver.findLatestIconsPlusVersion();
  if (iconsPlusPath == null) {
    print('❌ icons_plus non trouvé');
    return;
  }
  
  print('📍 Package: $iconsPlusPath');
  
  // 2. Parser un petit échantillon pour le test
  final parser = IconsPlusParser(iconsPlusPath);
  final enricher = IconMetadataEnricher();
  
  // Prendre seulement Bootstrap et Heroicons pour le test
  final testFiles = [
    '$iconsPlusPath\\lib\\src\\bootstrap.dart',
    '$iconsPlusPath\\lib\\src\\heroicons.dart',
  ];
  
  final iconSets = <String, List<EnrichedIcon>>{};
  
  for (final filePath in testFiles) {
    if (File(filePath).existsSync()) {
      print('🔍 Parsing ${filePath.split('\\').last}...');
      final parsedIcons = parser.parseIconFile(filePath);
      
      if (parsedIcons.isNotEmpty) {
        // Limiter à 100 icônes par set pour le test
        final limitedIcons = parsedIcons.take(100).toList();
        final enrichedIcons = enricher.enrichIcons(limitedIcons);
        
        final className = parsedIcons.first.className;
        iconSets[className] = enrichedIcons;
        
        print('   ✅ ${enrichedIcons.length} icônes enrichies');
      }
    }
  }
  
  if (iconSets.isEmpty) {
    print('❌ Aucune icône à générer');
    return;
  }
  
  // 3. Générer le registry
  print('\n🚀 Génération du registry de test...');
  final generator = IconRegistryGenerator();
  generator.generateRegistry(iconSets);
  
  // 4. Vérifier le fichier généré
  final generatedFile = File('lib/core/icons/generated_icons_registry.dart');
  if (generatedFile.existsSync()) {
    final content = generatedFile.readAsStringSync();
    final lines = content.split('\n').length;
    final size = (content.length / 1024).toStringAsFixed(1);
    
    print('\n✅ Registry généré avec succès!');
    print('📄 Lignes: $lines');
    print('📊 Taille: ${size}KB');
    
    // Afficher un aperçu
    print('\n📋 Aperçu du contenu:');
    final preview = content.split('\n').take(20).join('\n');
    print(preview);
    print('...');
  } else {
    print('❌ Fichier non généré');
  }
}