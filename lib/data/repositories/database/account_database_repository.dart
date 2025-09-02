import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/models/models.dart';

/// Repository pour les opérations sur les comptes
///
/// Contient toutes les opérations CRUD et logiques métier
/// liées à la gestion des comptes et calculs de solde.
class AccountDatabaseRepository {
  final AppDatabase _database;

  AccountDatabaseRepository(this._database);

  /// Récupère tous les comptes
  Future<List<Account>> getAllAccounts() async {
    return await _database.select(_database.accounts).get();
  }

  /// Récupère un compte par son ID
  Future<Account?> getAccountById(int id) async {
    return await (_database.select(
      _database.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Calcule le solde d'un compte à une date spécifique
  ///
  /// Cette méthode calcule le solde d'un compte en prenant en compte
  /// toutes les transactions jusqu'à la date spécifiée.
  Future<double> getAccountBalanceAtDate(int accountId, DateTime date) async {
    final account = await (_database.select(
      _database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final transactionsQuery = _database.select(_database.transactions)
      ..where(
        (t) =>
            t.accountId.equals(accountId) & t.date.isSmallerOrEqualValue(date),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final transactionsList = await transactionsQuery.get();

    double balance = account.initialBalance;
    for (final transaction in transactionsList) {
      final amount = transaction.amountBeforeConversion ?? transaction.amount;
      if (transaction.transactionType == 'DEBIT') {
        balance -= amount;
      } else {
        balance += amount;
      }
    }

    return balance;
  }

  /// Récupère le solde confirmé d'un compte (status = 1 uniquement)
  ///
  /// Calcule le solde en ne prenant en compte que les transactions
  /// avec un statut confirmé (status = 1).
  Future<double> getAccountConfirmedBalance(int accountId) async {
    final account = await (_database.select(
      _database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final transactionsQuery = _database.select(_database.transactions)
      ..where((t) => t.accountId.equals(accountId) & t.status.equals(1))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final transactionsList = await transactionsQuery.get();

    double balance = account.initialBalance;
    for (final transaction in transactionsList) {
      final amount = transaction.amountBeforeConversion ?? transaction.amount;
      if (transaction.transactionType == 'DEBIT') {
        balance -= amount;
      } else {
        balance += amount;
      }
    }

    return balance;
  }

  /// Récupère les transactions avec le solde courant après chaque transaction
  ///
  /// Cette méthode retourne toutes les transactions d'un compte
  /// avec le solde calculé après chaque transaction.
  Future<List<TransactionWithBalance>> getTransactionsWithBalance(
    int accountId,
  ) async {
    final transactionsQuery = _database.select(_database.transactions)
      ..where((t) => t.accountId.equals(accountId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);

    final transactionsList = await transactionsQuery.get();

    // Calculer le solde courant pour chaque transaction
    final result = <TransactionWithBalance>[];

    for (int i = transactionsList.length - 1; i >= 0; i--) {
      final transaction = transactionsList[i];
      final balance = await getAccountBalanceAtDate(
        accountId,
        transaction.date,
      );

      result.insert(
        0,
        TransactionWithBalance(transaction: transaction, balanceAfter: balance),
      );
    }

    return result;
  }

  /// Récupère un résumé complet d'un compte
  ///
  /// Calcule le résumé d'un compte incluant le solde actuel,
  /// le solde confirmé, les dépenses totales et les revenus totaux.
  Future<AccountSummary> getAccountSummary(int accountId) async {
    final account = await (_database.select(
      _database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final expensesQuery = _database.customSelect(
      'SELECT SUM(COALESCE(amount_converted, amount)) as total FROM transactions WHERE account_id = ? AND transaction_type = \'DEBIT\'',
      variables: [Variable.withInt(accountId)],
      readsFrom: {_database.transactions},
    );

    final revenuesQuery = _database.customSelect(
      'SELECT SUM(COALESCE(amount_converted, amount)) as total FROM transactions WHERE account_id = ? AND transaction_type = \'CREDIT\'',
      variables: [Variable.withInt(accountId)],
      readsFrom: {_database.transactions},
    );

    final expensesResult = await expensesQuery.getSingle();
    final revenuesResult = await revenuesQuery.getSingle();

    final totalExpenses = expensesResult.data['total'] as double? ?? 0.0;
    final totalRevenues = revenuesResult.data['total'] as double? ?? 0.0;

    final currentBalance =
        account.initialBalance + totalRevenues - totalExpenses;

    // Récupérer le solde confirmé
    final confirmedBalance = await getAccountConfirmedBalance(accountId);

    return AccountSummary(
      account: account,
      currentBalance: currentBalance,
      confirmedBalance: confirmedBalance,
      totalExpenses: totalExpenses,
      totalRevenues: totalRevenues,
    );
  }

  /// Crée un nouveau compte
  Future<int> createAccount({
    required String name,
    required String currency,
    required double initialBalance,
    String? icon,
  }) async {
    return await _database
        .into(_database.accounts)
        .insert(
          AccountsCompanion(
            name: Value(name),
            currency: Value(currency),
            initialBalance: Value(initialBalance),
            creationDate: Value(DateTime.now()),
            icon: Value(icon),
          ),
        );
  }

  /// Met à jour un compte
  Future<bool> updateAccount(
    int id, {
    String? name,
    String? currency,
    double? initialBalance,
    String? icon,
  }) async {
    final companion = AccountsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      currency: currency != null ? Value(currency) : const Value.absent(),
      initialBalance: initialBalance != null
          ? Value(initialBalance)
          : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
    );

    final updatedRows = await (_database.update(
      _database.accounts,
    )..where((a) => a.id.equals(id))).write(companion);

    return updatedRows > 0;
  }

  /// Supprime un compte
  Future<bool> deleteAccount(int id) async {
    final deletedRows = await (_database.delete(
      _database.accounts,
    )..where((a) => a.id.equals(id))).go();

    return deletedRows > 0;
  }

  /// Récupère les comptes par devise
  Future<List<Account>> getAccountsByCurrency(String currency) async {
    return await (_database.select(_database.accounts)
          ..where((a) => a.currency.equals(currency))
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .get();
  }

  /// Récupère le nombre total de comptes
  Future<int> getAccountCount() async {
    final result = await _database.select(_database.accounts).get();
    return result.length;
  }

  /// Récupère tous les résumés de comptes
  Future<List<AccountSummary>> getAllAccountSummaries() async {
    final accounts = await getAllAccounts();
    final summaries = <AccountSummary>[];

    for (final account in accounts) {
      final summary = await getAccountSummary(account.id);
      summaries.add(summary);
    }

    return summaries;
  }
}
