import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';
// Import pour l'invalidation
import 'package:bankapp/presentation/providers/viewmodel_providers.dart'
    show accountSummaryByIdProvider;
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État pour la gestion des transactions
class TransactionViewState extends BaseViewState {
  final List<domain.TransactionWithBalance> transactions;
  final List<domain.TransactionWithBalance> filteredTransactions;
  final int? selectedAccountId;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final int? selectedCategoryId;
  final int? selectedCounterpartyId;
  final DateRange? dateRange;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int itemsPerPage;

  const TransactionViewState({
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.selectedAccountId,
    this.searchQuery = '',
    this.minAmount,
    this.maxAmount,
    this.selectedCategoryId,
    this.selectedCounterpartyId,
    this.dateRange,
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.itemsPerPage = 20,
  });

  TransactionViewState copyWith({
    List<domain.TransactionWithBalance>? transactions,
    List<domain.TransactionWithBalance>? filteredTransactions,
    int? selectedAccountId,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    int? selectedCategoryId,
    int? selectedCounterpartyId,
    DateRange? dateRange,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return TransactionViewState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCounterpartyId:
          selectedCounterpartyId ?? this.selectedCounterpartyId,
      dateRange: dateRange ?? this.dateRange,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  TransactionViewState loading() {
    return copyWith(isLoading: true, error: null);
  }

  TransactionViewState success({
    List<domain.TransactionWithBalance>? transactions,
    List<domain.TransactionWithBalance>? filteredTransactions,
  }) {
    return TransactionViewState(
      transactions: transactions ?? this.transactions,
      filteredTransactions:
          filteredTransactions ?? transactions ?? this.filteredTransactions,
      selectedAccountId: selectedAccountId,
      searchQuery: searchQuery,
      minAmount: minAmount,
      maxAmount: maxAmount,
      selectedCategoryId: selectedCategoryId,
      selectedCounterpartyId: selectedCounterpartyId,
      dateRange: dateRange,
      isLoading: false,
      error: null,
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
    );
  }

  TransactionViewState failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }

  bool get hasError => error != null;
  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasFilteredTransactions => filteredTransactions.isNotEmpty;
  bool get isFiltered =>
      searchQuery.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      selectedCategoryId != null ||
      selectedCounterpartyId != null ||
      dateRange != null;

  int get totalPages => (filteredTransactions.length / itemsPerPage).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;

  List<domain.TransactionWithBalance> get paginatedTransactions {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredTransactions.length,
    );

    if (startIndex >= filteredTransactions.length) return [];

    return filteredTransactions.sublist(startIndex, endIndex);
  }

  @override
  String toString() =>
      'TransactionViewState(transactions: ${transactions.length}, filteredTransactions: ${filteredTransactions.length}, selectedAccountId: $selectedAccountId, searchQuery: "$searchQuery", isLoading: $isLoading, error: $error)';
}

/// ViewModel pour la gestion des transactions
class TransactionViewModel extends BaseViewModel<TransactionViewState>
    with
        ListViewModelMixin<TransactionViewState, domain.TransactionWithBalance>,
        PaginationViewModelMixin<
          TransactionViewState,
          domain.TransactionWithBalance
        > {
  final TransactionRepository _transactionRepository;
  final Ref? _ref;

  TransactionViewModel(this._transactionRepository, [this._ref])
    : super(const TransactionViewState());

  /// Charge les transactions pour un compte
  Future<void> loadTransactions(int accountId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final transactions = await _transactionRepository
          .getTransactionsWithBalance(accountId);

      state = state
          .success(transactions: transactions)
          .copyWith(selectedAccountId: accountId, currentPage: 0);

      // Appliquer les filtres existants
      await _applyFilters();
    });
  }

  /// Crée une nouvelle transaction avec support de conversion de devises
  Future<void> createTransaction({
    required int accountId,
    required domain.TransactionType type,
    required double amount,
    required String currency,
    required DateTime date,
    String? title,
    String? comment,
    int? counterpartyId,
    List<int>? categoryIds,
    domain.TransactionStatus status = domain.TransactionStatus.completed,
    double? amountBeforeConversion,
    String? currencyBeforeConversion,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final newTransaction = domain.Transaction(
        id: 0, // Sera assigné par la base de données
        accountId: accountId,
        counterpartyId: counterpartyId,
        category1Id: categoryIds?.isNotEmpty == true ? categoryIds![0] : null,
        category2Id: categoryIds != null && categoryIds.length > 1
            ? categoryIds[1]
            : null,
        category3Id: categoryIds != null && categoryIds.length > 2
            ? categoryIds[2]
            : null,
        category4Id: categoryIds != null && categoryIds.length > 3
            ? categoryIds[3]
            : null,
        type: type,
        currency: currency,
        amount: amount,
        title: title,
        comment: comment,
        date: date,
        status: status,
        amountBeforeConversion: amountBeforeConversion,
        currencyBeforeConversion: currencyBeforeConversion,
      );

      await _transactionRepository.createTransaction(newTransaction);

      // Invalider les providers d'account summary pour une réactivité automatique
      if (_ref != null) {
        _ref.invalidate(accountSummaryByIdProvider);
      }

      // Recharger les transactions
      await loadTransactions(accountId);
    });
  }

  /// Met à jour une transaction
  Future<void> updateTransaction({
    required int transactionId,
    required int accountId,
    required domain.TransactionType type,
    required double amount,
    required String currency,
    required DateTime date,
    String? title,
    String? comment,
    int? counterpartyId,
    List<int>? categoryIds,
    domain.TransactionStatus status = domain.TransactionStatus.completed,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      // Récupérer la transaction existante
      final existingTransaction = await _transactionRepository
          .getTransactionById(transactionId);
      if (existingTransaction == null) {
        throw Exception('Transaction not found: $transactionId');
      }

      // Utiliser copyWith() pour une mise à jour optimisée
      final updatedTransaction = existingTransaction.copyWith(
        accountId: accountId,
        counterpartyId: counterpartyId,
        category1Id: categoryIds?.isNotEmpty == true ? categoryIds![0] : null,
        category2Id: categoryIds != null && categoryIds.length > 1
            ? categoryIds[1]
            : null,
        category3Id: categoryIds != null && categoryIds.length > 2
            ? categoryIds[2]
            : null,
        category4Id: categoryIds != null && categoryIds.length > 3
            ? categoryIds[3]
            : null,
        type: type,
        currency: currency,
        amount: amount,
        title: title,
        comment: comment,
        date: date,
        status: status,
      );

      await _transactionRepository.updateTransaction(updatedTransaction);

      // Invalider les providers d'account summary pour une réactivité automatique
      if (_ref != null) {
        _ref.invalidate(accountSummaryByIdProvider);
      }

      // Recharger les transactions
      await loadTransactions(accountId);
    });
  }

  /// Supprime une transaction
  Future<void> deleteTransaction(int transactionId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      await _transactionRepository.deleteTransaction(transactionId);

      // Invalider les providers d'account summary pour une réactivité automatique
      if (_ref != null) {
        _ref.invalidate(accountSummaryByIdProvider);
      }

      // Recharger les transactions si un compte est sélectionné
      if (state.selectedAccountId != null) {
        await loadTransactions(state.selectedAccountId!);
      }
    });
  }

  /// Applique une recherche par mots-clés
  Future<void> searchTransactions(String query) async {
    state = state.copyWith(searchQuery: query, currentPage: 0);
    await _applyFilters();
  }

  /// Applique un filtre par montant
  Future<void> filterByAmount(double? minAmount, double? maxAmount) async {
    state = state.copyWith(
      minAmount: minAmount,
      maxAmount: maxAmount,
      currentPage: 0,
    );
    await _applyFilters();
  }

  /// Applique un filtre par catégorie
  Future<void> filterByCategory(int? categoryId) async {
    state = state.copyWith(selectedCategoryId: categoryId, currentPage: 0);
    await _applyFilters();
  }

  /// Applique un filtre par contrepartie
  Future<void> filterByCounterparty(int? counterpartyId) async {
    state = state.copyWith(
      selectedCounterpartyId: counterpartyId,
      currentPage: 0,
    );
    await _applyFilters();
  }

  /// Applique un filtre par période
  Future<void> filterByDateRange(DateRange? dateRange) async {
    state = state.copyWith(dateRange: dateRange, currentPage: 0);
    await _applyFilters();
  }

  /// Efface tous les filtres
  Future<void> clearFilters() async {
    state = state.copyWith(
      searchQuery: '',
      minAmount: null,
      maxAmount: null,
      selectedCategoryId: null,
      selectedCounterpartyId: null,
      dateRange: null,
      currentPage: 0,
    );
    await _applyFilters();
  }

  /// Applique tous les filtres actifs
  Future<void> _applyFilters() async {
    var filteredTransactions = List<domain.TransactionWithBalance>.from(
      state.transactions,
    );

    // Filtre par recherche
    if (state.searchQuery.isNotEmpty) {
      filteredTransactions = filteredTransactions
          .where((tx) => tx.matchesKeyword(state.searchQuery))
          .toList();
    }

    // Filtre par montant
    if (state.minAmount != null || state.maxAmount != null) {
      filteredTransactions = filteredTransactions
          .where((tx) => tx.isInAmountRange(state.minAmount, state.maxAmount))
          .toList();
    }

    // Filtre par catégorie
    if (state.selectedCategoryId != null) {
      filteredTransactions = filteredTransactions
          .where(
            (tx) =>
                tx.transaction.categoryIds.contains(state.selectedCategoryId),
          )
          .toList();
    }

    // Filtre par contrepartie
    if (state.selectedCounterpartyId != null) {
      filteredTransactions = filteredTransactions
          .where(
            (tx) =>
                tx.transaction.counterpartyId == state.selectedCounterpartyId,
          )
          .toList();
    }

    // Filtre par période
    if (state.dateRange != null) {
      filteredTransactions = filteredTransactions
          .where((tx) => state.dateRange!.contains(tx.transaction.date))
          .toList();
    }

    state = state.copyWith(filteredTransactions: filteredTransactions);
  }

  /// Charge les transactions autour d'aujourd'hui
  Future<void> loadTransactionsAroundToday(int accountId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final transactions = await _transactionRepository
          .getTransactionsAroundToday(accountId);

      state = state
          .success(transactions: transactions)
          .copyWith(selectedAccountId: accountId, currentPage: 0);

      await _applyFilters();
    });
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

  /// Rafraîchit les données
  Future<void> refresh() async {
    if (state.selectedAccountId != null) {
      await loadTransactions(state.selectedAccountId!);
    }
  }

  /// Obtient une transaction par ID
  domain.TransactionWithBalance? getTransactionById(int transactionId) {
    try {
      return state.transactions.firstWhere(
        (tx) => tx.transaction.id == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtient les transactions de revenus
  List<domain.TransactionWithBalance> get incomeTransactions =>
      state.filteredTransactions.where((tx) => tx.isIncome).toList();

  /// Obtient les transactions de dépenses
  List<domain.TransactionWithBalance> get expenseTransactions =>
      state.filteredTransactions.where((tx) => tx.isExpense).toList();

  /// Obtient le total des revenus filtrés
  double get filteredIncomeTotal =>
      incomeTransactions.fold(0.0, (sum, tx) => sum + tx.transaction.amount);

  /// Obtient le total des dépenses filtrées
  double get filteredExpenseTotal =>
      expenseTransactions.fold(0.0, (sum, tx) => sum + tx.transaction.amount);

  /// Obtient le montant net filtré
  double get filteredNetAmount => filteredIncomeTotal - filteredExpenseTotal;

  // === MÉTHODES DE CONVERSION DE DEVISES ===
  /// Vérifie si une transaction a été convertie
  ///
  bool isTransactionConverted(domain.TransactionWithBalance transaction) {
    return transaction.transaction.amountBeforeConversion != null &&
        transaction.transaction.currencyBeforeConversion != null;
  }

  /// Obtient le montant original d'une transaction
  double getOriginalAmount(domain.TransactionWithBalance transaction) {
    if (isTransactionConverted(transaction)) {
      // Si la transaction a été convertie, calculer le montant original
      final originalAmount = transaction.transaction.amountBeforeConversion!;
      final accountAmount = transaction.transaction.amount;

      // Si les montants sont différents, utiliser le montant converti
      return originalAmount != accountAmount ? originalAmount : accountAmount;
    }
    return transaction.transaction.amount;
  }

  /// Obtient la devise originale d'une transaction
  String getOriginalCurrency(domain.TransactionWithBalance transaction) {
    return transaction.transaction.currencyBeforeConversion ??
        transaction.transaction.currency;
  }

  /// Obtient toutes les transactions converties
  List<domain.TransactionWithBalance> get convertedTransactions => state
      .filteredTransactions
      .where((tx) => isTransactionConverted(tx))
      .toList();

  /// Obtient le nombre de transactions converties
  int get convertedTransactionsCount => convertedTransactions.length;

  /// Obtient les statistiques de conversion
  Map<String, dynamic> getConversionStats() {
    final converted = convertedTransactions;
    final total = state.filteredTransactions.length;

    final currencyDistribution = <String, int>{};
    for (final tx in converted) {
      final originalCurrency = getOriginalCurrency(tx);
      currencyDistribution[originalCurrency] =
          (currencyDistribution[originalCurrency] ?? 0) + 1;
    }

    return {
      'total': total,
      'converted': converted.length,
      'percentage': total > 0
          ? (converted.length / total * 100).toStringAsFixed(1)
          : '0.0',
      'currencyDistribution': currencyDistribution,
    };
  }

  @override
  void resetToInitialState() {
    state = const TransactionViewState();
  }
}
