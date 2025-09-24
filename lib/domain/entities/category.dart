import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:bankapp/core/extensions/app_localizations_extensions.dart';
import 'package:bankapp/core/l10n/app_localizations.dart';

class Category extends Equatable {
  final int id;
  final String label;
  final int level;
  final int? parentId;
  final String? icon;
  final Color? iconColor; // Type Flutter typé et validé

  const Category({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
    this.icon,
    this.iconColor,
  });

  Category copyWith({
    int? id,
    String? label,
    int? level,
    int? parentId,
    String? icon,
    Color? iconColor,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  bool get isRootCategory => parentId == null;
  bool get isSubCategory => parentId != null;

  /// Obtient le nom d'affichage de la catégorie (localisé si clé trouvée)
  /// 
  /// Si le label correspond à une clé de localisation, retourne la traduction.
  /// Sinon, retourne le label tel quel (catégorie créée par l'utilisateur).
  String getDisplayName(AppLocalizations l10n) {
    return l10n.getCategoryName(label);
  }

  @override
  List<Object?> get props => [id, label, level, parentId, icon, iconColor];

  @override
  bool get stringify => true;
}