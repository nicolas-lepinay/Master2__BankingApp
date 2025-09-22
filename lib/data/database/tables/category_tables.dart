import 'package:drift/drift.dart';

/// Table des catégories avec support hiérarchique
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get level => integer()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get icon => text().nullable()(); // Nom d'icône ou chemin SVG
  TextColumn get iconColor => text().nullable()(); // Couleur HEX "#FF5733"
}