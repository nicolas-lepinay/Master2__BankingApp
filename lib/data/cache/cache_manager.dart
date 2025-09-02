import 'dart:async';

import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

/// Gestionnaire de cache centralisé pour toutes les données
/// Résout le problème O(n²) en gardant tout en mémoire
class CacheManager {
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();

  CacheManager._();

  // Cache des données brutes
  final Map<int, AccountModel> _accounts = {};
  final Map<int, TransactionModel> _transactions = {};
  final Map<int, CategoryModel> _categories = {};
  final Map<int, CounterpartyModel> _counterparties = {};
  final Set<int> _followedTransactionIds = {};

  // Cache des données enrichies (calculées)
  final Map<int, List<TransactionWithBalance>> _transactionsWithBalance = {};
  final Map<int, AccountSummary> _accountSummaries = {};
  final List<TransactionWithBalance> _followedTransactionsWithBalance = [];

  // Cache des taux de change
  final Map<String, ExchangeRate> _exchangeRates = {};
  ExchangeRateRepository? _exchangeRateRepository;
  DateTime? _lastExchangeRateUpdate;

  // Streams pour la réactivité
  final StreamController<List<Account>> _accountsController =
      StreamController<List<Account>>.broadcast();
  final StreamController<List<Transaction>> _transactionsController =
      StreamController<List<Transaction>>.broadcast();
  final StreamController<List<Category>> _categoriesController =
      StreamController<List<Category>>.broadcast();
  final StreamController<List<Counterparty>> _counterpartiesController =
      StreamController<List<Counterparty>>.broadcast();
  final StreamController<List<TransactionWithBalance>>
  _followedTransactionsController =
      StreamController<List<TransactionWithBalance>>.broadcast();
  final StreamController<Map<String, ExchangeRate>> _exchangeRatesController =
      StreamController<Map<String, ExchangeRate>>.broadcast();

  // Flags d'initialisation
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Initialise le cache avec toutes les données
  Future<void> initialize({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<CounterpartyModel> counterparties,
    required List<int> followedTransactionIds,
    ExchangeRateRepository? exchangeRateRepository,
  }) async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;

    try {
      // Charger les données de base
      await _loadAccounts(accounts);
      await _loadTransactions(transactions);
      await _loadCategories(categories);
      await _loadCounterparties(counterparties);
      await _loadFollowedTransactionIds(followedTransactionIds);

      // Initialiser le repository des taux de change
      if (exchangeRateRepository != null) {
        _exchangeRateRepository = exchangeRateRepository;
        await _loadExchangeRates();
      }

      // Calculer les données enrichies
      await _calculateAllTransactionsWithBalance();
      await _calculateAllAccountSummaries();

      _isInitialized = true;
      _isLoading = false;

      // Notifier les streams
      _notifyAllStreams();
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }

  /// Charge les comptes dans le cache
  Future<void> _loadAccounts(List<AccountModel> accounts) async {
    _accounts.clear();
    for (final account in accounts) {
      _accounts[account.id] = account;
    }
  }

  /// Charge les transactions dans le cache
  Future<void> _loadTransactions(List<TransactionModel> transactions) async {
    _transactions.clear();
    for (final transaction in transactions) {
      _transactions[transaction.id] = transaction;
    }
  }

  /// Charge les catégories dans le cache
  Future<void> _loadCategories(List<CategoryModel> categories) async {
    _categories.clear();
    for (final category in categories) {
      _categories[category.id] = category;
    }
  }

  /// Charge les contreparties dans le cache
  Future<void> _loadCounterparties(
    List<CounterpartyModel> counterparties,
  ) async {
    _counterparties.clear();
    for (final counterparty in counterparties) {
      _counterparties[counterparty.id] = counterparty;
    }
  }

  /// Charge les IDs des transactions suivies dans le cache
  Future<void> _loadFollowedTransactionIds(
    List<int> followedTransactionIds,
  ) async {
    _followedTransactionIds.clear();
    _followedTransactionIds.addAll(followedTransactionIds);
  }

  /// Calcule toutes les transactions avec solde (optimisé O(n))
  Future<void> _calculateAllTransactionsWithBalance() async {
    _transactionsWithBalance.clear();

    // Grouper les transactions par compte
    final Map<int, List<TransactionModel>> transactionsByAccount = {};
    for (final transaction in _transactions.values) {
      transactionsByAccount
          .putIfAbsent(transaction.accountId, () => [])
          .add(transaction);
    }

    // Calculer le solde pour chaque compte
    for (final entry in transactionsByAccount.entries) {
      final accountId = entry.key;
      final transactions = entry.value;

      // Trier par date
      transactions.sort((a, b) => a.date.compareTo(b.date));

      final account = _accounts[accountId];
      if (account == null) continue;

      final transactionsWithBalance = <TransactionWithBalance>[];
      double currentBalance = account.initialBalance;

      for (final transaction in transactions) {
        // NOUVELLE SÉMANTIQUE : amount est toujours dans la devise du compte
        final effectiveAmount = transaction.amount;
        final signedAmount = transaction.type == TransactionType.income
            ? effectiveAmount
            : -effectiveAmount;
        currentBalance += signedAmount;

        // Créer l'objet enrichi
        final transactionWithBalance = TransactionWithBalance(
          transaction: transaction.toEntity(),
          account: account.toEntity(),
          balanceAfter: AccountBalance(
            balance: Money(amount: currentBalance, currency: account.currency),
            calculatedAt: DateTime.now(),
          ),
          counterparty: transaction.counterpartyId != null
              ? _counterparties[transaction.counterpartyId!]?.toEntity()
              : null,
          categories: _getTransactionCategories(transaction),
        );

        transactionsWithBalance.add(transactionWithBalance);
      }

      _transactionsWithBalance[accountId] = transactionsWithBalance;
    }

    // Calculer les transactions suivies avec balance
    await _calculateFollowedTransactionsWithBalance();
  }

  /// Calcule les transactions suivies avec leurs soldes
  Future<void> _calculateFollowedTransactionsWithBalance() async {
    _followedTransactionsWithBalance.clear();

    for (final transactionId in _followedTransactionIds) {
      // Rechercher la transaction dans tous les comptes
      TransactionWithBalance? foundTransaction;

      for (final transactions in _transactionsWithBalance.values) {
        try {
          foundTransaction = transactions.firstWhere(
            (txWithBalance) => txWithBalance.transaction.id == transactionId,
          );
          break;
        } catch (e) {
          // Continue à chercher dans le compte suivant
        }
      }

      if (foundTransaction != null) {
        _followedTransactionsWithBalance.add(foundTransaction);
      }
    }

    // Trier par date (plus récentes en premier)
    _followedTransactionsWithBalance.sort(
      (a, b) => b.transaction.date.compareTo(a.transaction.date),
    );
  }

  /// Obtient les catégories d'une transaction
  List<Category> _getTransactionCategories(TransactionModel transaction) {
    final categories = <Category>[];

    if (transaction.category1Id != null) {
      final category = _categories[transaction.category1Id!];
      if (category != null) categories.add(category.toEntity());
    }

    if (transaction.category2Id != null) {
      final category = _categories[transaction.category2Id!];
      if (category != null) categories.add(category.toEntity());
    }

    if (transaction.category3Id != null) {
      final category = _categories[transaction.category3Id!];
      if (category != null) categories.add(category.toEntity());
    }

    if (transaction.category4Id != null) {
      final category = _categories[transaction.category4Id!];
      if (category != null) categories.add(category.toEntity());
    }

    return categories;
  }

  /// Calcule les résumés de tous les comptes
  Future<void> _calculateAllAccountSummaries() async {
    _accountSummaries.clear();

    for (final account in _accounts.values) {
      final transactionsWithBalance =
          _transactionsWithBalance[account.id] ?? [];

      if (transactionsWithBalance.isEmpty) {
        _accountSummaries[account.id] = AccountSummary(
          account: account.toEntity(),
          currentBalance: AccountBalance(
            balance: Money(
              amount: account.initialBalance,
              currency: account.currency,
            ),
            calculatedAt: DateTime.now(),
          ),
          confirmedBalance: AccountBalance(
            balance: Money(
              amount: account.initialBalance,
              currency: account.currency,
            ),
            calculatedAt: DateTime.now(),
          ),
          recentTransactions: [],
          totalTransactionsCount: 0,
          totalIncome: Money(amount: 0, currency: account.currency),
          totalExpenses: Money(amount: 0, currency: account.currency),
          lastTransactionDate: account.creationDate,
        );
        continue;
      }

      // Calculer les totaux
      double totalIncome = 0;
      double totalExpenses = 0;

      for (final txWithBalance in transactionsWithBalance) {
        if (txWithBalance.isIncome) {
          totalIncome += txWithBalance.transaction.amount;
        } else {
          totalExpenses += txWithBalance.transaction.amount;
        }
      }

      // Calculer le solde confirmé (uniquement transactions confirmées)
      final confirmedTransactions = transactionsWithBalance
          .where((txWithBalance) => txWithBalance.transaction.isCompleted)
          .toList();

      AccountBalance confirmedBalance;
      if (confirmedTransactions.isEmpty) {
        // Pas de transactions confirmées, utiliser le solde initial
        confirmedBalance = AccountBalance(
          balance: Money(
            amount: account.initialBalance,
            currency: account.currency,
          ),
          calculatedAt: DateTime.now(),
        );
      } else {
        // Utiliser le solde après la dernière transaction confirmée
        confirmedBalance = confirmedTransactions.last.balanceAfter;
      }

      // Prendre les 10 dernières transactions
      final recentTransactions = transactionsWithBalance.reversed
          .take(10)
          .toList();

      // Solde actuel (dernière transaction)
      final currentBalance = transactionsWithBalance.last.balanceAfter;

      // Date de la dernière transaction
      final lastTransactionDate = transactionsWithBalance.last.transaction.date;

      _accountSummaries[account.id] = AccountSummary(
        account: account.toEntity(),
        currentBalance: currentBalance,
        confirmedBalance: confirmedBalance,
        recentTransactions: recentTransactions,
        totalTransactionsCount: transactionsWithBalance.length,
        totalIncome: Money(amount: totalIncome, currency: account.currency),
        totalExpenses: Money(amount: totalExpenses, currency: account.currency),
        lastTransactionDate: lastTransactionDate,
      );
    }
  }

  /// Notifie tous les streams
  void _notifyAllStreams() {
    _accountsController.add(_accounts.values.map((a) => a.toEntity()).toList());
    _transactionsController.add(
      _transactions.values.map((t) => t.toEntity()).toList(),
    );
    _categoriesController.add(
      _categories.values.map((c) => c.toEntity()).toList(),
    );
    _counterpartiesController.add(
      _counterparties.values.map((c) => c.toEntity()).toList(),
    );
    _followedTransactionsController.add(_followedTransactionsWithBalance);
    _exchangeRatesController.add(Map.from(_exchangeRates));
  }

  // === GETTERS PUBLICS ===

  /// Vérifie si le cache est initialisé
  bool get isInitialized => _isInitialized;

  /// Vérifie si le cache est en cours de chargement
  bool get isLoading => _isLoading;

  /// Obtient tous les comptes
  List<Account> getAllAccounts() {
    return _accounts.values.map((a) => a.toEntity()).toList();
  }

  /// Obtient un compte par ID
  Account? getAccountById(int id) {
    return _accounts[id]?.toEntity();
  }

  /// Obtient toutes les transactions
  List<Transaction> getAllTransactions() {
    return _transactions.values.map((t) => t.toEntity()).toList();
  }

  /// Obtient les transactions d'un compte
  List<Transaction> getTransactionsByAccountId(int accountId) {
    return _transactions.values
        .where((t) => t.accountId == accountId)
        .map((t) => t.toEntity())
        .toList();
  }

  /// Obtient les transactions avec solde d'un compte
  List<TransactionWithBalance> getTransactionsWithBalance(int accountId) {
    return _transactionsWithBalance[accountId] ?? [];
  }

  /// Obtient le résumé d'un compte
  AccountSummary? getAccountSummary(int accountId) {
    return _accountSummaries[accountId];
  }

  /// Obtient toutes les catégories
  List<Category> getAllCategories() {
    return _categories.values.map((c) => c.toEntity()).toList();
  }

  /// Obtient toutes les contreparties
  List<Counterparty> getAllCounterparties() {
    return _counterparties.values.map((c) => c.toEntity()).toList();
  }

  /// Obtient les transactions suivies avec balance
  List<TransactionWithBalance> getFollowedTransactionsWithBalance() {
    return List.from(_followedTransactionsWithBalance);
  }

  /// Obtient les IDs des transactions suivies
  List<int> getFollowedTransactionIds() {
    return List.from(_followedTransactionIds);
  }

  /// Vérifie si une transaction est suivie
  bool isTransactionFollowed(int transactionId) {
    return _followedTransactionIds.contains(transactionId);
  }

  // === STREAMS ===

  /// Stream des comptes
  Stream<List<Account>> get accountsStream => _accountsController.stream;

  /// Stream des transactions
  Stream<List<Transaction>> get transactionsStream =>
      _transactionsController.stream;

  /// Stream des catégories
  Stream<List<Category>> get categoriesStream => _categoriesController.stream;

  /// Stream des contreparties
  Stream<List<Counterparty>> get counterpartiesStream =>
      _counterpartiesController.stream;

  /// Stream des transactions suivies
  Stream<List<TransactionWithBalance>> get followedTransactionsStream =>
      _followedTransactionsController.stream;

  // === MUTATIONS ===

  /// Ajoute un compte
  Future<void> addAccount(AccountModel account) async {
    _accounts[account.id] = account;
    await _calculateAllAccountSummaries();
    _accountsController.add(getAllAccounts());
  }

  /// Ajoute une transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions[transaction.id] = transaction;
    await _calculateAllTransactionsWithBalance();
    await _calculateAllAccountSummaries();
    _transactionsController.add(getAllTransactions());
    _accountsController.add(getAllAccounts());
  }

  /// Supprime une transaction
  Future<void> removeTransaction(int transactionId) async {
    _transactions.remove(transactionId);
    await _calculateAllTransactionsWithBalance();
    await _calculateAllAccountSummaries();
    _transactionsController.add(getAllTransactions());
    _accountsController.add(getAllAccounts());
  }

  /// Invalide et recalcule tout
  Future<void> invalidateAll() async {
    if (!_isInitialized) return;

    await _calculateAllTransactionsWithBalance();
    await _calculateAllAccountSummaries();
    _notifyAllStreams();
  }

  /// Suit une transaction
  Future<void> followTransaction(int transactionId) async {
    if (!_followedTransactionIds.contains(transactionId)) {
      _followedTransactionIds.add(transactionId);
      await _calculateFollowedTransactionsWithBalance();
      _followedTransactionsController.add(_followedTransactionsWithBalance);
    }
  }

  /// Arrête le suivi d'une transaction
  Future<void> unfollowTransaction(int transactionId) async {
    if (_followedTransactionIds.remove(transactionId)) {
      await _calculateFollowedTransactionsWithBalance();
      _followedTransactionsController.add(_followedTransactionsWithBalance);
    }
  }

  // === GESTION DES TAUX DE CHANGE ===

  /// Charge les taux de change depuis le repository
  Future<void> _loadExchangeRates() async {
    if (_exchangeRateRepository == null) return;

    try {
      final validRates = await _exchangeRateRepository!.getAllValidRates();
      _exchangeRates.clear();

      for (final rate in validRates) {
        final key = '${rate.fromCurrency}_${rate.toCurrency}';
        _exchangeRates[key] = rate;
      }

      _lastExchangeRateUpdate = DateTime.now();
    } catch (e) {
      // Ignorer les erreurs de chargement des taux - pas critique
    }
  }

  /// Convertit un montant d'une devise à une autre
  Future<double?> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return amount;

    // Essayer d'abord avec le cache
    final cacheKey = '${fromCurrency}_$toCurrency';
    final cachedRate = _exchangeRates[cacheKey];

    if (cachedRate != null && cachedRate.isValid) {
      return cachedRate.convertAmount(amount);
    }

    // Si pas en cache ou expiré, essayer via le repository
    if (_exchangeRateRepository != null) {
      try {
        final convertedAmount = await _exchangeRateRepository!.convertAmount(
          amount,
          fromCurrency,
          toCurrency,
        );

        // Mettre à jour le cache avec le nouveau taux
        final rate = await _exchangeRateRepository!.getExchangeRate(
          fromCurrency,
          toCurrency,
        );
        if (rate != null) {
          _exchangeRates[cacheKey] = rate;
          _exchangeRatesController.add(Map.from(_exchangeRates));
        }

        return convertedAmount;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Obtient un taux de change
  Future<ExchangeRate?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) {
      return ExchangeRate.withDefaultExpiration(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: 1.0,
      );
    }

    final cacheKey = '${fromCurrency}_$toCurrency';
    final cachedRate = _exchangeRates[cacheKey];

    if (cachedRate != null && cachedRate.isValid) {
      return cachedRate;
    }

    if (_exchangeRateRepository != null) {
      try {
        final rate = await _exchangeRateRepository!.getExchangeRate(
          fromCurrency,
          toCurrency,
        );
        if (rate != null) {
          _exchangeRates[cacheKey] = rate;
          _exchangeRatesController.add(Map.from(_exchangeRates));
        }
        return rate;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Met à jour les taux de change pour une devise de base
  Future<void> updateExchangeRates(String baseCurrency) async {
    if (_exchangeRateRepository == null) return;

    try {
      await _exchangeRateRepository!.updateExchangeRates(baseCurrency);
      await _loadExchangeRates();
      _exchangeRatesController.add(Map.from(_exchangeRates));
    } catch (e) {
      // Ignorer les erreurs de mise à jour
    }
  }

  /// Vérifie si un taux de change est disponible
  Future<bool> isExchangeRateAvailable(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return true;

    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return rate != null;
  }

  /// Obtient tous les taux de change en cache
  Map<String, ExchangeRate> getAllExchangeRates() {
    return Map.from(_exchangeRates);
  }

  /// Obtient la date de dernière mise à jour des taux
  DateTime? get lastExchangeRateUpdate => _lastExchangeRateUpdate;

  /// Stream des taux de change
  Stream<Map<String, ExchangeRate>> get exchangeRatesStream =>
      _exchangeRatesController.stream;

  /// Nettoie le cache
  void dispose() {
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _counterparties.clear();
    _followedTransactionIds.clear();
    _transactionsWithBalance.clear();
    _accountSummaries.clear();
    _followedTransactionsWithBalance.clear();
    _exchangeRates.clear();

    _accountsController.close();
    _transactionsController.close();
    _categoriesController.close();
    _counterpartiesController.close();
    _followedTransactionsController.close();
    _exchangeRatesController.close();

    _isInitialized = false;
    _isLoading = false;
  }
}
