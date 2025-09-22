import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';

/// Enum pour les types de recherche
enum SearchType { all, keyword, amount, category, counterparty, date }

/// Filtres de recherche
class SearchFilters {
  final String keyword;
  final double? minAmount;
  final double? maxAmount;
  final int? categoryId;
  final int? counterpartyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final SearchType activeType;

  const SearchFilters({
    this.keyword = '',
    this.minAmount,
    this.maxAmount,
    this.categoryId,
    this.counterpartyId,
    this.startDate,
    this.endDate,
    this.activeType = SearchType.all,
  });

  SearchFilters copyWith({
    String? keyword,
    double? minAmount,
    double? maxAmount,
    int? categoryId,
    int? counterpartyId,
    DateTime? startDate,
    DateTime? endDate,
    SearchType? activeType,
  }) {
    return SearchFilters(
      keyword: keyword ?? this.keyword,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      categoryId: categoryId ?? this.categoryId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activeType: activeType ?? this.activeType,
    );
  }

  /// Efface tous les filtres
  SearchFilters clear() {
    return const SearchFilters();
  }

  /// Efface un filtre spécifique
  SearchFilters clearFilter(SearchType type) {
    switch (type) {
      case SearchType.keyword:
        return copyWith(keyword: '');
      case SearchType.amount:
        return copyWith(minAmount: null, maxAmount: null);
      case SearchType.category:
        return copyWith(categoryId: null);
      case SearchType.counterparty:
        return copyWith(counterpartyId: null);
      case SearchType.date:
        return copyWith(startDate: null, endDate: null);
      case SearchType.all:
        return clear();
    }
  }

  /// Indique si des filtres sont actifs
  bool get hasActiveFilters =>
      keyword.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      categoryId != null ||
      counterpartyId != null ||
      startDate != null ||
      endDate != null;

  /// Obtient le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (keyword.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (categoryId != null) count++;
    if (counterpartyId != null) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  @override
  String toString() =>
      'SearchFilters(keyword: "$keyword", minAmount: $minAmount, maxAmount: $maxAmount, categoryId: $categoryId, counterpartyId: $counterpartyId, startDate: $startDate, endDate: $endDate, activeType: $activeType)';
}

/// État pour la recherche
class SearchResultsViewState extends BaseViewState {
  final List<domain.TransactionWithBalance> allTransactions;
  final List<domain.TransactionWithBalance> searchResults;
  final List<domain.Category> categories;
  final List<domain.Counterparty> counterparties;
  final SearchFilters filters;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int itemsPerPage;

  const SearchResultsViewState({
    this.allTransactions = const [],
    this.searchResults = const [],
    this.categories = const [],
    this.counterparties = const [],
    this.filters = const SearchFilters(),
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.itemsPerPage = 20,
  });

  SearchResultsViewState copyWith({
    List<domain.TransactionWithBalance>? allTransactions,
    List<domain.TransactionWithBalance>? searchResults,
    List<domain.Category>? categories,
    List<domain.Counterparty>? counterparties,
    SearchFilters? filters,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return SearchResultsViewState(
      allTransactions: allTransactions ?? this.allTransactions,
      searchResults: searchResults ?? this.searchResults,
      categories: categories ?? this.categories,
      counterparties: counterparties ?? this.counterparties,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  SearchResultsViewState loading() {
    return copyWith(isLoading: true, error: null);
  }

  SearchResultsViewState success({
    List<domain.TransactionWithBalance>? allTransactions,
    List<domain.TransactionWithBalance>? searchResults,
    List<domain.Category>? categories,
    List<domain.Counterparty>? counterparties,
  }) {
    return SearchResultsViewState(
      allTransactions: allTransactions ?? this.allTransactions,
      searchResults: searchResults ?? this.searchResults,
      categories: categories ?? this.categories,
      counterparties: counterparties ?? this.counterparties,
      filters: filters,
      isLoading: false,
      error: null,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
    );
  }

  SearchResultsViewState failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }

  bool get hasError => error != null;
  bool get hasResults => searchResults.isNotEmpty;
  bool get hasFilters => filters.hasActiveFilters;

  int get totalPages => (searchResults.length / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;

  List<domain.TransactionWithBalance> get paginatedResults {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, searchResults.length);

    if (startIndex >= searchResults.length) return [];

    return searchResults.sublist(startIndex, endIndex);
  }

  @override
  String toString() =>
      'SearchViewState(allTransactions: ${allTransactions.length}, searchResults: ${searchResults.length}, filters: $filters, isLoading: $isLoading, error: $error)';
}

/// ViewModel pour la recherche
class SearchResultsViewModel extends BaseViewModel<SearchResultsViewState>
    with
        ListViewModelMixin<
          SearchResultsViewState,
          domain.TransactionWithBalance
        >,
        PaginationViewModelMixin<
          SearchResultsViewState,
          domain.TransactionWithBalance
        > {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final CounterpartyRepository _counterpartyRepository;

  SearchResultsViewModel(
    this._transactionRepository,
    this._categoryRepository,
    this._counterpartyRepository,
  ) : super(const SearchResultsViewState()) {
    _init();
  }

  /// Initialise le ViewModel
  Future<void> _init() async {
    await _loadMetadata();
  }

  /// Charge les métadonnées (catégories et contreparties)
  Future<void> _loadMetadata() async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final categories = await _categoryRepository.getAllCategories();
      final counterparties = await _counterpartyRepository
          .getAllCounterparties();

      state = state.success(
        categories: categories,
        counterparties: counterparties,
      );
    });
  }

  /// Initialise la recherche pour un compte
  Future<void> initializeSearch(int accountId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final transactions = await _transactionRepository
          .getTransactionsWithBalance(accountId);

      state = state.success(
        allTransactions: transactions,
        searchResults: transactions,
      );
    });
  }

  /// Recherche par mots-clés
  Future<void> searchByKeyword(String keyword) async {
    final newFilters = state.filters.copyWith(
      keyword: keyword,
      activeType: SearchType.keyword,
    );

    await _updateFiltersAndSearch(newFilters);
  }

  /// Recherche par montant
  Future<void> searchByAmount(double? minAmount, double? maxAmount) async {
    final newFilters = state.filters.copyWith(
      minAmount: minAmount,
      maxAmount: maxAmount,
      activeType: SearchType.amount,
    );

    await _updateFiltersAndSearch(newFilters);
  }

  /// Recherche par catégorie
  Future<void> searchByCategory(int? categoryId) async {
    final newFilters = state.filters.copyWith(
      categoryId: categoryId,
      activeType: SearchType.category,
    );

    await _updateFiltersAndSearch(newFilters);
  }

  /// Recherche par contrepartie
  Future<void> searchByCounterparty(int? counterpartyId) async {
    final newFilters = state.filters.copyWith(
      counterpartyId: counterpartyId,
      activeType: SearchType.counterparty,
    );

    await _updateFiltersAndSearch(newFilters);
  }

  /// Recherche par période
  Future<void> searchByDateRange(DateTime? startDate, DateTime? endDate) async {
    final newFilters = state.filters.copyWith(
      startDate: startDate,
      endDate: endDate,
      activeType: SearchType.date,
    );

    await _updateFiltersAndSearch(newFilters);
  }

  /// Combine plusieurs filtres
  Future<void> searchWithFilters(SearchFilters filters) async {
    await _updateFiltersAndSearch(filters);
  }

  /// Met à jour les filtres et effectue la recherche
  Future<void> _updateFiltersAndSearch(SearchFilters newFilters) async {
    state = state.copyWith(filters: newFilters, currentPage: 0);
    await _performSearch();
  }

  /// Effectue la recherche avec les filtres actuels
  Future<void> _performSearch() async {
    var results = List<domain.TransactionWithBalance>.from(
      state.allTransactions,
    );

    // Filtre par mots-clés
    if (state.filters.keyword.isNotEmpty) {
      results = results
          .where((tx) => tx.matchesKeyword(state.filters.keyword))
          .toList();
    }

    // Filtre par montant
    if (state.filters.minAmount != null || state.filters.maxAmount != null) {
      results = results
          .where(
            (tx) => tx.isInAmountRange(
              state.filters.minAmount,
              state.filters.maxAmount,
            ),
          )
          .toList();
    }

    // Filtre par catégorie
    if (state.filters.categoryId != null) {
      results = results
          .where(
            (tx) =>
                tx.transaction.categoryIds.contains(state.filters.categoryId),
          )
          .toList();
    }

    // Filtre par contrepartie
    if (state.filters.counterpartyId != null) {
      results = results
          .where(
            (tx) =>
                tx.transaction.counterpartyId == state.filters.counterpartyId,
          )
          .toList();
    }

    // Filtre par période
    if (state.filters.startDate != null || state.filters.endDate != null) {
      results = results.where((tx) {
        final date = tx.transaction.date;
        if (state.filters.startDate != null &&
            date.isBefore(state.filters.startDate!)) {
          return false;
        }
        if (state.filters.endDate != null &&
            date.isAfter(state.filters.endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    state = state.copyWith(searchResults: results);
  }

  /// Efface tous les filtres
  Future<void> clearAllFilters() async {
    await _updateFiltersAndSearch(const SearchFilters());
  }

  /// Efface un filtre spécifique
  Future<void> clearFilter(SearchType type) async {
    final newFilters = state.filters.clearFilter(type);
    await _updateFiltersAndSearch(newFilters);
  }

  /// Change de page
  void changePage(int newPage) {
    if (newPage >= 0 && newPage < state.totalPages) {
      state = state.copyWith(currentPage: newPage);
    }
  }

  /// Page suivante
  @override
  void nextPage() {
    if (state.hasNextPage) {
      changePage(state.currentPage + 1);
    }
  }

  /// Page précédente
  @override
  void previousPage() {
    if (state.hasPreviousPage) {
      changePage(state.currentPage - 1);
    }
  }

  /// Change le nombre d'éléments par page
  @override
  void setItemsPerPage(int itemsPerPage) {
    state = state.copyWith(itemsPerPage: itemsPerPage, currentPage: 0);
  }

  /// Obtient une catégorie par ID
  domain.Category? getCategoryById(int id) {
    try {
      return state.categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient une contrepartie par ID
  domain.Counterparty? getCounterpartyById(int id) {
    try {
      return state.counterparties.firstWhere(
        (counterparty) => counterparty.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtient les suggestions de recherche
  List<String> getSearchSuggestions(String query) {
    final suggestions = <String>[];

    if (query.isEmpty) return suggestions;

    final lowerQuery = query.toLowerCase();

    // Suggestions à partir des titres de transactions
    for (final tx in state.allTransactions) {
      final title = tx.displayTitle.toLowerCase();
      if (title.contains(lowerQuery) &&
          !suggestions.contains(tx.displayTitle)) {
        suggestions.add(tx.displayTitle);
      }
    }

    // Suggestions à partir des contreparties
    for (final counterparty in state.counterparties) {
      final name = counterparty.name.toLowerCase();
      if (name.contains(lowerQuery) &&
          !suggestions.contains(counterparty.name)) {
        suggestions.add(counterparty.name);
      }
    }

    // Suggestions à partir des catégories
    for (final category in state.categories) {
      final label = category.label.toLowerCase();
      if (label.contains(lowerQuery) && !suggestions.contains(category.label)) {
        suggestions.add(category.label);
      }
    }

    return suggestions.take(10).toList();
  }

  /// Obtient les statistiques de recherche
  Map<String, dynamic> getSearchStats() {
    final incomeTransactions = state.searchResults
        .where((tx) => tx.isIncome)
        .toList();
    final expenseTransactions = state.searchResults
        .where((tx) => tx.isExpense)
        .toList();

    return {
      'totalTransactions': state.searchResults.length,
      'incomeTransactions': incomeTransactions.length,
      'expenseTransactions': expenseTransactions.length,
      'totalIncome': incomeTransactions.fold(
        0.0,
        (sum, tx) => sum + tx.transaction.amount,
      ),
      'totalExpenses': expenseTransactions.fold(
        0.0,
        (sum, tx) => sum + tx.transaction.amount,
      ),
      'averageAmount': state.searchResults.isEmpty
          ? 0.0
          : state.searchResults.fold(
                  0.0,
                  (sum, tx) => sum + tx.transaction.amount,
                ) /
                state.searchResults.length,
      'activeFilters': state.filters.activeFiltersCount,
    };
  }

  @override
  void resetToInitialState() {
    state = const SearchResultsViewState();
    _init();
  }
}
