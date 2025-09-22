import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/core/utils/color_utils.dart';
import 'package:drift/drift.dart';

class CategoryModel {
  final int id;
  final String label;
  final int level;
  final int? parentId;
  final String? icon;
  final String? iconColor; // Format HEX depuis la DB

  const CategoryModel({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
    this.icon,
    this.iconColor,
  });

  factory CategoryModel.fromDrift(Category data) {
    return CategoryModel(
      id: data.id,
      label: data.label,
      level: data.level,
      parentId: data.parentId,
      icon: data.icon,
      iconColor: data.iconColor,
    );
  }

  factory CategoryModel.fromEntity(domain.Category category) {
    return CategoryModel(
      id: category.id,
      label: category.label,
      level: category.level,
      parentId: category.parentId,
      icon: category.icon,
      iconColor: category.iconColor != null ? ColorUtils.toHex(category.iconColor!) : null,
    );
  }

  domain.Category toEntity() {
    return domain.Category(
      id: id,
      label: label,
      level: level,
      parentId: parentId,
      icon: icon,
      iconColor: ColorUtils.fromHex(iconColor), // Conversion automatique String -> Color
    );
  }

  CategoriesCompanion toCompanion() {
    return CategoriesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      label: Value(label),
      level: Value(level),
      parentId: Value(parentId),
      icon: Value(icon),
      iconColor: Value(iconColor),
    );
  }

  CategoryModel copyWith({
    int? id,
    String? label,
    int? level,
    int? parentId,
    String? icon,
    String? iconColor,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      label: label ?? this.label,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}