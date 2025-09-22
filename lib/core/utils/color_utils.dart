import 'package:flutter/material.dart';

/// Utilitaires pour la conversion des couleurs
class ColorUtils {
  /// Convertit une couleur HEX en Color Flutter
  /// 
  /// Formats supportés :
  /// - "#FF5733" (avec #)
  /// - "FF5733" (sans #)
  /// - "#AAFF5733" (avec alpha)
  /// 
  /// Retourne null si la conversion échoue
  static Color? fromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    
    try {
      // Nettoyer la chaîne
      String cleanHex = hexColor.trim();
      
      // Supprimer le # si présent
      if (cleanHex.startsWith('#')) {
        cleanHex = cleanHex.substring(1);
      }
      
      // Ajouter l'alpha si manquant (6 caractères -> 8 caractères)
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex'; // Alpha opaque par défaut
      }
      
      // Vérifier la longueur (doit être 8 caractères)
      if (cleanHex.length != 8) {
        return null;
      }
      
      // Conversion
      final int colorInt = int.parse(cleanHex, radix: 16);
      return Color(colorInt);
      
    } catch (e) {
      // Couleur invalide, retourner null plutôt que crasher
      return null;
    }
  }
  
  /// Convertit une Color Flutter en format HEX
  /// 
  /// Retourne le format "#AARRGGBB" (avec alpha)
  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
  
  /// Convertit une Color Flutter en format HEX sans alpha
  /// 
  /// Retourne le format "#RRGGBB" (sans alpha)
  static String toHexRGB(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}'; // Supprimer les 2 premiers caractères (alpha)
  }
  
  /// Couleurs prédéfinies populaires pour les catégories
  static const Map<String, Color> predefinedColors = {
    'primary': Colors.blue,
    'success': Colors.green,
    'warning': Colors.orange,
    'danger': Colors.red,
    'info': Colors.cyan,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'brown': Colors.brown,
  };
  
  /// Retourne une couleur prédéfinie ou parse le HEX
  static Color? smartParse(String? colorInput) {
    if (colorInput == null || colorInput.isEmpty) return null;
    
    // Vérifier les couleurs prédéfinies d'abord
    final predefined = predefinedColors[colorInput.toLowerCase()];
    if (predefined != null) return predefined;
    
    // Sinon, essayer de parser comme HEX
    return fromHex(colorInput);
  }
}