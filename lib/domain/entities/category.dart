import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int id;
  final String label;
  final int level;
  final int? parentId;
  final String? icon;

  const Category({
    required this.id,
    required this.label,
    required this.level,
    this.parentId,
    this.icon,
  });

  Category copyWith({
    int? id,
    String? label,
    int? level,
    int? parentId,
    String? icon,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
    );
  }

  bool get isRootCategory => parentId == null;
  bool get isSubCategory => parentId != null;

  @override
  List<Object?> get props => [id, label, level, parentId, icon];

  @override
  bool get stringify => true;
}