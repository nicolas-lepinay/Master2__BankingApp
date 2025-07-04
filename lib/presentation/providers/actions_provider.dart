import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';

// Provider pour les actions sur les comptes
final accountActionsProvider = Provider((ref) => AccountActions(ref));

// Provider pour les actions sur les transactions
final transactionActionsProvider = Provider((ref) => TransactionActions(ref));

class AccountActions {
  final Ref _ref;

  AccountActions(this._ref);

  AppDatabase get _database => _ref.read(databaseProvider);

  Future<void> createAccount({
    required String name,
    required String currency,
    required double initialBalance,
  }) async {
    await _database
        .into(_database.accounts)
        .insert(
          AccountsCompanion(
            name: Value(name),
            currency: Value(currency),
            initialBalance: Value(initialBalance),
            creationDate: Value(DateTime.now()),
          ),
        );

    // Invalider les providers pour rafraîchir les données
    _ref.invalidate(accountsProvider);
  }

  Future<void> updateAccount({
    required int id,
    required String name,
    required String currency,
    required double initialBalance,
  }) async {
    await (_database.update(
      _database.accounts,
    )..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(name),
        currency: Value(currency),
        initialBalance: Value(initialBalance),
      ),
    );

    _ref.invalidate(accountsProvider);
    _ref.invalidate(accountSummaryProvider);
  }

  Future<void> deleteAccount(int id) async {
    await (_database.delete(
      _database.accounts,
    )..where((a) => a.id.equals(id))).go();

    _ref.invalidate(accountsProvider);
  }
}

class TransactionActions {
  final Ref _ref;

  TransactionActions(this._ref);

  AppDatabase get _database => _ref.read(databaseProvider);

  Future<void> createTransaction({
    required int accountId,
    required String transactionType,
    required String currency,
    required double amount,
    String? title,
    String? comment,
    DateTime? date,
    String? counterpartyName, // Nouveau paramètre pour le nom du tiers
    int? category1Id,
    int status = 1,
  }) async {
    int? counterpartyId;

    // Si un nom de tiers est fourni, trouver ou créer le tiers
    if (counterpartyName != null && counterpartyName.trim().isNotEmpty) {
      counterpartyId = await _database.findOrCreateCounterparty(
        counterpartyName,
      );
    }

    await _database
        .into(_database.transactions)
        .insert(
          TransactionsCompanion(
            accountId: Value(accountId),
            transactionType: Value(transactionType),
            currency: Value(currency),
            amount: Value(amount),
            title: Value(title),
            comment: Value(comment),
            date: Value(date ?? DateTime.now()),
            counterpartyId: Value(counterpartyId),
            category1Id: Value(category1Id),
            status: Value(status),
          ),
        );

    // Invalider les providers pour rafraîchir les données
    _ref.invalidate(accountSummaryProvider);
    _ref.invalidate(transactionsWithBalanceProvider);
  }

  Future<void> updateTransaction({
    required int id,
    required int accountId,
    required String transactionType,
    required String currency,
    required double amount,
    String? title,
    String? comment,
    DateTime? date,
    String? counterpartyName, // Nouveau paramètre pour le nom du tiers
    int? category1Id,
    int? status,
  }) async {
    int? counterpartyId;

    // Si un nom de tiers est fourni, trouver ou créer le tiers
    if (counterpartyName != null && counterpartyName.trim().isNotEmpty) {
      counterpartyId = await _database.findOrCreateCounterparty(
        counterpartyName,
      );
    }

    await (_database.update(
      _database.transactions,
    )..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        accountId: Value(accountId),
        transactionType: Value(transactionType),
        currency: Value(currency),
        amount: Value(amount),
        title: Value(title),
        comment: Value(comment),
        date: Value(date ?? DateTime.now()),
        counterpartyId: Value(counterpartyId),
        category1Id: Value(category1Id),
        status: Value(status ?? 1),
      ),
    );

    _ref.invalidate(accountSummaryProvider);
    _ref.invalidate(transactionsWithBalanceProvider);
    _ref.invalidate(transactionProvider);
  }

  Future<void> deleteTransaction(int id, int accountId) async {
    await (_database.delete(
      _database.transactions,
    )..where((t) => t.id.equals(id))).go();

    _ref.invalidate(accountSummaryProvider);
    _ref.invalidate(transactionsWithBalanceProvider);
  }

  Future<void> toggleTransactionStatus(int id, int accountId) async {
    final transaction = await (_database.select(
      _database.transactions,
    )..where((t) => t.id.equals(id))).getSingle();

    final newStatus = transaction.status == 1 ? 0 : 1;

    await (_database.update(_database.transactions)
          ..where((t) => t.id.equals(id)))
        .write(TransactionsCompanion(status: Value(newStatus)));

    _ref.invalidate(accountSummaryProvider);
    _ref.invalidate(transactionsWithBalanceProvider);
    _ref.invalidate(transactionProvider);
  }
}
