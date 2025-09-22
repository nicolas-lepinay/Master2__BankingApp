import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
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
  final AccountLocalDataSource _accountLocalDataSource;
  final CounterpartyLocalDataSource _counterpartyLocalDataSource;
  final CategoryLocalDataSource _categoryLocalDataSource;

  TransactionRepositoryImpl(
    this._localDataSource,
    this._cacheManager,
    this._followedTransactionRepository,
    this._accountLocalDataSource,
    this._counterpartyLocalDataSource,
    this._categoryLocalDataSource,
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
    // Si le cache est initialisé, utiliser la méthode optimisée O(1)
    if (_cacheManager.isInitialized) {
      return _cacheManager.getTransactionById(id);
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

    final savedTransaction = savedModel.toEntity();

    // 🔥 FIX CRITIQUE : Émettre l'événement TransactionCreatedEvent pour réactivité
    AppEventBus.instance.fire(
      TransactionEventFactory.createTransactionCreatedEvent(
        transaction: savedTransaction,
        accountId: savedTransaction.accountId,
        context: 'repository_create',
      ),
    );

    return savedTransaction;
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

    final updatedTransaction = savedModel.toEntity();

    // 🔥 RÉACTIVITÉ : Émettre l'événement TransactionUpdatedEvent
    AppEventBus.instance.fire(
      TransactionEventFactory.createTransactionUpdatedEvent(
        updatedTransaction: updatedTransaction,
        accountId: updatedTransaction.accountId,
        context: 'repository_update',
      ),
    );

    return updatedTransaction;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    // Récupérer la transaction avant suppression pour l'événement
    final transaction = await getTransactionById(id);
    
    // Supprimer de la base de données
    await _localDataSource.deleteTransaction(id);

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.removeTransaction(id);
    }

    // 🔥 RÉACTIVITÉ : Émettre l'événement TransactionDeletedEvent
    if (transaction != null) {
      AppEventBus.instance.fire(
        TransactionEventFactory.createTransactionDeletedEvent(
          transactionId: id,
          accountId: transaction.accountId,
          deletedTransaction: transaction,
          context: 'repository_delete',
        ),
      );
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
    print('⚠️  FALLBACK: Cache non initialisé, calcul des soldes depuis la DB pour compte $accountId');
    return await _calculateTransactionsWithBalanceFallback(accountId);
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
  Future<List<TransactionWithBalance>>
  getFollowedTransactionsWithDetails() async {
    // Si le cache est initialisé, utiliser le cache MVVM
    if (_cacheManager.isInitialized) {
      return _cacheManager.getFollowedTransactionsWithBalance();
    }

    // Fallback : utiliser l'ancienne méthode
    final followedTransactionsWithCounterparty =
        await _followedTransactionRepository
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
        deepestCategoryId: txWithCounterparty.transaction.deepestCategoryId,
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

      result.add(
        TransactionWithBalance(
          transaction: transaction,
          account: account,
          balanceAfter: balance,
        ),
      );
    }

    return result;
  }

  @override
  Future<List<int>> getFollowedTransactionIds() async {
    // Si le cache est initialisé, utiliser le cache MVVM
    if (_cacheManager.isInitialized) {
      return _cacheManager.getFollowedTransactionIds();
    }

    // Fallback : utiliser l'ancienne méthode
    return await _followedTransactionRepository.getFollowedTransactionIds();
  }

  @override
  Future<bool> isTransactionFollowed(int transactionId) async {
    // Si le cache est initialisé, utiliser le cache MVVM
    if (_cacheManager.isInitialized) {
      return _cacheManager.isTransactionFollowed(transactionId);
    }

    // Fallback : utiliser l'ancienne méthode
    return await _followedTransactionRepository.isTransactionFollowed(
      transactionId,
    );
  }

  @override
  Future<void> followTransaction(int transactionId) async {
    // Ajouter dans la base de données
    await _followedTransactionRepository.addFollowedTransaction(transactionId);

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.followTransaction(transactionId);
    }
  }

  @override
  Future<void> unfollowTransaction(int transactionId) async {
    // Supprimer de la base de données
    await _followedTransactionRepository.removeFollowedTransaction(
      transactionId,
    );

    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.unfollowTransaction(transactionId);
    }
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

  /// Calcule les transactions avec solde depuis la base de données (fallback)
  /// Inspiré du code V1 - utilisé uniquement en cas de cache non initialisé
  Future<List<TransactionWithBalance>> _calculateTransactionsWithBalanceFallback(
    int accountId,
  ) async {
    try {
      // Récupérer le compte depuis la DataSource
      final accountModel = await _accountLocalDataSource.getAccountById(accountId);
      if (accountModel == null) {
        print('❌ FALLBACK: Compte $accountId introuvable');
        return [];
      }
      
      final account = accountModel.toEntity();
      
      // Récupérer les transactions triées par date
      final transactionModels = await _localDataSource.getTransactionsByAccountId(
        accountId,
      );
      
      // Trier par date (ascendant) pour calculer les soldes chronologiquement
      transactionModels.sort((a, b) => a.date.compareTo(b.date));
      
      final transactionsWithBalance = <TransactionWithBalance>[];
      double currentBalance = account.initialBalance;
      
      print('📊 FALLBACK: Calcul des soldes pour ${transactionModels.length} transactions (solde initial: ${account.initialBalance})');
      
      for (final transactionModel in transactionModels) {
        final transaction = transactionModel.toEntity();
        
        // Calculer le nouveau solde (même logique que le cache)
        final signedAmount = transaction.type == TransactionType.income
            ? transaction.amount
            : -transaction.amount;
        currentBalance += signedAmount;
        
        // Récupérer la contrepartie si disponible
        Counterparty? counterparty;
        if (transaction.counterpartyId != null) {
          final counterpartyModel = await _counterpartyLocalDataSource.getCounterpartyById(
            transaction.counterpartyId!,
          );
          counterparty = counterpartyModel?.toEntity();
        }
        
        // Récupérer les catégories
        final categories = await _getTransactionCategoriesFallback(transaction);
        
        // Créer l'objet TransactionWithBalance
        final transactionWithBalance = TransactionWithBalance(
          transaction: transaction,
          account: account,
          balanceAfter: AccountBalance(
            balance: Money(amount: currentBalance, currency: account.currency),
            calculatedAt: DateTime.now(),
          ),
          counterparty: counterparty,
          categories: categories,
        );
        
        transactionsWithBalance.add(transactionWithBalance);
      }
      
      print('✅ FALLBACK: Calcul terminé, solde final: $currentBalance');
      return transactionsWithBalance;
      
    } catch (e) {
      print('❌ FALLBACK: Erreur lors du calcul des soldes: $e');
      rethrow;
    }
  }
  
  /// Récupère les catégories d'une transaction (fallback)
  /// Récupère la hiérarchie complète des catégories d'une transaction (fallback DB)
  /// Utilise le même algorithme que le CacheManager mais avec accès direct à la DB
  Future<List<Category>> _getTransactionCategoriesFallback(
    Transaction transaction,
  ) async {
    if (transaction.deepestCategoryId == null) return [];
    
    final hierarchy = <Category>[];
    int? currentCategoryId = transaction.deepestCategoryId;
    
    // Remonter la hiérarchie jusqu'à la racine (même algorithme que le cache)
    while (currentCategoryId != null) {
      final categoryModel = await _categoryLocalDataSource.getCategoryById(currentCategoryId);
      if (categoryModel == null) {
        // Catégorie introuvable, arrêter la remontée
        break;
      }
      
      final category = categoryModel.toEntity();
      hierarchy.add(category);
      
      // Remonter vers le parent
      currentCategoryId = categoryModel.parentId;
      
      // Sécurité : arrêter si on atteint la racine (level 1) ou si pas de parent
      if (category.level <= 1 || categoryModel.parentId == null) {
        break;
      }
    }
    
    // Retourner dans l'ordre : [Fast Food, Restaurants, Food, Expenses]
    // (du plus spécifique au plus général)
    return hierarchy;
  }

}
