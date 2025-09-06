import 'dart:io';
import 'package:flutter/material.dart';

/// Utilitaires pour l'affichage d'images
class ImageUtils {
  /// Détermine si un chemin est une URL ou un fichier local
  static bool isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
  
  /// Affiche une image depuis une URL ou un fichier local
  static Widget buildImageFromPath(
    String imagePath, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (isNetworkUrl(imagePath)) {
      // URL distante (Brandfetch, etc.)
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else {
      // Fichier local (icônes téléchargées)
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }
}