import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/repositories/repositories.dart';
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;

// === PROVIDERS DE BASE ===

/// Provider pour la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider pour le gestionnaire de cache
final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager.instance;
});

// === PROVIDERS DATASOURCES ===

/// Provider pour AccountLocalDataSource
final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountLocalDataSourceImpl(database);
});

/// Provider pour TransactionLocalDataSource
final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return TransactionLocalDataSourceImpl(database);
});

/// Provider pour CategoryLocalDataSource
final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return CategoryLocalDataSourceImpl(database);
});

/// Provider pour CounterpartyLocalDataSource
final counterpartyLocalDataSourceProvider = Provider<CounterpartyLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return CounterpartyLocalDataSourceImpl(database);
});

// === PROVIDERS REPOSITORIES ===

/// Provider pour AccountRepository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final localDataSource = ref.watch(accountLocalDataSourceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return AccountRepositoryImpl(localDataSource, cacheManager);
});

/// Provider pour TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return TransactionRepositoryImpl(localDataSource, cacheManager);
});

/// Provider pour CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final localDataSource = ref.watch(categoryLocalDataSourceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return CategoryRepositoryImpl(localDataSource, cacheManager);
});

/// Provider pour CounterpartyRepository
final counterpartyRepositoryProvider = Provider<CounterpartyRepository>((ref) {
  final localDataSource = ref.watch(counterpartyLocalDataSourceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return CounterpartyRepositoryImpl(localDataSource, cacheManager);
});

// === PROVIDERS D'INITIALISATION ===

/// Provider pour l'initialisation du cache
final cacheInitializationProvider = FutureProvider<void>((ref) async {
  final cacheManager = ref.watch(cacheManagerProvider);
  
  // Si déjà initialisé, ne rien faire
  if (cacheManager.isInitialized) {
    return;
  }
  
  // Charger toutes les données depuis les datasources
  final accountDataSource = ref.watch(accountLocalDataSourceProvider);
  final transactionDataSource = ref.watch(transactionLocalDataSourceProvider);
  final categoryDataSource = ref.watch(categoryLocalDataSourceProvider);
  final counterpartyDataSource = ref.watch(counterpartyLocalDataSourceProvider);
  
  // Charger en parallèle pour les performances
  final accounts = await accountDataSource.getAllAccounts();
  final transactions = await transactionDataSource.getAllTransactions();
  final categories = await categoryDataSource.getAllCategories();
  final counterparties = await counterpartyDataSource.getAllCounterparties();
  
  // Initialiser le cache
  await cacheManager.initialize(
    accounts: accounts,
    transactions: transactions,
    categories: categories,
    counterparties: counterparties,
  );
});

// === PROVIDERS MÉTIER ===

/// Provider pour la liste des comptes
final accountsProvider = StreamProvider<List<domain.Account>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAllAccounts();
});

/// Provider pour un compte spécifique
final accountProvider = StreamProvider.family<domain.Account?, int>((ref, accountId) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccountById(accountId);
});

/// Provider pour le résumé d'un compte
final accountSummaryProvider = StreamProvider.family<domain.AccountSummary, int>((ref, accountId) {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccountSummary(accountId);
});

/// Provider pour les transactions d'un compte
final transactionsProvider = StreamProvider.family<List<domain.Transaction>, int>((ref, accountId) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactionsByAccountId(accountId);
});

/// Provider pour les transactions avec solde d'un compte
final transactionsWithBalanceProvider = StreamProvider.family<List<domain.TransactionWithBalance>, int>((ref, accountId) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactionsWithBalance(accountId);
});

/// Provider pour les catégories
final categoriesProvider = StreamProvider<List<domain.Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchAllCategories();
});

/// Provider pour les contreparties
final counterpartiesProvider = StreamProvider<List<domain.Counterparty>>((ref) {
  final repository = ref.watch(counterpartyRepositoryProvider);
  return repository.watchAllCounterparties();
});

// === PROVIDERS D'ACTIONS ===

/// Provider pour les actions sur les comptes
final accountActionsProvider = Provider<AccountActions>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountActions(repository);
});

/// Provider pour les actions sur les transactions
final transactionActionsProvider = Provider<TransactionActions>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionActions(repository);
});

/// Provider pour les actions sur les catégories
final categoryActionsProvider = Provider<CategoryActions>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryActions(repository);
});

/// Provider pour les actions sur les contreparties
final counterpartyActionsProvider = Provider<CounterpartyActions>((ref) {
  final repository = ref.watch(counterpartyRepositoryProvider);
  return CounterpartyActions(repository);
});

// === CLASSES D'ACTIONS ===

class AccountActions {
  final AccountRepository _repository;
  
  AccountActions(this._repository);
  
  Future<domain.Account> createAccount(domain.Account account) => _repository.createAccount(account);
  Future<domain.Account> updateAccount(domain.Account account) => _repository.updateAccount(account);
  Future<void> deleteAccount(int id) => _repository.deleteAccount(id);
}

class TransactionActions {
  final TransactionRepository _repository;
  
  TransactionActions(this._repository);
  
  Future<domain.Transaction> createTransaction(domain.Transaction transaction) => _repository.createTransaction(transaction);
  Future<domain.Transaction> updateTransaction(domain.Transaction transaction) => _repository.updateTransaction(transaction);
  Future<void> deleteTransaction(int id) => _repository.deleteTransaction(id);
  
  Future<List<domain.TransactionWithBalance>> searchByKeyword(int accountId, String keyword) => 
      _repository.searchTransactionsByKeyword(accountId, keyword);
  
  Future<List<domain.TransactionWithBalance>> filterByAmount(int accountId, double? min, double? max) => 
      _repository.filterTransactionsByAmount(accountId, min, max);
}

class CategoryActions {
  final CategoryRepository _repository;
  
  CategoryActions(this._repository);
  
  Future<domain.Category> createCategory(domain.Category category) => _repository.createCategory(category);
  Future<domain.Category> updateCategory(domain.Category category) => _repository.updateCategory(category);
  Future<void> deleteCategory(int id) => _repository.deleteCategory(id);
}

class CounterpartyActions {
  final CounterpartyRepository _repository;
  
  CounterpartyActions(this._repository);
  
  Future<domain.Counterparty> createCounterparty(domain.Counterparty counterparty) => _repository.createCounterparty(counterparty);
  Future<domain.Counterparty> updateCounterparty(domain.Counterparty counterparty) => _repository.updateCounterparty(counterparty);
  Future<void> deleteCounterparty(int id) => _repository.deleteCounterparty(id);
}