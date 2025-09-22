import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  @override
  List<Object?> get props => [id, label, level, parentId, icon, iconColor];

  @override
  bool get stringify => true;
}