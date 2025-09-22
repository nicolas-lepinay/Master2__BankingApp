import 'package:bankapp/presentation/viewmodels/base_view_model.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de base pour les ViewModels gérant des listes d'éléments
abstract class BaseListViewState<T> extends BaseViewState {
  /// Liste complète des éléments (non filtrée)
  final List<T> items;
  
  /// Liste filtrée des éléments
  final List<T> filteredItems;
  
  /// Requête de recherche actuelle
  final String searchQuery;
  
  /// Page actuelle (pour pagination)
  final int currentPage;
  
  /// Nombre d'éléments par page
  final int itemsPerPage;
  
  /// Indique si les données sont en cours de chargement
  final bool isLoading;
  
  /// Message d'erreur si présent
  final String? error;
  
  /// Plage de dates pour le filtrage (optionnel)
  final DateRange? dateFilter;

  const BaseListViewState({
    this.items = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.currentPage = 0,
    this.itemsPerPage = 20,
    this.isLoading = false,
    this.error,
    this.dateFilter,
  });

  // État dérivé pour la pagination
  bool get hasError => error != null;
  bool get hasItems => items.isNotEmpty;
  bool get hasFilteredItems => filteredItems.isNotEmpty;
  bool get isFiltered => searchQuery.isNotEmpty || dateFilter != null;
  
  int get totalPages => filteredItems.isEmpty ? 0 : (filteredItems.length / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;
  
  /// Obtient les éléments de la page actuelle
  List<T> get paginatedItems {
    if (filteredItems.isEmpty) return [];
    
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredItems.length);
    
    if (startIndex >= filteredItems.length) return [];
    
    return filteredItems.sublist(startIndex, endIndex);
  }
  
  /// Obtient des informations sur la pagination
  String get paginationInfo {
    if (filteredItems.isEmpty) return 'Aucun élément';
    
    final startIndex = currentPage * itemsPerPage + 1;
    final endIndex = ((currentPage + 1) * itemsPerPage).clamp(0, filteredItems.length);
    
    return '$startIndex-$endIndex sur ${filteredItems.length}';
  }
}

/// ViewModel de base pour la gestion de listes avec pagination, filtrage et recherche
/// 
/// Cette classe simplifie le développement de ViewModels gérant des listes en fournissant
/// des fonctionnalités communes comme la pagination, le filtrage et la recherche.
/// Elle utilise le nouveau système Event Bus pour la communication entre ViewModels.
abstract class BaseListViewModel<TState extends BaseListViewState<TItem>, TItem> 
    extends StateNotifier<TState> {
  
  BaseListViewModel(super.initialState) {
    // S'abonner aux événements de l'Event Bus si nécessaire
    _subscribeToEvents();
  }

  // ============================================================================
  // GESTION DES ÉVÉNEMENTS
  // ============================================================================

  /// S'abonne aux événements de l'Event Bus
  void _subscribeToEvents() {
    // Les sous-classes peuvent override cette méthode pour s'abonner à des événements spécifiques
  }

  // ============================================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================================

  /// Charge tous les éléments - doit être implémenté par les sous-classes
  Future<List<TItem>> loadAllItems();

  /// Rafraîchit les données
  Future<void> refresh() async {
    try {
      state = setLoading(true);
      
      final items = await loadAllItems();
      state = setItems(items);
      
      // Appliquer les filtres existants
      await _applyCurrentFilters();
    } catch (error) {
      state = setError(error.toString());
    }
  }

  /// Charge les données initiales
  Future<void> initialize() async {
    if (state.hasItems) return; // Éviter le double chargement
    await refresh();
  }

  // ============================================================================
  // RECHERCHE ET FILTRAGE
  // ============================================================================

  /// Met à jour la requête de recherche
  Future<void> updateSearchQuery(String query) async {
    state = updateSearchQueryState(query);
    await _applyCurrentFilters();
  }

  /// Efface la recherche
  Future<void> clearSearch() async {
    await updateSearchQuery('');
  }

  /// Met à jour le filtre de date
  Future<void> updateDateFilter(DateRange? dateRange) async {
    state = updateDateFilterState(dateRange);
    await _applyCurrentFilters();
  }

  /// Efface tous les filtres
  Future<void> clearFilters() async {
    state = clearFiltersState();
    await _applyCurrentFilters();
  }

  /// Applique les filtres actuels - peut être étendu par les sous-classes
  Future<void> _applyCurrentFilters() async {
    var filteredItems = List<TItem>.from(state.items);

    // Filtrage par recherche
    if (state.searchQuery.isNotEmpty) {
      filteredItems = applySearchFilter(filteredItems, state.searchQuery);
    }

    // Filtrage par date
    if (state.dateFilter != null) {
      filteredItems = applyDateFilter(filteredItems, state.dateFilter!);
    }

    // Appliquer filtres supplémentaires définis par les sous-classes
    filteredItems = await applyCustomFilters(filteredItems);

    // Trier les résultats
    filteredItems = sortItems(filteredItems);

    state = setFilteredItems(filteredItems);
  }

  /// Applique le filtre de recherche - doit être implémenté par les sous-classes
  List<TItem> applySearchFilter(List<TItem> items, String query);

  /// Applique le filtre de date - peut être override par les sous-classes
  List<TItem> applyDateFilter(List<TItem> items, DateRange dateRange) {
    // Par défaut, ne fait rien - les sous-classes peuvent override
    return items;
  }

  /// Applique des filtres personnalisés - peut être override par les sous-classes
  Future<List<TItem>> applyCustomFilters(List<TItem> items) async {
    return items; // Par défaut, ne fait rien
  }

  /// Trie les éléments - peut être override par les sous-classes
  List<TItem> sortItems(List<TItem> items) {
    return items; // Par défaut, conserve l'ordre actuel
  }

  // ============================================================================
  // PAGINATION
  // ============================================================================

  /// Passe à la page suivante
  void nextPage() {
    if (state.hasNextPage) {
      state = setCurrentPage(state.currentPage + 1);
    }
  }

  /// Passe à la page précédente
  void previousPage() {
    if (state.hasPreviousPage) {
      state = setCurrentPage(state.currentPage - 1);
    }
  }

  /// Va à une page spécifique
  void goToPage(int page) {
    final clampedPage = page.clamp(0, state.totalPages - 1);
    state = setCurrentPage(clampedPage);
  }

  /// Met à jour le nombre d'éléments par page
  void updateItemsPerPage(int itemsPerPage) {
    final clampedItemsPerPage = itemsPerPage.clamp(1, 100);
    state = setItemsPerPage(clampedItemsPerPage);
    // Reset à la première page
    state = setCurrentPage(0);
  }

  /// Remet la pagination à la première page
  void resetPagination() {
    state = setCurrentPage(0);
  }

  // ============================================================================
  // MÉTHODES D'ÉTAT ABSTRAITES - À IMPLÉMENTER PAR LES SOUS-CLASSES
  // ============================================================================

  /// Met à jour l'état de chargement - doit être implémenté par les sous-classes
  TState setLoading(bool isLoading);

  /// Met à jour l'état d'erreur - doit être implémenté par les sous-classes
  TState setError(String error);

  /// Met à jour la liste des éléments - doit être implémenté par les sous-classes
  TState setItems(List<TItem> items);

  /// Met à jour la liste filtrée - doit être implémenté par les sous-classes
  TState setFilteredItems(List<TItem> filteredItems);

  /// Met à jour la requête de recherche - doit être implémenté par les sous-classes
  TState updateSearchQueryState(String query);

  /// Met à jour le filtre de date - doit être implémenté par les sous-classes
  TState updateDateFilterState(DateRange? dateFilter);

  /// Met à jour la page actuelle - doit être implémenté par les sous-classes
  TState setCurrentPage(int currentPage);

  /// Met à jour le nombre d'éléments par page - doit être implémenté par les sous-classes
  TState setItemsPerPage(int itemsPerPage);

  /// Efface tous les filtres - doit être implémenté par les sous-classes
  TState clearFiltersState();

  // ============================================================================
  // GESTION D'ERREUR ET NETTOYAGE
  // ============================================================================

  @override
  void dispose() {
    // Nettoyage des abonnements aux événements si nécessaire
    super.dispose();
  }
}

/// Mixin pour ajouter des fonctionnalités de tri avancé
mixin SortableListMixin<TState extends BaseListViewState<TItem>, TItem> 
    on BaseListViewModel<TState, TItem> {
  
  /// Options de tri disponibles
  Map<String, int Function(TItem, TItem)> get availableSorts => {};
  
  /// Tri actuellement sélectionné
  String? _currentSort;
  bool _sortAscending = true;
  
  String? get currentSort => _currentSort;
  bool get sortAscending => _sortAscending;

  /// Applique un tri spécifique
  void applySorting(String sortKey, {bool? ascending}) {
    _currentSort = sortKey;
    _sortAscending = ascending ?? true;
    
    // Réappliquer les filtres avec le nouveau tri
    _applyCurrentFilters();
  }

  /// Inverse l'ordre de tri
  void toggleSortOrder() {
    if (_currentSort != null) {
      applySorting(_currentSort!, ascending: !_sortAscending);
    }
  }

  @override
  List<TItem> sortItems(List<TItem> items) {
    if (_currentSort == null || !availableSorts.containsKey(_currentSort)) {
      return super.sortItems(items);
    }

    final comparator = availableSorts[_currentSort]!;
    final sortedItems = List<TItem>.from(items);
    
    sortedItems.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
    
    return sortedItems;
  }
}