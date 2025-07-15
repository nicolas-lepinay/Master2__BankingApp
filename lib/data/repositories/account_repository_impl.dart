import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/models/models.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountLocalDataSource _localDataSource;
  final CacheManager _cacheManager;

  AccountRepositoryImpl(this._localDataSource, this._cacheManager);

  @override
  Future<List<Account>> getAllAccounts() async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getAllAccounts();
    }
    
    // Sinon, charger depuis la base de données
    final accountModels = await _localDataSource.getAllAccounts();
    return accountModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Account?> getAccountById(int id) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.getAccountById(id);
    }
    
    // Sinon, charger depuis la base de données
    final accountModel = await _localDataSource.getAccountById(id);
    return accountModel?.toEntity();
  }

  @override
  Future<Account> createAccount(Account account) async {
    // Créer le modèle pour la base de données
    final accountModel = AccountModel.fromEntity(account);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.createAccount(accountModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addAccount(savedModel);
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<Account> updateAccount(Account account) async {
    // Créer le modèle pour la base de données
    final accountModel = AccountModel.fromEntity(account);
    
    // Sauvegarder dans la base de données
    final savedModel = await _localDataSource.updateAccount(accountModel);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.addAccount(savedModel); // addAccount fait aussi update
    }
    
    return savedModel.toEntity();
  }

  @override
  Future<void> deleteAccount(int id) async {
    // Supprimer de la base de données
    await _localDataSource.deleteAccount(id);
    
    // Mettre à jour le cache si initialisé
    if (_cacheManager.isInitialized) {
      await _cacheManager.invalidateAll(); // Recalculer tout
    }
  }

  @override
  Future<AccountSummary> getAccountSummary(int accountId) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final summary = _cacheManager.getAccountSummary(accountId);
      if (summary != null) {
        return summary;
      }
    }
    
    // Fallback : calculer depuis la base de données (plus lent)
    final account = await getAccountById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }
    
    // Retourner un résumé basique
    return AccountSummary(
      account: account,
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
  }

  @override
  Future<AccountBalance> getAccountBalanceAtDate(int accountId, DateTime date) async {
    // Si le cache est initialisé, utiliser le cache
    if (_cacheManager.isInitialized) {
      final transactionsWithBalance = _cacheManager.getTransactionsWithBalance(accountId);
      
      // Trouver la dernière transaction avant ou à la date donnée
      TransactionWithBalance? lastTransaction;
      for (final txWithBalance in transactionsWithBalance) {
        if (txWithBalance.transaction.date.isBefore(date) || 
            txWithBalance.transaction.date.isAtSameMomentAs(date)) {
          lastTransaction = txWithBalance;
        } else {
          break; // Les transactions sont triées par date
        }
      }
      
      if (lastTransaction != null) {
        return lastTransaction.balanceAfter;
      }
      
      // Pas de transactions avant cette date, retourner le solde initial
      final account = _cacheManager.getAccountById(accountId);
      if (account != null) {
        return AccountBalance(
          balance: Money(amount: account.initialBalance, currency: account.currency),
          calculatedAt: DateTime.now(),
        );
      }
    }
    
    // Fallback : calculer depuis la base de données (plus lent)
    final account = await getAccountById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }
    
    return AccountBalance(
      balance: Money(amount: account.initialBalance, currency: account.currency),
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Future<AccountBalance> getCurrentAccountBalance(int accountId) async {
    return getAccountBalanceAtDate(accountId, DateTime.now());
  }

  @override
  Stream<List<Account>> watchAllAccounts() {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.accountsStream;
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAllAccounts()
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<Account?> watchAccountById(int id) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.accountsStream.map((accounts) {
        try {
          return accounts.firstWhere((account) => account.id == id);
        } catch (e) {
          return null;
        }
      });
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAccountById(id)
        .map((model) => model?.toEntity());
  }

  @override
  Stream<AccountSummary> watchAccountSummary(int accountId) {
    // Si le cache est initialisé, utiliser le stream du cache
    if (_cacheManager.isInitialized) {
      return _cacheManager.accountsStream.asyncMap((_) async {
        final summary = _cacheManager.getAccountSummary(accountId);
        if (summary != null) {
          return summary;
        }
        
        // Fallback
        return getAccountSummary(accountId);
      });
    }
    
    // Sinon, utiliser le stream de la base de données
    return _localDataSource.watchAccountById(accountId)
        .asyncMap((model) async {
      if (model == null) {
        throw Exception('Account not found: $accountId');
      }
      
      return getAccountSummary(accountId);
    });
  }
}