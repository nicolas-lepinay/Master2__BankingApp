import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/category_events.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:bankapp/domain/repositories/category_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'package:flutter/foundation.dart';

/// États pour la création de catégorie
class CategoryCreationViewState extends BaseViewState {
  final String categoryName;
  final List<domain.Category> parentBreadcrumbs;
  final domain.Category? parentCategory;
  final bool isCreating;
  final bool isNameValid;
  final String? nameError;
  final domain.Category? createdCategory;

  const CategoryCreationViewState({
    this.categoryName = '',
    this.parentBreadcrumbs = const [],
    this.parentCategory,
    this.isCreating = false,
    this.isNameValid = false,
    this.nameError,
    this.createdCategory,
  });

  CategoryCreationViewState copyWith({
    String? categoryName,
    List<domain.Category>? parentBreadcrumbs,
    domain.Category? parentCategory,
    bool? isCreating,
    bool? isNameValid,
    String? nameError,
    domain.Category? createdCategory,
  }) {
    return CategoryCreationViewState(
      categoryName: categoryName ?? this.categoryName,
      parentBreadcrumbs: parentBreadcrumbs ?? this.parentBreadcrumbs,
      parentCategory: parentCategory ?? this.parentCategory,
      isCreating: isCreating ?? this.isCreating,
      isNameValid: isNameValid ?? this.isNameValid,
      nameError: nameError ?? this.nameError,
      createdCategory: createdCategory ?? this.createdCategory,
    );
  }

  bool get canCreate =>
      isNameValid && !isCreating && categoryName.trim().isNotEmpty;
  int get newCategoryLevel => (parentCategory?.level ?? 0) + 1;

  @override
  String toString() =>
      'CategoryCreationViewState(name: $categoryName, valid: $isNameValid, creating: $isCreating)';
}

/// ViewModel pour la création de nouvelles catégories
///
/// Gère la validation du nom, la vérification d'unicité,
/// et la création via le repository avec Event Bus
class CategoryCreationViewModel
    extends BaseViewModel<CategoryCreationViewState> {
  final CategoryRepository _categoryRepository;

  CategoryCreationViewModel(this._categoryRepository)
    : super(const CategoryCreationViewState());

  /// Initialise la création avec le contexte parent
  void initializeCreation({
    required List<domain.Category> parentBreadcrumbs,
    domain.Category? parentCategory,
  }) {
    state = state.copyWith(
      parentBreadcrumbs: parentBreadcrumbs,
      parentCategory: parentCategory,
      categoryName: '',
      isNameValid: false,
      nameError: null,
      createdCategory: null,
    );

    if (kDebugMode) {
      print(
        '📝 Category creation initialized with parent: ${parentCategory?.label ?? 'root'}',
      );
    }
  }

  /// Met à jour le nom de la catégorie et valide
  void updateCategoryName(String name) {
    final trimmedName = name.trim();

    state = state.copyWith(categoryName: name, nameError: null);

    // Validation en temps réel
    _validateCategoryName(trimmedName);
  }

  /// Valide le nom de la catégorie
  void _validateCategoryName(String name) {
    if (name.isEmpty) {
      state = state.copyWith(
        isNameValid: false,
        nameError: null, // Pas d'erreur si vide, juste invalide
      );
      return;
    }

    if (name.length < 2) {
      state = state.copyWith(
        isNameValid: false,
        nameError: 'Le nom doit contenir au moins 2 caractères',
      );
      return;
    }

    if (name.length > 50) {
      state = state.copyWith(
        isNameValid: false,
        nameError: 'Le nom ne peut pas dépasser 50 caractères',
      );
      return;
    }

    // Validation des caractères spéciaux
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) {
      state = state.copyWith(
        isNameValid: false,
        nameError: 'Le nom contient des caractères non autorisés',
      );
      return;
    }

    // Nom valide
    state = state.copyWith(isNameValid: true, nameError: null);
  }

  /// Crée la nouvelle catégorie
  Future<bool> createCategory() async {
    if (!state.canCreate) {
      if (kDebugMode) {
        print('❌ Cannot create category: invalid state');
      }
      return false;
    }

    state = state.copyWith(isCreating: true, nameError: null);

    try {
      final trimmedName = state.categoryName.trim();

      // Vérifier l'unicité via le repository
      final existingCategories = await _categoryRepository.getAllCategories();
      final parentId = state.parentCategory?.id;
      final level = state.newCategoryLevel;

      final isDuplicate = existingCategories.any(
        (cat) =>
            cat.label.toLowerCase() == trimmedName.toLowerCase() &&
            cat.parentId == parentId &&
            cat.level == level,
      );

      if (isDuplicate) {
        state = state.copyWith(
          isCreating: false,
          nameError: 'Une catégorie avec ce nom existe déjà à ce niveau',
        );
        return false;
      }

      // Créer la nouvelle catégorie
      final newCategory = domain.Category(
        id: 0, // Sera assigné par la DB
        label: trimmedName,
        level: level,
        parentId: parentId,
        icon: null, // TODO: sera ajouté dans une future version
        iconColor: null, // TODO: sera ajouté dans une future version
      );

      final createdCategory = await _categoryRepository.createCategory(
        newCategory,
      );

      state = state.copyWith(
        isCreating: false,
        createdCategory: createdCategory,
      );

      // Émettre l'événement de création pour réactivité
      AppEventBus.instance.fire(
        CategoryEventFactory.createCategoryCreatedEvent(
          category: createdCategory,
          context: 'category_creation_bottom_sheet',
        ),
      );

      if (kDebugMode) {
        print(
          '✅ Category created successfully: ${createdCategory.label} (ID: ${createdCategory.id})',
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        nameError: 'Erreur lors de la création: ${e.toString()}',
      );

      if (kDebugMode) {
        print('❌ Error creating category: $e');
      }

      return false;
    }
  }

  /// Réinitialise l'état pour une nouvelle création
  void resetCreation() {
    state = state.copyWith(
      categoryName: '',
      isNameValid: false,
      nameError: null,
      isCreating: false,
      createdCategory: null,
    );
  }

  /// Obtient les breadcrumbs complets pour l'affichage
  List<domain.Category> getFullBreadcrumbs() {
    final breadcrumbs = <domain.Category>[...state.parentBreadcrumbs];

    if (state.parentCategory != null) {
      breadcrumbs.add(state.parentCategory!);
    }

    return breadcrumbs;
  }

  @override
  void resetToInitialState() {
    state = const CategoryCreationViewState();
  }
}
