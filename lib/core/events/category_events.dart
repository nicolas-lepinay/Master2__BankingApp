import 'package:bankapp/core/events/app_events.dart';
import 'package:bankapp/domain/entities/category.dart';

/// Événements liés aux catégories
abstract class CategoryEvent extends AppEvent {
  const CategoryEvent({
    required super.timestamp,
    required super.eventId,
  });
}

/// Événement de création d'une nouvelle catégorie
class CategoryCreatedEvent extends CategoryEvent {
  /// Catégorie qui vient d'être créée
  final Category category;

  /// Contexte de création (ex: "category_creation_bottom_sheet", "import", "sync")
  final String? context;

  const CategoryCreatedEvent({
    required this.category,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, category, context];

  @override
  String toString() => 'CategoryCreatedEvent(categoryId: ${category.id}, label: ${category.label}, context: $context)';
}

/// Événement de modification d'une catégorie existante
class CategoryUpdatedEvent extends CategoryEvent {
  /// Catégorie après modification
  final Category updatedCategory;

  /// Catégorie avant modification (pour rollback éventuel)
  final Category? previousCategory;

  /// Champs qui ont été modifiés
  final List<String> modifiedFields;

  /// Contexte de modification
  final String? context;

  const CategoryUpdatedEvent({
    required this.updatedCategory,
    this.previousCategory,
    this.modifiedFields = const [],
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    updatedCategory,
    previousCategory,
    modifiedFields,
    context
  ];

  @override
  String toString() => 'CategoryUpdatedEvent(categoryId: ${updatedCategory.id}, fields: $modifiedFields)';
}

/// Événement de suppression d'une catégorie
class CategoryDeletedEvent extends CategoryEvent {
  /// ID de la catégorie supprimée
  final int categoryId;

  /// Catégorie supprimée (pour rollback éventuel)
  final Category? deletedCategory;

  /// Contexte de suppression
  final String? context;

  const CategoryDeletedEvent({
    required this.categoryId,
    this.deletedCategory,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, categoryId, deletedCategory, context];

  @override
  String toString() => 'CategoryDeletedEvent(categoryId: $categoryId)';
}

/// Événement de sélection d'une catégorie (pour UI)
class CategorySelectedEvent extends CategoryEvent {
  /// Catégorie sélectionnée (null si désélection)
  final Category? selectedCategory;

  /// Catégorie précédemment sélectionnée
  final Category? previousCategory;

  /// Contexte de sélection
  final String? context;

  const CategorySelectedEvent({
    this.selectedCategory,
    this.previousCategory,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, selectedCategory, previousCategory, context];

  @override
  String toString() => 'CategorySelectedEvent(from: ${previousCategory?.label}, to: ${selectedCategory?.label})';
}

/// Événement de navigation dans l'arborescence des catégories
class CategoryNavigationEvent extends CategoryEvent {
  /// Catégorie parent vers laquelle on navigue (null pour niveau racine)
  final Category? parentCategory;

  /// Niveau de navigation (1 = racine)
  final int level;

  /// Direction de navigation
  final CategoryNavigationDirection direction;

  /// Contexte de navigation
  final String? context;

  const CategoryNavigationEvent({
    this.parentCategory,
    required this.level,
    required this.direction,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, parentCategory, level, direction, context];

  @override
  String toString() => 'CategoryNavigationEvent(level: $level, direction: $direction, parent: ${parentCategory?.label})';
}

/// Direction de navigation dans l'arborescence
enum CategoryNavigationDirection {
  /// Navigation vers un niveau plus profond (sous-catégories)
  deeper,
  /// Navigation vers un niveau parent (retour)
  back,
  /// Navigation vers la racine
  root,
}

/// Événement de rechargement des catégories
class CategoriesRefreshedEvent extends CategoryEvent {
  /// Nombre de catégories chargées
  final int categoryCount;

  /// Contexte du rechargement
  final String? context;

  const CategoriesRefreshedEvent({
    required this.categoryCount,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, categoryCount, context];

  @override
  String toString() => 'CategoriesRefreshedEvent(count: $categoryCount)';
}

/// Factory pour créer les événements de catégorie avec des IDs uniques
class CategoryEventFactory {
  static int _counter = 0;

  static String _generateEventId(String eventType) {
    _counter++;
    return '${eventType}_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }

  /// Crée un événement de création de catégorie
  static CategoryCreatedEvent createCategoryCreatedEvent({
    required Category category,
    String? context,
  }) {
    return CategoryCreatedEvent(
      category: category,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORY_CREATED'),
    );
  }

  /// Crée un événement de modification de catégorie
  static CategoryUpdatedEvent createCategoryUpdatedEvent({
    required Category updatedCategory,
    Category? previousCategory,
    List<String> modifiedFields = const [],
    String? context,
  }) {
    return CategoryUpdatedEvent(
      updatedCategory: updatedCategory,
      previousCategory: previousCategory,
      modifiedFields: modifiedFields,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORY_UPDATED'),
    );
  }

  /// Crée un événement de suppression de catégorie
  static CategoryDeletedEvent createCategoryDeletedEvent({
    required int categoryId,
    Category? deletedCategory,
    String? context,
  }) {
    return CategoryDeletedEvent(
      categoryId: categoryId,
      deletedCategory: deletedCategory,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORY_DELETED'),
    );
  }

  /// Crée un événement de sélection de catégorie
  static CategorySelectedEvent createCategorySelectedEvent({
    Category? selectedCategory,
    Category? previousCategory,
    String? context,
  }) {
    return CategorySelectedEvent(
      selectedCategory: selectedCategory,
      previousCategory: previousCategory,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORY_SELECTED'),
    );
  }

  /// Crée un événement de navigation de catégorie
  static CategoryNavigationEvent createCategoryNavigationEvent({
    Category? parentCategory,
    required int level,
    required CategoryNavigationDirection direction,
    String? context,
  }) {
    return CategoryNavigationEvent(
      parentCategory: parentCategory,
      level: level,
      direction: direction,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORY_NAVIGATION'),
    );
  }

  /// Crée un événement de rechargement de catégories
  static CategoriesRefreshedEvent createCategoriesRefreshedEvent({
    required int categoryCount,
    String? context,
  }) {
    return CategoriesRefreshedEvent(
      categoryCount: categoryCount,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('CATEGORIES_REFRESHED'),
    );
  }
}