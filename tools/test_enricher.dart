/// Test de l'enrichisseur de métadonnées
import 'icon_generator/path_resolver.dart';
import 'icon_generator/parser.dart';
import 'icon_generator/enricher.dart';

void main() {
  print('🧪 Test de l\'enrichisseur de métadonnées\n');
  
  // 1. Trouver et parser quelques icônes
  final iconsPlusPath = PubCachePathResolver.findLatestIconsPlusVersion();
  if (iconsPlusPath == null) {
    print('❌ icons_plus non trouvé');
    return;
  }
  
  final parser = IconsPlusParser(iconsPlusPath);
  
  // Tester sur Bootstrap seulement pour limiter la sortie
  final bootstrapIcons = parser.parseIconFile('$iconsPlusPath\\lib\\src\\bootstrap.dart');
  
  if (bootstrapIcons.isEmpty) {
    print('❌ Aucune icône Bootstrap trouvée');
    return;
  }
  
  print('📍 ${bootstrapIcons.length} icônes Bootstrap parsées');
  
  // 2. Enrichir un échantillon
  final sampleIcons = bootstrapIcons.take(50).toList();
  print('🔬 Test enrichissement sur ${sampleIcons.length} icônes échantillon\n');
  
  final enricher = IconMetadataEnricher();
  final enrichedIcons = enricher.enrichIcons(sampleIcons);
  
  // 3. Afficher quelques exemples
  print('\n📋 Exemples d\'icônes enrichies:');
  for (final icon in enrichedIcons.take(5)) {
    print('');
    print('🎯 ID: ${icon.id}');
    print('   📝 Nom: ${icon.name}');
    print('   📂 Catégorie: ${icon.category}');
    print('   🎨 Style: ${icon.style ?? 'default'}');
    print('   🔤 Mots-clés: ${icon.keywords.take(8).join(', ')}${icon.keywords.length > 8 ? '...' : ''}');
    print('   🏷️  Tags: ${icon.tags.join(', ')}');
  }
  
  // 4. Statistiques
  print('\n📊 Statistiques d\'enrichissement:');
  final stats = enricher.getEnrichmentStats(enrichedIcons);
  print(stats);
  
  // 5. Test de recherche simulée
  print('\n🔍 Test de recherche simulée:');
  final testQueries = ['heart', 'cœur', 'user', 'circle', 'arrow'];
  
  for (final query in testQueries) {
    final matches = enrichedIcons.where((icon) {
      final searchableText = [icon.name, icon.category, ...icon.keywords]
          .map((s) => s.toLowerCase())
          .join(' ');
      return searchableText.contains(query.toLowerCase());
    }).toList();
    
    print('   "$query": ${matches.length} résultats');
    if (matches.isNotEmpty) {
      final examples = matches.take(3).map((i) => i.name).join(', ');
      print('      Ex: $examples');
    }
  }
}