import 'dart:async';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';
import 'package:bankapp/data/models/models.dart';

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

  // Cache des données enrichies (calculées)
  final Map<int, List<TransactionWithBalance>> _transactionsWithBalance = {};
  final Map<int, AccountSummary> _accountSummaries = {};

  // Streams pour la réactivité
  final StreamController<List<Account>> _accountsController = StreamController<List<Account>>.broadcast();
  final StreamController<List<Transaction>> _transactionsController = StreamController<List<Transaction>>.broadcast();
  final StreamController<List<Category>> _categoriesController = StreamController<List<Category>>.broadcast();
  final StreamController<List<Counterparty>> _counterpartiesController = StreamController<List<Counterparty>>.broadcast();

  // Flags d'initialisation
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Initialise le cache avec toutes les données
  Future<void> initialize({
    required List<AccountModel> accounts,
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<CounterpartyModel> counterparties,
  }) async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    
    try {
      // Charger les données de base
      await _loadAccounts(accounts);
      await _loadTransactions(transactions);
      await _loadCategories(categories);
      await _loadCounterparties(counterparties);
      
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
  Future<void> _loadCounterparties(List<CounterpartyModel> counterparties) async {
    _counterparties.clear();
    for (final counterparty in counterparties) {
      _counterparties[counterparty.id] = counterparty;
    }
  }

  /// Calcule toutes les transactions avec solde (optimisé O(n))
  Future<void> _calculateAllTransactionsWithBalance() async {
    _transactionsWithBalance.clear();
    
    // Grouper les transactions par compte
    final Map<int, List<TransactionModel>> transactionsByAccount = {};
    for (final transaction in _transactions.values) {
      transactionsByAccount.putIfAbsent(transaction.accountId, () => []).add(transaction);
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
        // Calculer le nouveau solde
        final signedAmount = transaction.type == TransactionType.income 
            ? transaction.amount 
            : -transaction.amount;
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
      final transactionsWithBalance = _transactionsWithBalance[account.id] ?? [];
      
      if (transactionsWithBalance.isEmpty) {
        _accountSummaries[account.id] = AccountSummary(
          account: account.toEntity(),
          currentBalance: AccountBalance(
            balance: Money(amount: account.initialBalance, currency: account.currency),
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
      
      // Prendre les 10 dernières transactions
      final recentTransactions = transactionsWithBalance.reversed.take(10).toList();
      
      // Solde actuel (dernière transaction)
      final currentBalance = transactionsWithBalance.last.balanceAfter;
      
      // Date de la dernière transaction
      final lastTransactionDate = transactionsWithBalance.last.transaction.date;
      
      _accountSummaries[account.id] = AccountSummary(
        account: account.toEntity(),
        currentBalance: currentBalance,
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
    _transactionsController.add(_transactions.values.map((t) => t.toEntity()).toList());
    _categoriesController.add(_categories.values.map((c) => c.toEntity()).toList());
    _counterpartiesController.add(_counterparties.values.map((c) => c.toEntity()).toList());
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

  // === STREAMS ===

  /// Stream des comptes
  Stream<List<Account>> get accountsStream => _accountsController.stream;

  /// Stream des transactions
  Stream<List<Transaction>> get transactionsStream => _transactionsController.stream;

  /// Stream des catégories
  Stream<List<Category>> get categoriesStream => _categoriesController.stream;

  /// Stream des contreparties
  Stream<List<Counterparty>> get counterpartiesStream => _counterpartiesController.stream;

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

  /// Nettoie le cache
  void dispose() {
    _accounts.clear();
    _transactions.clear();
    _categories.clear();
    _counterparties.clear();
    _transactionsWithBalance.clear();
    _accountSummaries.clear();
    
    _accountsController.close();
    _transactionsController.close();
    _categoriesController.close();
    _counterpartiesController.close();
    
    _isInitialized = false;
    _isLoading = false;
  }
}