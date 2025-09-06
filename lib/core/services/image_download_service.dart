import 'dart:io';

import 'package:bankapp/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service pour télécharger et sauvegarder des images de logos
class ImageDownloadService with AppLoggerMixin {
  final http.Client _client;

  /// Timeout pour les téléchargements
  static const Duration _timeout = Duration(seconds: 30);

  /// Dossier pour stocker les images de logos
  static const String _logosFolderName = 'counterparty_logos';

  ImageDownloadService({http.Client? client}) : _client = client ?? http.Client();

  /// Télécharge une image depuis une URL et la sauvegarde localement
  /// 
  /// [imageUrl] : URL de l'image à télécharger
  /// [domain] : Nom de domaine pour le nommage du fichier
  /// 
  /// Retourne le chemin local de l'image sauvegardée
  Future<String> downloadAndSaveLogo({
    required String imageUrl,
    required String domain,
  }) async {
    final startTime = DateTime.now();
    
    logInfo('downloadAndSaveLogo', 'Downloading logo for $domain from $imageUrl');

    try {
      // Créer le dossier de stockage si nécessaire
      final logosDirectory = await _getLogosDirectory();
      
      // Télécharger l'image
      final response = await _client.get(Uri.parse(imageUrl)).timeout(_timeout);
      
      if (response.statusCode != 200) {
        throw ImageDownloadException(
          'Failed to download image: HTTP ${response.statusCode}',
        );
      }

      // Déterminer l'extension du fichier
      final extension = _getFileExtension(imageUrl, response.headers);
      
      // Créer le nom de fichier avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanDomain = _sanitizeDomainName(domain);
      final filename = '${cleanDomain}_$timestamp.$extension';
      
      // Sauvegarder le fichier
      final file = File(path.join(logosDirectory.path, filename));
      await file.writeAsBytes(response.bodyBytes);
      
      final duration = DateTime.now().difference(startTime);
      final fileSizeKb = (response.bodyBytes.length / 1024).round();
      
      logInfo('downloadAndSaveLogo', 'Logo saved for $domain: $filename (${fileSizeKb}KB) in ${duration.inMilliseconds}ms');
      
      return file.path;
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      logError('downloadAndSaveLogo', 'Failed to download logo for $domain in ${duration.inMilliseconds}ms', e);
      
      if (e is ImageDownloadException) {
        rethrow;
      }
      
      throw ImageDownloadException('Download failed: $e');
    }
  }

  /// Obtient le répertoire pour stocker les logos
  Future<Directory> _getLogosDirectory() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final logosDir = Directory(path.join(appSupportDir.path, _logosFolderName));
    
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
      logInfo('_getLogosDirectory', 'Created logos directory: ${logosDir.path}');
    }
    
    return logosDir;
  }

  /// Détermine l'extension du fichier à partir de l'URL ou des headers
  String _getFileExtension(String imageUrl, Map<String, String> headers) {
    // Essayer d'abord depuis l'URL
    final urlExtension = _getExtensionFromUrl(imageUrl);
    if (urlExtension.isNotEmpty) {
      return urlExtension;
    }
    
    // Essayer depuis le Content-Type header
    final contentType = headers['content-type']?.toLowerCase();
    if (contentType != null) {
      if (contentType.contains('webp')) return 'webp';
      if (contentType.contains('png')) return 'png';
      if (contentType.contains('jpeg') || contentType.contains('jpg')) return 'jpg';
      if (contentType.contains('gif')) return 'gif';
      if (contentType.contains('svg')) return 'svg';
    }
    
    // Par défaut, utiliser webp (format courant de Brandfetch)
    return 'webp';
  }

  /// Extrait l'extension depuis l'URL
  String _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        final parts = lastSegment.split('.');
        
        if (parts.length > 1) {
          final extension = parts.last.toLowerCase();
          // Vérifier que c'est une extension d'image valide
          if (['webp', 'png', 'jpg', 'jpeg', 'gif', 'svg'].contains(extension)) {
            return extension;
          }
        }
      }
    } catch (e) {
      logInfo('_getFileExtension', 'Failed to parse URL for extension: $url');
    }
    
    return '';
  }

  /// Nettoie le nom de domaine pour créer un nom de fichier valide
  String _sanitizeDomainName(String domain) {
    // Supprimer le protocole et www
    String cleaned = domain.toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '');
    
    // Supprimer l'extension .com, .org, etc.
    cleaned = cleaned.replaceAll(RegExp(r'\.[a-z]+$'), '');
    
    // Remplacer les caractères non alphanumériques par des underscores
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    
    // Supprimer les underscores multiples et de début/fin
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    
    // Si vide, utiliser un nom par défaut
    if (cleaned.isEmpty) {
      cleaned = 'logo';
    }
    
    return cleaned;
  }

  /// Supprime un fichier de logo
  Future<bool> deleteLogo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logInfo('deleteLogoFile', 'Deleted logo file: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      logError('deleteLogoFile', 'Failed to delete logo file $filePath', e);
      return false;
    }
  }

  /// Nettoie les anciens fichiers de logos (garde les 30 derniers jours)
  Future<void> cleanupOldLogos({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final logosDirectory = await _getLogosDirectory();
      final files = logosDirectory.listSync().whereType<File>();
      final cutoffTime = DateTime.now().subtract(maxAge);
      
      int deletedCount = 0;
      
      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          await file.delete();
          deletedCount++;
        }
      }
      
      if (deletedCount > 0) {
        logInfo('cleanupOldLogos', 'Cleaned up $deletedCount old logo files');
      }
    } catch (e) {
      logError('cleanupOldLogos', 'Failed to cleanup old logos', e);
    }
  }

  /// Obtient la taille du cache des logos
  Future<int> getCacheSize() async {
    try {
      final logosDirectory = await _getLogosDirectory();
      final files = logosDirectory.listSync().whereType<File>();
      
      int totalSize = 0;
      for (final file in files) {
        final stat = await file.stat();
        totalSize += stat.size;
      }
      
      return totalSize;
    } catch (e) {
      logError('getCacheSize', 'Failed to calculate cache size', e);
      return 0;
    }
  }

  /// Vérifie si un fichier existe
  Future<bool> logoExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _client.close();
  }
}

/// Exception pour les erreurs de téléchargement d'image
class ImageDownloadException implements Exception {
  final String message;

  const ImageDownloadException(this.message);

  @override
  String toString() => 'ImageDownloadException: $message';
}