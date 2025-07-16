import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:drift/drift.dart';

abstract class CategoryLocalDataSource {
  /// Get all categories
  Future<List<CategoryModel>> getAllCategories();
  
  /// Get category by ID
  Future<CategoryModel?> getCategoryById(int id);
  
  /// Get categories by level
  Future<List<CategoryModel>> getCategoriesByLevel(int level);
  
  /// Get subcategories of a parent category
  Future<List<CategoryModel>> getSubcategories(int parentId);
  
  /// Create a new category
  Future<CategoryModel> createCategory(CategoryModel category);
  
  /// Update an existing category
  Future<CategoryModel> updateCategory(CategoryModel category);
  
  /// Delete a category
  Future<void> deleteCategory(int id);
  
  /// Stream to watch categories changes
  Stream<List<CategoryModel>> watchAllCategories();
  
  /// Stream to watch specific category changes
  Stream<CategoryModel?> watchCategoryById(int id);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final AppDatabase _database;
  
  CategoryLocalDataSourceImpl(this._database);
  
  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final categories = await (_database.select(_database.categories)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.level, mode: OrderingMode.asc),
                 (tbl) => OrderingTerm(expression: tbl.label, mode: OrderingMode.asc)]))
      .get();
    
    return categories.map((category) => CategoryModel.fromDrift(category)).toList();
  }
  
  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final category = await (_database.select(_database.categories)
      ..where((tbl) => tbl.id.equals(id)))
      .getSingleOrNull();
    
    return category != null ? CategoryModel.fromDrift(category) : null;
  }
  
  @override
  Future<List<CategoryModel>> getCategoriesByLevel(int level) async {
    final categories = await (_database.select(_database.categories)
      ..where((tbl) => tbl.level.equals(level))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.label, mode: OrderingMode.asc)]))
      .get();
    
    return categories.map((category) => CategoryModel.fromDrift(category)).toList();
  }
  
  @override
  Future<List<CategoryModel>> getSubcategories(int parentId) async {
    final categories = await (_database.select(_database.categories)
      ..where((tbl) => tbl.parentId.equals(parentId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.label, mode: OrderingMode.asc)]))
      .get();
    
    return categories.map((category) => CategoryModel.fromDrift(category)).toList();
  }
  
  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final companion = category.toCompanion();
    final id = await _database.into(_database.categories).insert(companion);
    return category.copyWith(id: id);
  }
  
  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final companion = category.toCompanion();
    await _database.update(_database.categories).replace(companion);
    return category;
  }
  
  @override
  Future<void> deleteCategory(int id) async {
    await (_database.delete(_database.categories)
      ..where((tbl) => tbl.id.equals(id)))
      .go();
  }
  
  @override
  Stream<List<CategoryModel>> watchAllCategories() {
    return (_database.select(_database.categories)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.level, mode: OrderingMode.asc),
                 (tbl) => OrderingTerm(expression: tbl.label, mode: OrderingMode.asc)]))
      .watch()
      .map((categories) => categories.map((category) => CategoryModel.fromDrift(category)).toList());
  }
  
  @override
  Stream<CategoryModel?> watchCategoryById(int id) {
    return (_database.select(_database.categories)
      ..where((tbl) => tbl.id.equals(id)))
      .watchSingleOrNull()
      .map((category) => category != null ? CategoryModel.fromDrift(category) : null);
  }
}