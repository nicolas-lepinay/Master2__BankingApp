import 'package:flutter/material.dart';

import 'package:bankapp/core/icons/icon_entry.dart';
import 'package:bankapp/core/icons/icons_registry.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';

/// État pour le IconTestViewModel - gestion de la page de test des icônes
class IconTestViewState extends BaseViewState {
  /// Liste des icônes actuellement affichées
  final List<IconEntry> icons;

  /// Texte de recherche actuel
  final String searchQuery;

  /// Résultats de recherche avec métriques
  final SearchResult? searchResult;

  /// Indique si une recherche est en cours
  final bool isSearching;

  /// Catégorie sélectionnée pour le filtrage
  final String? selectedCategory;

  /// Set d'icônes sélectionné pour le filtrage
  final String? selectedSet;

  /// Type d'affichage actuel (populaires, recherche, catégorie)
  final IconDisplayType displayType;

  /// Message à afficher à l'utilisateur
  final String? displayMessage;

  const IconTestViewState({
    this.icons = const [],
    this.searchQuery = '',
    this.searchResult,
    this.isSearching = false,
    this.selectedCategory,
    this.selectedSet,
    this.displayType = IconDisplayType.popular,
    this.displayMessage,
  });

  IconTestViewState copyWith({
    List<IconEntry>? icons,
    String? searchQuery,
    SearchResult? searchResult,
    bool? isSearching,
    String? selectedCategory,
    String? selectedSet,
    IconDisplayType? displayType,
    String? displayMessage,
    bool clearSearchResult = false,
    bool clearSelectedCategory = false,
    bool clearSelectedSet = false,
  }) {
    return IconTestViewState(
      icons: icons ?? this.icons,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResult: clearSearchResult ? null : (searchResult ?? this.searchResult),
      isSearching: isSearching ?? this.isSearching,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedSet: clearSelectedSet ? null : (selectedSet ?? this.selectedSet),
      displayType: displayType ?? this.displayType,
      displayMessage: displayMessage ?? this.displayMessage,
    );
  }

  /// Indique si des icônes sont disponibles
  bool get hasIcons => icons.isNotEmpty;

  /// Nombre total d'icônes affichées
  int get iconCount => icons.length;

  /// Message d'état en fonction du type d'affichage
  String get statusMessage {
    if (displayMessage != null) return displayMessage!;
    
    switch (displayType) {
      case IconDisplayType.popular:
        return 'Icônes populaires ($iconCount)';
      case IconDisplayType.search:
        final totalResults = searchResult?.totalResults ?? iconCount;
        final searchTime = searchResult?.searchTimeMs ?? 0;
        return '$totalResults résultats pour "$searchQuery" (${searchTime}ms)';
      case IconDisplayType.category:
        return 'Catégorie: $selectedCategory ($iconCount icônes)';
      case IconDisplayType.set:
        return 'Set: $selectedSet ($iconCount icônes)';
    }
  }

  @override
  String toString() => 'IconTestViewState(icons: ${icons.length}, searchQuery: $searchQuery, displayType: $displayType)';
}

/// Types d'affichage des icônes
enum IconDisplayType {
  popular,
  search,
  category,
  set,
}

/// ViewModel pour la page de test des icônes
class IconTestViewModel extends BaseViewModel<IconTestViewState> {
  IconTestViewModel() : super(const IconTestViewState()) {
    _loadPopularIcons();
  }

  /// Charge les icônes populaires au démarrage
  Future<void> _loadPopularIcons() async {
    await executeWithErrorHandling(() async {
      state = state.copyWith(
        isSearching: true,
        displayType: IconDisplayType.popular,
      );

      final popularIcons = IconsRegistry.getPopularIcons(limit: 100);

      state = state.copyWith(
        icons: popularIcons,
        isSearching: false,
        searchQuery: '',
        displayType: IconDisplayType.popular,
        clearSearchResult: true,
        clearSelectedCategory: true,
        clearSelectedSet: true,
      );
    });
  }

  /// Effectue une recherche d'icônes par query
  Future<void> searchIcons(String query) async {
    final trimmedQuery = query.trim();

    // Si la query est vide, revenir aux icônes populaires
    if (trimmedQuery.isEmpty) {
      await _loadPopularIcons();
      return;
    }

    // Éviter les recherches redondantes
    if (trimmedQuery == state.searchQuery && state.displayType == IconDisplayType.search) {
      return;
    }

    await executeWithErrorHandling(() async {
      state = state.copyWith(
        isSearching: true,
        searchQuery: trimmedQuery,
        displayType: IconDisplayType.search,
      );

      final searchResult = IconsRegistry.searchWithMetrics(
        query: trimmedQuery,
        category: state.selectedCategory,
        setName: state.selectedSet,
        limit: 100,
      );

      state = state.copyWith(
        icons: searchResult.icons,
        searchResult: searchResult,
        isSearching: false,
        displayType: IconDisplayType.search,
      );
    });
  }

  /// Filtre par catégorie
  Future<void> filterByCategory(String? category) async {
    await executeWithErrorHandling(() async {
      state = state.copyWith(
        isSearching: true,
        selectedCategory: category,
        displayType: IconDisplayType.category,
      );

      List<IconEntry> icons;
      if (category != null) {
        icons = IconsRegistry.getIconsByCategory(category);
      } else {
        // Retour aux icônes populaires si aucune catégorie
        icons = IconsRegistry.getPopularIcons(limit: 100);
      }

      state = state.copyWith(
        icons: icons.take(100).toList(),
        isSearching: false,
        searchQuery: '',
        displayType: category != null ? IconDisplayType.category : IconDisplayType.popular,
        clearSearchResult: true,
      );
    });
  }

  /// Filtre par set d'icônes
  Future<void> filterBySet(String? setName) async {
    await executeWithErrorHandling(() async {
      state = state.copyWith(
        isSearching: true,
        selectedSet: setName,
        displayType: IconDisplayType.set,
      );

      List<IconEntry> icons;
      if (setName != null) {
        icons = IconsRegistry.getIconsBySet(setName);
      } else {
        // Retour aux icônes populaires si aucun set
        icons = IconsRegistry.getPopularIcons(limit: 100);
      }

      state = state.copyWith(
        icons: icons.take(100).toList(),
        isSearching: false,
        searchQuery: '',
        displayType: setName != null ? IconDisplayType.set : IconDisplayType.popular,
        clearSearchResult: true,
      );
    });
  }

  /// Recharge les données
  Future<void> refresh() async {
    switch (state.displayType) {
      case IconDisplayType.popular:
        await _loadPopularIcons();
        break;
      case IconDisplayType.search:
        await searchIcons(state.searchQuery);
        break;
      case IconDisplayType.category:
        await filterByCategory(state.selectedCategory);
        break;
      case IconDisplayType.set:
        await filterBySet(state.selectedSet);
        break;
    }
  }

  /// Efface les filtres et revient aux icônes populaires
  Future<void> clearFilters() async {
    await _loadPopularIcons();
  }

  /// Remet le ViewModel à son état initial (implémentation requise par BaseViewModel)
  @override
  void resetToInitialState() {
    state = const IconTestViewState();
    // Recharger les icônes populaires de manière asynchrone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPopularIcons();
    });
  }

  /// Obtient les catégories disponibles
  List<IconCategory> getAvailableCategories() {
    try {
      return IconsRegistry.getAvailableCategories();
    } catch (e) {
      return [];
    }
  }

  /// Obtient les sets disponibles
  List<IconSet> getAvailableSets() {
    try {
      return IconsRegistry.getAvailableSets();
    } catch (e) {
      return [];
    }
  }

  /// Obtient les statistiques globales
  Map<String, dynamic> getStatistics() {
    try {
      return IconsRegistry.getStatistics();
    } catch (e) {
      return {};
    }
  }
}