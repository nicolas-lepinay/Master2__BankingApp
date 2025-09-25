import 'dart:async';

import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/category_events.dart';
import 'package:bankapp/domain/entities/category.dart' as domain;
import 'package:bankapp/domain/repositories/category_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'package:bankapp/presentation/widgets/forms/category_selection_widget.dart';
import 'package:flutter/foundation.dart';

/// Mode d'affichage pour la sélection de catégories
enum CategoryDisplayMode {
  /// Vue d'ensemble : niveaux 1 et 2 simultanés (Dépenses + sous-catégories, Revenus + sous-catégories)
  rootOverview,
  /// Détail d'une sous-catégorie : navigation dans niveau 3+
  subcategoryDetail,
}

/// Groupe de catégories niveau 1 avec ses enfants niveau 2
class CategoryGroup {
  final domain.Category parentCategory;
  final List<domain.Category> subcategories;

  const CategoryGroup({
    required this.parentCategory,
    required this.subcategories,
  });
}

/// États pour la sélection de catégories
class CategorySelectionViewState extends BaseViewState {
  final List<domain.Category> allCategories;
  final List<domain.Category> currentLevelCategories;
  final List<domain.Category> navigationStack;
  final domain.Category? selectedCategory;
  final bool isLoading;
  final String? error;
  final int currentLevel;
  final domain.Category? currentParent;

  // Nouveaux champs pour la structure niveau 1+2
  final CategoryDisplayMode displayMode;
  final List<CategoryGroup> categoryGroups;

  const CategorySelectionViewState({
    this.allCategories = const [],
    this.currentLevelCategories = const [],
    this.navigationStack = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
    this.currentLevel = 1,
    this.currentParent,
    this.displayMode = CategoryDisplayMode.rootOverview,
    this.categoryGroups = const [],
  });

  CategorySelectionViewState copyWith({
    List<domain.Category>? allCategories,
    List<domain.Category>? currentLevelCategories,
    List<domain.Category>? navigationStack,
    domain.Category? selectedCategory,
    bool? isLoading,
    String? error,
    int? currentLevel,
    domain.Category? currentParent,
    CategoryDisplayMode? displayMode,
    List<CategoryGroup>? categoryGroups,
    bool clearSelectedCategory = false,
  }) {
    return CategorySelectionViewState(
      allCategories: allCategories ?? this.allCategories,
      currentLevelCategories: currentLevelCategories ?? this.currentLevelCategories,
      navigationStack: navigationStack ?? this.navigationStack,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentLevel: currentLevel ?? this.currentLevel,
      currentParent: currentParent ?? this.currentParent,
      displayMode: displayMode ?? this.displayMode,
      categoryGroups: categoryGroups ?? this.categoryGroups,
    );
  }

  bool get hasParent => currentParent != null;
  bool get canNavigateBack => displayMode == CategoryDisplayMode.subcategoryDetail;
  bool get isRootOverview => displayMode == CategoryDisplayMode.rootOverview;
  bool get isSubcategoryDetail => displayMode == CategoryDisplayMode.subcategoryDetail;

  @override
  String toString() =>
      'CategorySelectionViewState(mode: $displayMode, level: $currentLevel, categories: ${currentLevelCategories.length}, groups: ${categoryGroups.length}, selected: ${selectedCategory?.label})';
}

/// ViewModel pour la sélection hiérarchique de catégories
///
/// Gère la navigation dans l'arborescence des catégories, la sélection,
/// et la communication avec le repository via l'Event Bus
class CategorySelectionViewModel extends BaseViewModel<CategorySelectionViewState> {
  final CategoryRepository _categoryRepository;
  late final StreamSubscription<CategoryCreatedEvent> _categoryCreatedSubscription;

  CategorySelectionViewModel(
    this._categoryRepository,
  ) : super(const CategorySelectionViewState()) {
    _initializeEventListeners();
  }

  /// Initialise les écouteurs d'événements
  void _initializeEventListeners() {
    // Écouter les événements de création de catégories
    _categoryCreatedSubscription = AppEventBus.instance
        .on<CategoryCreatedEvent>()
        .listen(_onCategoryCreated);
  }

  /// Gère l'événement de création de nouvelle catégorie
  void _onCategoryCreated(CategoryCreatedEvent event) {
    if (kDebugMode) {
      print('📂 CategorySelectionViewModel: Nouvelle catégorie créée ${event.category.label}');
    }

    // Recharger les catégories en préservant la navigation actuelle
    _refreshCategoriesPreservingNavigation();
  }

  /// Recharge les catégories depuis la DB en préservant la navigation actuelle
  Future<void> _refreshCategoriesPreservingNavigation() async {
    try {
      // Sauvegarder l'état actuel de la navigation
      final currentDisplayMode = state.displayMode;
      final currentLevel = state.currentLevel;
      final currentParent = state.currentParent;
      final currentNavigationStack = state.navigationStack;
      final currentSelectedCategory = state.selectedCategory;

      // Recharger toutes les catégories depuis la DB
      final categories = await _categoryRepository.getAllCategories();

      if (currentDisplayMode == CategoryDisplayMode.rootOverview) {
        // Mode vue d'ensemble : reconstruire les groups
        final categoryGroups = _buildCategoryGroups(categories);

        state = state.copyWith(
          allCategories: categories,
          categoryGroups: categoryGroups,
          selectedCategory: currentSelectedCategory,
        );
      } else {
        // Mode détail : reconstruire le niveau actuel en préservant la navigation
        if (currentParent != null) {
          // Retrouver le parent actualisé depuis les nouvelles données
          final updatedParent = categories.firstWhere(
            (cat) => cat.id == currentParent.id,
            orElse: () => currentParent,
          );

          // Recalculer les catégories du niveau actuel
          final updatedCurrentLevelCategories = categories
              .where((cat) => cat.parentId == updatedParent.id)
              .toList();

          state = state.copyWith(
            allCategories: categories,
            currentLevelCategories: updatedCurrentLevelCategories,
            currentParent: updatedParent,
            selectedCategory: currentSelectedCategory,
            // Préserver le reste de la navigation
            displayMode: currentDisplayMode,
            currentLevel: currentLevel,
            navigationStack: currentNavigationStack,
          );
        }
      }

      if (kDebugMode) {
        print('📂 Categories refreshed while preserving navigation - Mode: $currentDisplayMode, Level: $currentLevel');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing categories: $e');
      }
      // En cas d'erreur, faire un rechargement complet en dernier recours
      loadCategories();
    }
  }

  /// Charge toutes les catégories et initialise l'état (vue d'ensemble ou restauration)
  Future<void> loadCategories({CategoryNavigationState? restoreState}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _categoryRepository.getAllCategories();

      // Si un état de restauration est fourni, l'appliquer
      if (restoreState != null &&
          restoreState.displayMode == CategoryDisplayMode.subcategoryDetail &&
          restoreState.currentParent != null) {

        // Mode détail : restaurer la navigation
        final currentLevelCategories = categories
            .where((cat) => cat.parentId == restoreState.currentParent!.id)
            .toList();

        state = state.copyWith(
          allCategories: categories,
          displayMode: restoreState.displayMode,
          currentParent: restoreState.currentParent,
          currentLevel: restoreState.currentParent!.level + 1,
          navigationStack: restoreState.navigationStack,
          currentLevelCategories: currentLevelCategories,
          categoryGroups: [], // Vide en mode detail
          isLoading: false,
        );

        if (kDebugMode) {
          print('📂 Loaded ${categories.length} categories, restored to detail mode: ${restoreState.currentParent!.label}');
        }
      } else {
        // Mode par défaut : vue d'ensemble
        final categoryGroups = _buildCategoryGroups(categories);

        state = state.copyWith(
          allCategories: categories,
          categoryGroups: categoryGroups,
          displayMode: CategoryDisplayMode.rootOverview,
          currentLevel: 1,
          currentParent: null,
          navigationStack: [],
          currentLevelCategories: [], // Vide en mode overview
          isLoading: false,
        );

        if (kDebugMode) {
          print('📂 Loaded ${categories.length} categories, ${categoryGroups.length} groups in overview mode');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      if (kDebugMode) {
        print('❌ Error loading categories: $e');
      }
    }
  }

  /// Construit les groupes de catégories niveau 1 avec leurs enfants niveau 2
  List<CategoryGroup> _buildCategoryGroups(List<domain.Category> allCategories) {
    final level1Categories = allCategories.where((cat) => cat.level == 1).toList();
    final groups = <CategoryGroup>[];

    for (final parent in level1Categories) {
      final subcategories = allCategories
          .where((cat) => cat.parentId == parent.id)
          .toList();

      groups.add(CategoryGroup(
        parentCategory: parent,
        subcategories: subcategories,
      ));
    }

    return groups;
  }

  /// Navigue vers les sous-catégories d'une catégorie parent (niveau 3+)
  void navigateToSubcategories(domain.Category parentCategory) {
    final subcategories = state.allCategories
        .where((cat) => cat.parentId == parentCategory.id)
        .toList();

    // Construire la nouvelle pile de navigation
    List<domain.Category> newStack = [];

    if (state.isRootOverview) {
      // Navigation depuis la vue d'ensemble : stack reste vide pour le premier niveau
      newStack = [];
    } else {
      // Navigation depuis un niveau détail : ajouter le parent actuel au stack
      newStack = [...state.navigationStack];
      if (state.currentParent != null) {
        newStack.add(state.currentParent!);
      }
    }

    // Toujours naviguer, même si la liste est vide (pour permettre l'ajout)
    state = state.copyWith(
      displayMode: CategoryDisplayMode.subcategoryDetail,
      currentLevelCategories: subcategories,
      currentLevel: parentCategory.level + 1,
      currentParent: parentCategory,
      navigationStack: newStack,
      categoryGroups: [], // Vide en mode detail
    );

    if (kDebugMode) {
      print('📂 Navigated to ${subcategories.length} subcategories of ${parentCategory.label} (detail mode, stack depth: ${newStack.length}, from ${state.isRootOverview ? "overview" : "detail"})');
    }
  }

  /// Retourne à la vue d'ensemble (niveau 1+2)
  void navigateToOverview() {
    final categoryGroups = _buildCategoryGroups(state.allCategories);

    state = state.copyWith(
      displayMode: CategoryDisplayMode.rootOverview,
      categoryGroups: categoryGroups,
      currentLevelCategories: [],
      currentLevel: 1,
      currentParent: null,
      navigationStack: [],
    );

    if (kDebugMode) {
      print('📂 Returned to overview mode with ${categoryGroups.length} groups - State fully reset');
    }
  }

  /// Navigue vers le niveau parent (retour en arrière)
  void navigateBack() {
    if (!state.isSubcategoryDetail) return;

    if (kDebugMode) {
      print('📂 NavigateBack called - Stack depth: ${state.navigationStack.length}, Current: ${state.currentParent?.label}');
    }

    // Si pas de stack de navigation, retourner à la vue d'ensemble
    if (state.navigationStack.isEmpty) {
      if (kDebugMode) {
        print('📂 Empty stack, returning to overview');
      }
      navigateToOverview();
      return;
    }

    // Sinon, remonter d'un niveau dans la stack
    final newStack = [...state.navigationStack];
    final previousParent = newStack.removeLast();

    // Récupérer les catégories du niveau précédent
    final previousCategories = state.allCategories
        .where((cat) => cat.parentId == previousParent.id)
        .toList();

    state = state.copyWith(
      currentLevelCategories: previousCategories,
      currentLevel: previousParent.level + 1,
      currentParent: previousParent,
      navigationStack: newStack,
    );

    if (kDebugMode) {
      print('📂 Navigated back to ${previousParent.label} (stack depth: ${newStack.length})');
    }
  }

  /// Sélectionne ou désélectionne une catégorie (toggle)
  /// Seules les catégories niveau 2+ peuvent être sélectionnées
  void toggleCategorySelection(domain.Category category) {
    // Empêcher la sélection des catégories niveau 1
    if (category.level == 1) {
      if (kDebugMode) {
        print('📂 Cannot select level 1 category: ${category.label}');
      }
      return;
    }

    final isCurrentlySelected = state.selectedCategory?.id == category.id;

    if (isCurrentlySelected) {
      // Désélectionner
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      // Sélectionner la nouvelle catégorie
      state = state.copyWith(selectedCategory: category);
    }

    if (kDebugMode) {
      print('📂 Category selection: ${isCurrentlySelected ? 'none (deselected)' : category.label}');
    }
  }

  /// Vérifie si une catégorie peut être sélectionnée
  bool canSelectCategory(domain.Category category) {
    return category.level >= 2; // Seulement niveau 2+
  }

  /// Vérifie si une catégorie a des sous-catégories (utilisé pour info)
  bool hasSubcategories(domain.Category category) {
    return state.allCategories.any((cat) => cat.parentId == category.id);
  }

  /// Détermine si le chevron doit être affiché (toujours true selon nouvelles specs)
  bool shouldShowChevron(domain.Category category) {
    // Toujours afficher le chevron pour niveau 2+ pour permettre navigation/ajout
    return category.level >= 2;
  }

  /// Obtient les breadcrumbs pour la navigation actuelle (mode subcategoryDetail)
  List<domain.Category> getCurrentBreadcrumbs() {
    if (state.isRootOverview || state.currentParent == null) {
      return [];
    }

    // En mode subcategoryDetail, construire les breadcrumbs depuis le parent actuel
    final breadcrumbs = <domain.Category>[];

    // Ajouter les ancêtres du parent actuel
    domain.Category? current = state.currentParent;
    while (current != null) {
      breadcrumbs.insert(0, current); // Insérer au début pour l'ordre correct
      // Chercher le parent de cette catégorie
      try {
        current = state.allCategories.firstWhere(
          (cat) => cat.id == current!.parentId,
        );
      } catch (e) {
        current = null;
      }
    }

    return breadcrumbs;
  }

  /// Réinitialise la sélection
  void clearSelection() {
    state = state.copyWith(selectedCategory: null);
  }

  /// Restaure un état de navigation spécifique (pour persistance externe)
  Future<void> restoreNavigationState({
    required CategoryDisplayMode displayMode,
    required domain.Category currentParent,
    required List<domain.Category> navigationStack,
  }) async {
    try {
      if (displayMode == CategoryDisplayMode.subcategoryDetail) {
        // Calculer les catégories du niveau actuel à partir du parent
        final currentLevelCategories = state.allCategories
            .where((cat) => cat.parentId == currentParent.id)
            .toList();

        // Appliquer l'état restauré
        state = state.copyWith(
          displayMode: displayMode,
          currentParent: currentParent,
          currentLevel: currentParent.level + 1,
          navigationStack: navigationStack,
          currentLevelCategories: currentLevelCategories,
          categoryGroups: [], // Vide en mode detail
        );

        if (kDebugMode) {
          print('📂 Navigation state restored: ${currentParent.label} (level ${currentParent.level + 1}, stack depth: ${navigationStack.length})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring navigation state: $e');
      }
      // En cas d'erreur, revenir à la vue d'ensemble
      navigateToOverview();
    }
  }

  /// Réinitialise la navigation à la vue d'ensemble
  void resetNavigation() {
    navigateToOverview();
  }

  @override
  void resetToInitialState() {
    state = const CategorySelectionViewState();
  }

  @override
  void dispose() {
    _categoryCreatedSubscription.cancel();
    super.dispose();
  }
}