import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/models/models.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;
  final CacheManager _cacheManager;

  TransactionRepositoryImpl(this._localDataSource, this._cacheManager);

  @override
  Future<List<Transaction>> getAllTransactions() async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getAllTransactions();
    }
    
    // Sinon, charger depuis la base de données
    final transactionModels = await _localDataSource.getAllTransactions();
    return transactionModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByAccountId(int accountId) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getTransactionsByAccountId(accountId);
    }
    
    // Sinon, charger depuis la base de données
    final transactionModels = await _localDataSource.getTransactionsByAccountId(accountId);
    return transactionModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final allTransactions = _cacheManager.getAllTransactions();
      try {
        return allTransactions.firstWhere((transaction) => transaction.id == id);
      } catch (e) {
        return null;
      }
    }
    
    // Sinon, charger depuis la base de données
    final transactionModel = await _localDataSource.getTransactionById(id);
    return transactionModel?.toEntity();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    // Créer le modèle pour la base de données
    final transactionModel = TransactionModel.fromEntity(transaction);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.createTransaction(transactionModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addTransaction(savedModel);
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    // Créer le modèle pour la base de données
    final transactionModel = TransactionModel.fromEntity(transaction);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.updateTransaction(transactionModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addTransaction(savedModel); // addTransaction fait aussi update
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<void> deleteTransaction(int id) async {
    // Supprimer de la base de données
    await _localDataSource.deleteTransaction(id);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.removeTransaction(id);
    }
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsWithBalance(int accountId) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getTransactionsWithBalance(accountId);
    }
    
    // Fallback : calculer depuis la base de données (plus lent)
    final transactionModels = await _localDataSource.getTransactionsByAccountId(accountId);
    // Note : Cette implémentation de fallback est simplifiée
    // En production, il faudrait recalculer les soldes ici
    return transactionModels.map((model) {
      // Implémentation simplifiée pour le fallback
      return TransactionWithBalance(
        transaction: model.toEntity(),
        account: Account(
          id: accountId,
          name: 'Account',
          currency: model.currency,
          initialBalance: 0,
          creationDate: DateTime.now(),
        ),
        balanceAfter: AccountBalance(
          balance: Money(amount: 0, currency: model.currency),
          calculatedAt: DateTime.now(),
        ),
      );
    }).toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsWithBalanceInRange(
    int accountId,
    DateRange dateRange,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where((txWithBalance) => dateRange.contains(txWithBalance.transaction.date))
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsAroundToday(int accountId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateRange = DateRange(
      start: today.subtract(const Duration(days: 30)),
      end: today.add(const Duration(days: 30)),
    );
    
    return getTransactionsWithBalanceInRange(accountId, dateRange);
  }

  @override
  Future<List<TransactionWithBalance>> searchTransactionsByKeyword(
    int accountId,
    String keyword,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where((txWithBalance) => txWithBalance.matchesKeyword(keyword))
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> filterTransactionsByAmount(
    int accountId,
    double? minAmount,
    double? maxAmount,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where((txWithBalance) => txWithBalance.isInAmountRange(minAmount, maxAmount))
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsByCategory(
    int accountId,
    int categoryId,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where((txWithBalance) => 
            txWithBalance.transaction.categoryIds.contains(categoryId))
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where((txWithBalance) => 
            txWithBalance.transaction.counterpartyId == counterpartyId)
        .toList();
  }

  @override
  Stream<List<Transaction>> watchAllTransactions() {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream;
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAllTransactions()
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<List<Transaction>> watchTransactionsByAccountId(int accountId) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream.map((transactions) {
        return transactions.where((transaction) => transaction.accountId == accountId).toList();
      });
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchTransactionsByAccountId(accountId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<List<TransactionWithBalance>> watchTransactionsWithBalance(int accountId) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream.asyncMap((_) async {
        return _cacheManager.getTransactionsWithBalance(accountId);
      });
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchTransactionsByAccountId(accountId)
        .asyncMap((models) async {
      return getTransactionsWithBalance(accountId);
    });
  }
}