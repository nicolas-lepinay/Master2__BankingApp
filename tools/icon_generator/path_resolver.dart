/// Résolveur de chemins pour localiser le package icons_plus sur Windows
/// 
/// Ce module localise automatiquement icons_plus dans le cache pub
/// en testant les emplacements standards Windows.
library;

import 'dart:io';

/// Résolveur de chemins Windows pour le cache pub
class PubCachePathResolver {
  
  /// Trouve icons_plus dans le cache pub Windows
  static String? findIconsPlusPath() {
    final possiblePaths = _getPossiblePubCachePaths();
    
    for (final basePath in possiblePaths) {
      final dir = Directory(basePath);
      if (!dir.existsSync()) continue;
      
      try {
        for (final item in dir.listSync()) {
          if (item is Directory && item.path.contains('icons_plus-')) {
            print('📍 Trouvé icons_plus: ${item.path}');
            return item.path;
          }
        }
      } catch (e) {
        // Ignorer les erreurs de permissions, essayer le chemin suivant
        print('⚠️  Erreur d\'accès à $basePath: $e');
        continue;
      }
    }
    
    return null;
  }
  
  /// Trouve la version la plus récente d'icons_plus
  static String? findLatestIconsPlusVersion() {
    final basePath = _findPubCacheBasePath();
    if (basePath == null) return null;
    
    final versions = <String>[];
    final dir = Directory(basePath);
    
    try {
      for (final item in dir.listSync()) {
        if (item is Directory && item.path.contains('icons_plus-')) {
          versions.add(item.path);
        }
      }
    } catch (e) {
      print('❌ Erreur de lecture du cache pub: $e');
      return null;
    }
    
    if (versions.isEmpty) return null;
    
    // Trier par version (la plus récente en dernier)
    versions.sort();
    final latest = versions.last;
    print('🎯 Version la plus récente détectée: ${_extractVersionFromPath(latest)}');
    return latest;
  }
  
  /// Trouve le chemin de base du cache pub
  static String? _findPubCacheBasePath() {
    final possiblePaths = _getPossiblePubCachePaths();
    
    for (final path in possiblePaths) {
      if (Directory(path).existsSync()) {
        print('✅ Cache pub trouvé: $path');
        return path;
      }
    }
    
    print('❌ Aucun cache pub trouvé dans les emplacements standards');
    return null;
  }
  
  /// Liste des chemins possibles du cache pub sur Windows
  static List<String> _getPossiblePubCachePaths() {
    final userProfile = Platform.environment['USERPROFILE'];
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final userName = Platform.environment['USERNAME'];
    
    return [
      // Chemins standards Windows pour pub cache
      if (userProfile != null) '$userProfile\\.pub-cache\\hosted\\pub.dev',
      if (localAppData != null) '$localAppData\\Pub\\Cache\\hosted\\pub.dev',
      if (userName != null) 'C:\\Users\\$userName\\.pub-cache\\hosted\\pub.dev',
      
      // Chemin spécifique détecté pour icons_plus-5.0.0 (fallback)
      'C:\\Users\\offth\\AppData\\Local\\Pub\\Cache\\hosted\\pub.dev',
      
      // Autres emplacements possibles
      'C:\\ProgramData\\Pub\\Cache\\hosted\\pub.dev',
      if (userProfile != null) '$userProfile\\AppData\\Local\\Pub\\Cache\\hosted\\pub.dev',
    ];
  }
  
  /// Extrait la version depuis un chemin de fichier
  static String _extractVersionFromPath(String path) {
    final regex = RegExp(r'icons_plus-(\d+\.\d+\.\d+)');
    final match = regex.firstMatch(path);
    return match?.group(1) ?? 'inconnue';
  }
  
  /// Valide qu'un chemin contient bien le package icons_plus
  static bool validateIconsPlusPath(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return false;
    
    // Vérifier la présence des dossiers lib/src
    final libDir = Directory('$path\\lib');
    final srcDir = Directory('$path\\lib\\src');
    
    if (!libDir.existsSync() || !srcDir.existsSync()) {
      print('⚠️  Structure invalide dans $path');
      return false;
    }
    
    // Vérifier qu'il y a des fichiers .dart dans src/
    try {
      final dartFiles = srcDir
          .listSync()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      
      if (dartFiles.isEmpty) {
        print('⚠️  Aucun fichier .dart trouvé dans $path\\lib\\src');
        return false;
      }
      
      print('✅ Package icons_plus valide: ${dartFiles.length} fichiers source');
      return true;
    } catch (e) {
      print('❌ Erreur de validation: $e');
      return false;
    }
  }
  
  /// Affiche des informations de débogage sur l'environnement
  static void printEnvironmentInfo() {
    print('🔍 Informations environnement Windows:');
    print('   USERPROFILE: ${Platform.environment['USERPROFILE']}');
    print('   LOCALAPPDATA: ${Platform.environment['LOCALAPPDATA']}');
    print('   USERNAME: ${Platform.environment['USERNAME']}');
    print('   PUB_CACHE: ${Platform.environment['PUB_CACHE'] ?? 'non défini'}');
    print('');
    print('📁 Chemins de recherche testés:');
    for (final path in _getPossiblePubCachePaths()) {
      final exists = Directory(path).existsSync();
      print('   ${exists ? '✅' : '❌'} $path');
    }
  }
}