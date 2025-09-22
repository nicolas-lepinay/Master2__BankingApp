import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/domain/value_objects/date_range.dart';
import 'package:bankapp/presentation/viewmodels/base/base_list_view_model.dart';
import 'dart:async';

/// État pour le TransactionListViewModel - spécialisé pour l'affichage de listes de transactions
class TransactionListViewState extends BaseListViewState<domain.TransactionWithBalance> {
  /// ID du compte sélectionné pour le filtrage
  final int? selectedAccountId;
  
  /// Filtres spécifiques aux transactions
  final double? minAmount;
  final double? maxAmount;
  final int? selectedCategoryId;
  final int? selectedCounterpartyId;

  const TransactionListViewState({
    super.items,
    super.filteredItems,
    super.searchQuery,
    super.currentPage,
    super.itemsPerPage,
    super.isLoading,
    super.error,
    super.dateFilter,
    this.selectedAccountId,
    this.minAmount,
    this.maxAmount,
    this.selectedCategoryId,
    this.selectedCounterpartyId,
  });

  TransactionListViewState copyWith({
    List<domain.TransactionWithBalance>? items,
    List<domain.TransactionWithBalance>? filteredItems,
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
    bool? isLoading,
    String? error,
    DateRange? dateFilter,
    int? selectedAccountId,
    double? minAmount,
    double? maxAmount,
    int? selectedCategoryId,
    int? selectedCounterpartyId,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearCategoryId = false,
    bool clearCounterpartyId = false,
    bool clearDateFilter = false,
  }) {
    return TransactionListViewState(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      selectedCategoryId: clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedCounterpartyId: clearCounterpartyId ? null : (selectedCounterpartyId ?? this.selectedCounterpartyId),
    );
  }

  // États dérivés spécifiques aux transactions
  bool get hasAmountFilter => minAmount != null || maxAmount != null;
  bool get hasCategoryFilter => selectedCategoryId != null;
  bool get hasCounterpartyFilter => selectedCounterpartyId != null;
  
  @override
  bool get isFiltered => 
      super.isFiltered || 
      hasAmountFilter || 
      hasCategoryFilter || 
      hasCounterpartyFilter;

  int get activeFiltersCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (dateFilter != null) count++;
    if (hasAmountFilter) count++;
    if (hasCategoryFilter) count++;
    if (hasCounterpartyFilter) count++;
    return count;
  }
}

/// ViewModel pour la gestion des listes de transactions par écran
/// 
/// Ce ViewModel gère l'affichage des transactions dans les écrans de liste,
/// en utilisant le BaseListViewModel pour la pagination et le filtrage,
/// et l'Event Bus pour la réactivité.
class TransactionListViewModel extends BaseListViewModel<TransactionListViewState, domain.TransactionWithBalance> {
  final TransactionRepository _transactionRepository;
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;
  StreamSubscription<AccountEvent>? _accountEventSubscription;

  TransactionListViewModel(this._transactionRepository) : super(const TransactionListViewState()) {
    _subscribeToEvents();
  }

  // ============================================================================
  // GESTION DES ÉVÉNEMENTS EVENT BUS
  // ============================================================================

  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de transactions
    _transactionEventSubscription = eventBus.transactionEvents.listen((event) {
      _handleTransactionEvent(event);
    });

    // Écouter les événements de comptes (changement de sélection, etc.)
    _accountEventSubscription = eventBus.accountEvents.listen((event) {
      _handleAccountEvent(event);
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    switch (event) {
      case TransactionCreatedEvent():
        _handleTransactionCreated(event);
        break;
      case TransactionUpdatedEvent():
        _handleTransactionUpdated(event);
        break;
      case TransactionDeletedEvent():
        _handleTransactionDeleted(event);
        break;
      case TransactionsRefreshedEvent():
        _handleTransactionsRefreshed(event);
        break;
      default:
        // Ignorer les autres types d'événements
        break;
    }
  }

  void _handleAccountEvent(AccountEvent event) {
    switch (event) {
      case AccountSelectedEvent():
        _handleAccountSelected(event);
        break;
      case AccountBalanceUpdatedEvent():
        // Peut nécessiter un rechargement si cela affecte les soldes affichés
        _refreshIfAccountMatches(event.accountId);
        break;
      case CounterpartyLogoDownloadedEvent():
        // Recharger les transactions pour afficher le nouveau logo téléchargé
        _refreshIfAccountMatches(event.accountId);
        break;
      default:
        break;
    }
  }

  void _handleTransactionCreated(TransactionCreatedEvent event) {
    // Si la transaction concerne le compte actuellement affiché, recharger
    if (state.selectedAccountId == event.accountId) {
      refresh();
    }
  }

  void _handleTransactionUpdated(TransactionUpdatedEvent event) {
    // Recharger si la transaction concerne le compte affiché
    if (state.selectedAccountId == event.accountId) {
      refresh();
    }
  }

  void _handleTransactionDeleted(TransactionDeletedEvent event) {
    // Recharger si la transaction concerne le compte affiché
    if (state.selectedAccountId == event.accountId) {
      refresh();
    }
  }

  void _handleTransactionsRefreshed(TransactionsRefreshedEvent event) {
    // Recharger si les transactions concernent le compte affiché
    if (state.selectedAccountId == event.accountId) {
      refresh();
    }
  }

  void _handleAccountSelected(AccountSelectedEvent event) {
    // Charger les transactions du nouveau compte sélectionné
    loadTransactionsForAccount(event.accountId);
  }

  void _refreshIfAccountMatches(int accountId) {
    if (state.selectedAccountId == accountId) {
      refresh();
    }
  }

  // ============================================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================================

  @override
  Future<List<domain.TransactionWithBalance>> loadAllItems() async {
    if (state.selectedAccountId == null) {
      return [];
    }
    return await _transactionRepository.getTransactionsWithBalance(state.selectedAccountId!);
  }

  /// Charge les transactions pour un compte spécifique
  Future<void> loadTransactionsForAccount(int accountId) async {
    final newState = state.copyWith(selectedAccountId: accountId);
    state = newState;
    await refresh();
  }

  /// Charge les transactions autour de la date d'aujourd'hui
  Future<void> loadTransactionsAroundToday(int accountId) async {
    final newState = state.copyWith(selectedAccountId: accountId);
    state = newState;
    
    try {
      state = setLoading(true);
      
      // Pour l'instant, on charge toutes les transactions puis on les filtre
      // Une optimisation future pourrait utiliser une requête de plage de dates
      final transactions = await _transactionRepository.getTransactionsWithBalance(accountId);
      
      state = setItems(transactions);
      // Les filtres sont automatiquement appliqués dans refresh() du BaseListViewModel
      
      // Optionnel : centrer sur la page contenant les transactions d'aujourd'hui
      _scrollToToday();
      
    } catch (error) {
      state = setError(error.toString());
    }
  }

  void _scrollToToday() {
    if (state.filteredItems.isEmpty) return;
    
    final today = DateTime.now();
    final todayTransactionIndex = state.filteredItems.indexWhere((transaction) =>
        transaction.transaction.date.year == today.year &&
        transaction.transaction.date.month == today.month &&
        transaction.transaction.date.day == today.day
    );
    
    if (todayTransactionIndex >= 0) {
      final targetPage = todayTransactionIndex ~/ state.itemsPerPage;
      goToPage(targetPage);
    }
  }

  // ============================================================================
  // FILTRAGE SPÉCIALISÉ POUR TRANSACTIONS
  // ============================================================================

  @override
  List<domain.TransactionWithBalance> applySearchFilter(List<domain.TransactionWithBalance> items, String query) {
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      final transaction = item.transaction;
      final counterparty = item.counterparty;
      
      // Recherche dans le titre, commentaire et nom de la contrepartie
      return (transaction.title?.toLowerCase().contains(lowerQuery) ?? false) ||
             (transaction.comment?.toLowerCase().contains(lowerQuery) ?? false) ||
             (counterparty?.name.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  List<domain.TransactionWithBalance> applyDateFilter(List<domain.TransactionWithBalance> items, DateRange dateRange) {
    return items.where((item) {
      final transactionDate = item.transaction.date;
      return transactionDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
             transactionDate.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<List<domain.TransactionWithBalance>> applyCustomFilters(List<domain.TransactionWithBalance> items) async {
    var filteredItems = items;

    // Filtre par montant
    if (state.minAmount != null || state.maxAmount != null) {
      filteredItems = filteredItems.where((item) {
        final amount = item.transaction.amount.abs();
        final minOk = state.minAmount == null || amount >= state.minAmount!;
        final maxOk = state.maxAmount == null || amount <= state.maxAmount!;
        return minOk && maxOk;
      }).toList();
    }

    // Filtre par catégorie
    if (state.selectedCategoryId != null) {
      filteredItems = filteredItems.where((item) {
        final transaction = item.transaction;
        return transaction.deepestCategoryId == state.selectedCategoryId;
      }).toList();
    }

    // Filtre par contrepartie
    if (state.selectedCounterpartyId != null) {
      filteredItems = filteredItems.where((item) {
        return item.transaction.counterpartyId == state.selectedCounterpartyId;
      }).toList();
    }

    return filteredItems;
  }

  @override
  List<domain.TransactionWithBalance> sortItems(List<domain.TransactionWithBalance> items) {
    // Tri par date décroissante (plus récent en premier)
    final sortedItems = List<domain.TransactionWithBalance>.from(items);
    sortedItems.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    return sortedItems;
  }

  // ============================================================================
  // MÉTHODES DE FILTRAGE SPÉCIFIQUES
  // ============================================================================

  /// Filtre les transactions par plage de montant
  Future<void> filterByAmount(double? minAmount, double? maxAmount) async {
    state = state.copyWith(
      minAmount: minAmount, 
      maxAmount: maxAmount,
      clearMinAmount: minAmount == null,
      clearMaxAmount: maxAmount == null,
    );
    await _reapplyFilters();
  }

  /// Filtre les transactions par catégorie
  Future<void> filterByCategory(int? categoryId) async {
    state = state.copyWith(selectedCategoryId: categoryId);
    await _reapplyFilters();
  }

  /// Filtre les transactions par contrepartie
  Future<void> filterByCounterparty(int? counterpartyId) async {
    state = state.copyWith(selectedCounterpartyId: counterpartyId);
    await _reapplyFilters();
  }

  /// Réapplique tous les filtres en utilisant les méthodes du BaseListViewModel
  Future<void> _reapplyFilters() async {
    var filteredItems = List<domain.TransactionWithBalance>.from(state.items);

    // Filtrage par recherche
    if (state.searchQuery.isNotEmpty) {
      filteredItems = applySearchFilter(filteredItems, state.searchQuery);
    }

    // Filtrage par date
    if (state.dateFilter != null) {
      filteredItems = applyDateFilter(filteredItems, state.dateFilter!);
    }

    // Appliquer filtres personnalisés définis par cette sous-classe
    filteredItems = await applyCustomFilters(filteredItems);

    // Trier les résultats
    filteredItems = sortItems(filteredItems);

    state = setFilteredItems(filteredItems);
  }

  // ============================================================================
  // MÉTHODES D'ÉTAT REQUISES PAR BaseListViewModel
  // ============================================================================

  @override
  TransactionListViewState setLoading(bool isLoading) {
    return state.copyWith(isLoading: isLoading, error: null);
  }

  @override
  TransactionListViewState setError(String error) {
    return state.copyWith(error: error, isLoading: false);
  }

  @override
  TransactionListViewState setItems(List<domain.TransactionWithBalance> items) {
    return state.copyWith(
      items: items,
      filteredItems: items,
      isLoading: false,
      error: null,
    );
  }

  @override
  TransactionListViewState setFilteredItems(List<domain.TransactionWithBalance> filteredItems) {
    return state.copyWith(
      filteredItems: filteredItems,
      currentPage: 0, // Reset pagination
    );
  }

  @override
  TransactionListViewState updateSearchQueryState(String query) {
    return state.copyWith(searchQuery: query);
  }

  @override
  TransactionListViewState updateDateFilterState(DateRange? dateFilter) {
    return state.copyWith(
      dateFilter: dateFilter,
      clearDateFilter: dateFilter == null,
    );
  }

  @override
  TransactionListViewState setCurrentPage(int currentPage) {
    return state.copyWith(currentPage: currentPage);
  }

  @override
  TransactionListViewState setItemsPerPage(int itemsPerPage) {
    return state.copyWith(itemsPerPage: itemsPerPage);
  }

  @override
  TransactionListViewState clearFiltersState() {
    return state.copyWith(
      searchQuery: '',
      clearDateFilter: true,
      clearMinAmount: true,
      clearMaxAmount: true,
      clearCategoryId: true,
      clearCounterpartyId: true,
    );
  }

  // ============================================================================
  // GESTION DU CYCLE DE VIE
  // ============================================================================

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    _accountEventSubscription?.cancel();
    super.dispose();
  }
}