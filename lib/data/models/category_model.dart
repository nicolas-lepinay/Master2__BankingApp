import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:drift/drift.dart';

class CategoryModel {
  final int id;
  final String label;
  final int level;
  final int? parentId;
  final String? icon;

  const CategoryModel({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
    this.icon,
  });

  factory CategoryModel.fromDrift(Category data) {
    return CategoryModel(
      id: data.id,
      label: data.label,
      level: data.level,
      parentId: data.parentId,
      icon: data.icon,
    );
  }

  factory CategoryModel.fromEntity(domain.Category category) {
    return CategoryModel(
      id: category.id,
      label: category.label,
      level: category.level,
      parentId: category.parentId,
      icon: category.icon,
    );
  }

  domain.Category toEntity() {
    return domain.Category(
      id: id,
      label: label,
      level: level,
      parentId: parentId,
      icon: icon,
    );
  }

  CategoriesCompanion toCompanion() {
    return CategoriesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      label: Value(label),
      level: Value(level),
      parentId: Value(parentId),
      icon: Value(icon),
    );
  }

  CategoryModel copyWith({
    int? id,
    String? label,
    int? level,
    int? parentId,
    String? icon,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      label: label ?? this.label,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
    );
  }
}