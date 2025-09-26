import 'package:flutter/material.dart';
import 'package:bankapp/core/icons/generated_icons_registry.dart';

/// Extensions pour le GeneratedIconsRegistry
///
/// Cette classe étend les fonctionnalités du registry généré automatiquement
/// sans le modifier directement, évitant ainsi de perdre les modifications
/// lors d'une régénération.
class IconRegistryExtensions {
  IconRegistryExtensions._(); // Constructeur privé - classe utilitaire

  /// Map inverse pour recherche rapide IconData → ID (lazy initialization)
  static Map<IconData, String>? _reverseMap;

  /// Initialise la map inverse (appelé une seule fois au besoin)
  static void _initializeReverseMap() {
    if (_reverseMap != null) return;

    _reverseMap = {};

    // Utiliser le getter allIcons du registry généré
    final allIcons = GeneratedIconsRegistry.allIcons;
    for (final iconEntry in allIcons.values) {
      _reverseMap![iconEntry.iconData] = iconEntry.id;
    }
  }

  /// Recherche l'ID d'une IconData (optimisé O(1))
  ///
  /// Cette méthode utilise une map inverse pour une recherche rapide.
  /// Utilisée pour la sérialisation IconData → String dans CategoryModel.fromEntity().
  static String? findIdByIconData(IconData? iconData) {
    if (iconData == null) return null;

    _initializeReverseMap();
    return _reverseMap![iconData];
  }
}