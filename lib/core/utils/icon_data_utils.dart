import 'package:flutter/material.dart';
import 'package:bankapp/core/icons/generated_icons_registry.dart';
import 'package:bankapp/core/icons/icon_registry_extensions.dart';

/// Utilitaire pour la conversion bidirectionnelle IconData ↔ String
///
/// Cette classe centralise la logique de conversion entre les identifiants
/// d'icônes (stockés en DB) et les objets IconData (utilisés dans l'UI).
///
/// Pattern identique à ColorUtils pour maintenir la cohérence architecturale.
class IconDataUtils {
  IconDataUtils._(); // Constructeur privé - classe utilitaire

  /// Convertit un identifiant d'icône en IconData
  ///
  /// Cette méthode résout l'IconData une seule fois lors de la conversion
  /// CategoryModel → Category, évitant les lookups répétés dans l'UI.
  ///
  /// [iconId] : Identifiant de l'icône (ex: "bootstrap_heart_fill")
  /// Retourne l'IconData correspondant ou null si introuvable
  static IconData? idToIconData(String? iconId) {
    if (iconId == null || iconId.isEmpty) return null;

    final iconEntry = GeneratedIconsRegistry.getIconById(iconId);
    return iconEntry?.iconData;
  }

  /// Convertit un IconData en identifiant pour stockage en DB
  ///
  /// Utilisé pour la sérialisation Category → CategoryModel.
  /// Nécessite une recherche inverse dans le registry (optimisée).
  ///
  /// [iconData] : L'IconData à sérialiser
  /// Retourne l'identifiant string ou null si introuvable
  static String? iconDataToId(IconData? iconData) {
    if (iconData == null) return null;

    // Utiliser notre extension (safe pour les regenerations)
    return IconRegistryExtensions.findIdByIconData(iconData);
  }

  /// Icône par défaut pour les catégories sans icône définie
  static IconData get defaultCategoryIcon => Icons.folder_outlined;

  /// Vérifie si un identifiant d'icône est valide
  static bool isValidIconId(String? iconId) {
    return iconId != null &&
           iconId.isNotEmpty &&
           GeneratedIconsRegistry.hasIcon(iconId);
  }

  /// Obtient l'icône d'affichage pour une catégorie
  ///
  /// Retourne l'icône convertie ou l'icône par défaut.
  /// Cette méthode encapsule la logique d'affichage des catégories.
  static IconData getDisplayIcon(IconData? categoryIcon) {
    return categoryIcon ?? defaultCategoryIcon;
  }
}