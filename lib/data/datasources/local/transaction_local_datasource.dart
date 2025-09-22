import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:drift/drift.dart';

abstract class TransactionLocalDataSource {
  /// Get all transactions
  Future<List<TransactionModel>> getAllTransactions();

  /// Get transactions by account ID
  Future<List<TransactionModel>> getTransactionsByAccountId(int accountId);

  /// Get transaction by ID
  Future<TransactionModel?> getTransactionById(int id);

  /// Create a new transaction
  Future<TransactionModel> createTransaction(TransactionModel transaction);

  /// Update an existing transaction
  Future<TransactionModel> updateTransaction(TransactionModel transaction);

  /// Delete a transaction
  Future<void> deleteTransaction(int id);

  /// Get transactions in date range
  Future<List<TransactionModel>> getTransactionsInDateRange(
    int accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(
    int accountId,
    int categoryId,
  );

  /// Get transactions by counterparty
  Future<List<TransactionModel>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  );

  /// Stream to watch transactions changes
  Stream<List<TransactionModel>> watchAllTransactions();

  /// Stream to watch transactions for specific account
  Stream<List<TransactionModel>> watchTransactionsByAccountId(int accountId);

  /// Get followed transaction IDs
  Future<List<int>> getFollowedTransactionIds();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase _database;

  TransactionLocalDataSourceImpl(this._database);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final transactions =
        await (_database.select(_database.transactions)..orderBy([
              (tbl) =>
                  OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
            ]))
            .get();
    return transactions
        .map((transaction) => TransactionModel.fromDrift(transaction))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByAccountId(
    int accountId,
  ) async {
    final transactions =
        await (_database.select(_database.transactions)
              ..where((tbl) => tbl.accountId.equals(accountId))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
              ]))
            .get();

    return transactions
        .map((transaction) => TransactionModel.fromDrift(transaction))
        .toList();
  }

  @override
  Future<TransactionModel?> getTransactionById(int id) async {
    final transaction = await (_database.select(
      _database.transactions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return transaction != null ? TransactionModel.fromDrift(transaction) : null;
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    final companion = transaction.toCompanion();
    final id = await _database.into(_database.transactions).insert(companion);
    return transaction.copyWith(id: id);
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    final companion = transaction.toCompanion();
    await _database.update(_database.transactions).replace(companion);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await (_database.delete(
      _database.transactions,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<List<TransactionModel>> getTransactionsInDateRange(
    int accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions =
        await (_database.select(_database.transactions)
              ..where((tbl) => tbl.accountId.equals(accountId))
              ..where((tbl) => tbl.date.isBetweenValues(startDate, endDate))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
              ]))
            .get();

    return transactions
        .map((transaction) => TransactionModel.fromDrift(transaction))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCategory(
    int accountId,
    int categoryId,
  ) async {
    final transactions =
        await (_database.select(_database.transactions)
              ..where((tbl) => tbl.accountId.equals(accountId))
              ..where(
                (tbl) => tbl.deepestCategoryId.equals(categoryId),
              )
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
              ]))
            .get();

    return transactions
        .map((transaction) => TransactionModel.fromDrift(transaction))
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  ) async {
    final transactions =
        await (_database.select(_database.transactions)
              ..where((tbl) => tbl.accountId.equals(accountId))
              ..where((tbl) => tbl.counterpartyId.equals(counterpartyId))
              ..orderBy([
                (tbl) =>
                    OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
              ]))
            .get();

    return transactions
        .map((transaction) => TransactionModel.fromDrift(transaction))
        .toList();
  }

  @override
  Stream<List<TransactionModel>> watchAllTransactions() {
    return _database
        .select(_database.transactions)
        .watch()
        .map(
          (transactions) => transactions
              .map((transaction) => TransactionModel.fromDrift(transaction))
              .toList(),
        );
  }

  @override
  Stream<List<TransactionModel>> watchTransactionsByAccountId(int accountId) {
    return (_database.select(_database.transactions)
          ..where((tbl) => tbl.accountId.equals(accountId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.date, mode: OrderingMode.desc),
          ]))
        .watch()
        .map(
          (transactions) => transactions
              .map((transaction) => TransactionModel.fromDrift(transaction))
              .toList(),
        );
  }

  @override
  Future<List<int>> getFollowedTransactionIds() async {
    final followedTransactions = await _database
        .select(_database.followedTransactions)
        .get();
    return followedTransactions.map((ft) => ft.transactionId).toList();
  }
}
