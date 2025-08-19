import 'package:bankapp/domain/entities/entities.dart';

abstract class CategoryRepository {
  /// Get all categories
  Future<List<Category>> getAllCategories();
  
  /// Get category by ID
  Future<Category?> getCategoryById(int id);
  
  /// Get categories by level
  Future<List<Category>> getCategoriesByLevel(int level);
  
  /// Get subcategories of a parent category
  Future<List<Category>> getSubcategories(int parentId);
  
  /// Get root categories (level 1)
  Future<List<Category>> getRootCategories();
  
  /// Create a new category
  Future<Category> createCategory(Category category);
  
  /// Update an existing category
  Future<Category> updateCategory(Category category);
  
  /// Delete a category
  Future<void> deleteCategory(int id);
  
  /// Check if category has subcategories
  Future<bool> hasSubcategories(int categoryId);
  
  /// Check if category is used in transactions
  Future<bool> isUsedInTransactions(int categoryId);
  
  /// Stream to watch categories changes
  Stream<List<Category>> watchAllCategories();
  
  /// Stream to watch specific category changes
  Stream<Category?> watchCategoryById(int id);
}