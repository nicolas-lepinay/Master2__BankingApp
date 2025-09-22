/// Test du parser d'icônes
import 'dart:io';
import 'icon_generator/path_resolver.dart';
import 'icon_generator/parser.dart';

void main() {
  print('🧪 Test du parser d\'icônes\n');
  
  // 1. Trouver icons_plus
  final iconsPlusPath = PubCachePathResolver.findLatestIconsPlusVersion();
  
  if (iconsPlusPath == null) {
    print('❌ icons_plus non trouvé');
    return;
  }
  
  print('📍 Package trouvé: $iconsPlusPath\n');
  
  // 2. Créer le parser
  final parser = IconsPlusParser(iconsPlusPath);
  
  // 3. Afficher les infos du package
  final packageInfo = parser.getPackageInfo();
  print(packageInfo);
  
  // 4. Tester le parsing d'un fichier spécifique
  print('\n🔍 Test parsing d\'un fichier...');
  final testFiles = [
    '$iconsPlusPath\\lib\\src\\bootstrap.dart',
    '$iconsPlusPath\\lib\\src\\font_awesome.dart',
    '$iconsPlusPath\\lib\\src\\ant_design.dart',
  ];
  
  for (final filePath in testFiles) {
    if (File(filePath).existsSync()) {
      final icons = parser.parseIconFile(filePath);
      print('   📄 ${filePath.split('\\').last}: ${icons.length} icônes');
      
      // Afficher quelques exemples
      if (icons.isNotEmpty) {
        final examples = icons.take(3).toList();
        for (final icon in examples) {
          print('      🎯 ${icon.name} (${icon.codePoint})');
        }
      }
      break; // Tester seulement le premier fichier trouvé
    }
  }
  
  // 5. Tester le parsing complet (limité pour le test)
  print('\n🚀 Test parsing complet...');
  final allIcons = parser.parseAllIconFiles();
  
  if (allIcons.isNotEmpty) {
    print('\n✅ Parsing réussi!');
    final totalIcons = allIcons.values.map((icons) => icons.length).fold(0, (a, b) => a + b);
    print('📊 Total: $totalIcons icônes dans ${allIcons.length} sets');
  } else {
    print('\n❌ Aucune icône parsée');
  }
}