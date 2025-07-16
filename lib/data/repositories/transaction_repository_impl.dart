import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:bankapp/data/repositories/database/followed_transaction_database_repository.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;
  final CacheManager _cacheManager;
  final FollowedTransactionDatabaseRepository _followedTransactionRepository;

  TransactionRepositoryImpl(
    this._localDataSource,
    this._cacheManager,
    this._followedTransactionRepository,
  );

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
    final transactionModels = await _localDataSource.getTransactionsByAccountId(
      accountId,
    );
    return transactionModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Transaction?> getTransactionById(int id) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final allTransactions = _cacheManager.getAllTransactions();
      try {
        return allTransactions.firstWhere(
          (transaction) => transaction.id == id,
        );
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
    final savedModel = await _localDataSource.createTransaction(
      transactionModel,
    );

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
    final savedModel = await _localDataSource.updateTransaction(
      transactionModel,
    );

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addTransaction(
        savedModel,
      ); // addTransaction fait aussi update
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
  Future<List<TransactionWithBalance>> getTransactionsWithBalance(
    int accountId,
  ) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getTransactionsWithBalance(accountId);
    }

    // Fallback : calculer depuis la base de données (plus lent)
    final transactionModels = await _localDataSource.getTransactionsByAccountId(
      accountId,
    );
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
        .where(
          (txWithBalance) => dateRange.contains(txWithBalance.transaction.date),
        )
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsAroundToday(
    int accountId,
  ) async {
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
        .where(
          (txWithBalance) =>
              txWithBalance.isInAmountRange(minAmount, maxAmount),
        )
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsByCategory(
    int accountId,
    int categoryId,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where(
          (txWithBalance) =>
              txWithBalance.transaction.categoryIds.contains(categoryId),
        )
        .toList();
  }

  @override
  Future<List<TransactionWithBalance>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  ) async {
    final allTransactions = await getTransactionsWithBalance(accountId);
    return allTransactions
        .where(
          (txWithBalance) =>
              txWithBalance.transaction.counterpartyId == counterpartyId,
        )
        .toList();
  }

  @override
  Stream<List<Transaction>> watchAllTransactions() {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream;
    }

    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAllTransactions().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Stream<List<Transaction>> watchTransactionsByAccountId(int accountId) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream.map((transactions) {
        return transactions
            .where((transaction) => transaction.accountId == accountId)
            .toList();
      });
    }

    // Sinon, utiliser le stream de la base de données
    return _localDataSource
        .watchTransactionsByAccountId(accountId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<List<TransactionWithBalance>> watchTransactionsWithBalance(
    int accountId,
  ) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.transactionsStream.asyncMap((_) async {
        return _cacheManager.getTransactionsWithBalance(accountId);
      });
    }

    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchTransactionsByAccountId(accountId).asyncMap((
      models,
    ) async {
      return getTransactionsWithBalance(accountId);
    });
  }

  // ============================================================================
  // FOLLOWED TRANSACTIONS METHODS
  // ============================================================================

  @override
  Future<List<TransactionWithBalance>> getFollowedTransactionsWithDetails() async {
    final followedTransactionsWithCounterparty = await _followedTransactionRepository
        .getFollowedTransactionsWithDetails();

    // Convertir TransactionWithCounterparty en TransactionWithBalance
    final List<TransactionWithBalance> result = [];
    for (final txWithCounterparty in followedTransactionsWithCounterparty) {
      final transaction = Transaction(
        id: txWithCounterparty.transaction.id,
        accountId: txWithCounterparty.transaction.accountId,
        type: TransactionType.values.firstWhere(
          (t) => t.name == txWithCounterparty.transaction.type,
        ),
        amount: txWithCounterparty.transaction.amount,
        currency: txWithCounterparty.transaction.currency,
        date: txWithCounterparty.transaction.date,
        title: txWithCounterparty.transaction.title,
        comment: txWithCounterparty.transaction.comment,
        counterpartyId: txWithCounterparty.transaction.counterpartyId,
        category1Id: txWithCounterparty.transaction.category1Id,
        category2Id: txWithCounterparty.transaction.category2Id,
        category3Id: txWithCounterparty.transaction.category3Id,
        category4Id: txWithCounterparty.transaction.category4Id,
        status: TransactionStatus.values.firstWhere(
          (s) => s.index == txWithCounterparty.transaction.status,
        ),
      );

      // Obtenir les informations du compte
      final accounts = _cacheManager.getAllAccounts();
      final account = accounts.firstWhere(
        (a) => a.id == transaction.accountId,
        orElse: () => Account(
          id: transaction.accountId,
          name: 'Account ${transaction.accountId}',
          currency: transaction.currency,
          initialBalance: 0,
          creationDate: DateTime.now(),
        ),
      );

      // Calculer le solde (simplification pour l'instant)
      final balance = AccountBalance(
        balance: Money(amount: 0, currency: transaction.currency),
        calculatedAt: DateTime.now(),
      );

      result.add(TransactionWithBalance(
        transaction: transaction,
        account: account,
        balanceAfter: balance,
      ));
    }

    return result;
  }

  @override
  Future<List<int>> getFollowedTransactionIds() async {
    return await _followedTransactionRepository.getFollowedTransactionIds();
  }

  @override
  Future<bool> isTransactionFollowed(int transactionId) async {
    return await _followedTransactionRepository.isTransactionFollowed(transactionId);
  }

  @override
  Future<void> followTransaction(int transactionId) async {
    await _followedTransactionRepository.addFollowedTransaction(transactionId);
  }

  @override
  Future<void> unfollowTransaction(int transactionId) async {
    await _followedTransactionRepository.removeFollowedTransaction(transactionId);
  }

  @override
  Future<void> toggleTransactionStatus(int transactionId) async {
    // Récupérer la transaction existante
    final transaction = await getTransactionById(transactionId);
    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    // Inverser le statut
    final newStatus = transaction.status == TransactionStatus.completed
        ? TransactionStatus.pending
        : TransactionStatus.completed;

    // Créer une nouvelle transaction avec le statut inversé (utilise copyWith)
    final updatedTransaction = transaction.copyWith(status: newStatus);

    // Sauvegarder la transaction mise à jour
    await updateTransaction(updatedTransaction);
  }
}
