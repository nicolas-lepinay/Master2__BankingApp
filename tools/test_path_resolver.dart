/// Test simple du résolveur de chemins
import 'icon_generator/path_resolver.dart';

void main() {
  print('🧪 Test du résolveur de chemins Windows\n');
  
  // Afficher l'environnement
  PubCachePathResolver.printEnvironmentInfo();
  
  print('\n🔍 Recherche d\'icons_plus...');
  
  // Tester la recherche
  final iconsPlusPath = PubCachePathResolver.findLatestIconsPlusVersion();
  
  if (iconsPlusPath != null) {
    print('\n✅ SUCCESS: icons_plus trouvé!');
    print('📍 Chemin: $iconsPlusPath');
    
    // Valider le package
    final isValid = PubCachePathResolver.validateIconsPlusPath(iconsPlusPath);
    print('🔍 Validation: ${isValid ? 'VALIDE ✅' : 'INVALIDE ❌'}');
  } else {
    print('\n❌ FAILURE: icons_plus non trouvé');
    print('💡 Assurez-vous que icons_plus est installé avec: dart pub add icons_plus');
  }
}