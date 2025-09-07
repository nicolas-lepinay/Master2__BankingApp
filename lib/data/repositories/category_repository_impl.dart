import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/repositories.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _localDataSource;
  final CacheManager _cacheManager;

  CategoryRepositoryImpl(this._localDataSource, this._cacheManager);

  @override
  Future<List<Category>> getAllCategories() async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getAllCategories();
    }

    // Sinon, charger depuis la base de données
    final categoryModels = await _localDataSource.getAllCategories();
    return categoryModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final allCategories = _cacheManager.getAllCategories();
      try {
        return allCategories.firstWhere((category) => category.id == id);
      } catch (e) {
        return null;
      }
    }

    // Sinon, charger depuis la base de données
    final categoryModel = await _localDataSource.getCategoryById(id);
    return categoryModel?.toEntity();
  }

  @override
  Future<List<Category>> getCategoriesByLevel(int level) async {
    final allCategories = await getAllCategories();
    return allCategories.where((category) => category.level == level).toList();
  }

  @override
  Future<List<Category>> getSubcategories(int parentId) async {
    final allCategories = await getAllCategories();
    return allCategories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  @override
  Future<List<Category>> getRootCategories() async {
    return getCategoriesByLevel(1);
  }

  @override
  Future<Category> createCategory(Category category) async {
    // Créer le modèle pour la base de données
    final categoryModel = CategoryModel.fromEntity(category);

    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.createCategory(categoryModel);

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addCategory(savedModel);
    }

    return savedModel.toEntity();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    // Créer le modèle pour la base de données
    final categoryModel = CategoryModel.fromEntity(category);

    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.updateCategory(categoryModel);

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addCategory(savedModel);
    }

    return savedModel.toEntity();
  }

  @override
  Future<void> deleteCategory(int id) async {
    // Supprimer de la base de données
    await _localDataSource.deleteCategory(id);

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.removeCategory(id);
    }
  }

  @override
  Future<bool> hasSubcategories(int categoryId) async {
    final subcategories = await getSubcategories(categoryId);
    return subcategories.isNotEmpty;
  }

  @override
  Future<bool> isUsedInTransactions(int categoryId) async {
    // Si le cache est initialisé, vérifier dans le cache
    if (_cacheManager.isInitialized) {
      final allTransactions = _cacheManager.getAllTransactions();
      return allTransactions.any(
        (transaction) => transaction.categoryIds.contains(categoryId),
      );
    }

    // Sinon, vérifier dans la base de données
    // Note : Cette implémentation nécessiterait une méthode dans la datasource
    // Pour l'instant, on assume que non
    return false;
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.categoriesStream;
    }

    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAllCategories().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Stream<Category?> watchCategoryById(int id) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.categoriesStream.map((categories) {
        try {
          return categories.firstWhere((category) => category.id == id);
        } catch (e) {
          return null;
        }
      });
    }

    // Sinon, utiliser le stream de la base de données
    return _localDataSource
        .watchCategoryById(id)
        .map((model) => model?.toEntity());
  }
}
