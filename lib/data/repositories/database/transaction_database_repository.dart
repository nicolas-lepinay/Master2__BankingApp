import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/models/models.dart';

/// Repository pour les opérations sur les transactions
///
/// Contient toutes les opérations CRUD et logiques métier
/// liées à la gestion des transactions générales.
class TransactionDatabaseRepository {
  final AppDatabase _database;

  TransactionDatabaseRepository(this._database);

  /// Récupère toutes les transactions d'un compte
  Future<List<Transaction>> getTransactionsByAccount(int accountId) async {
    return await (_database.select(_database.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Récupère une transaction par son ID
  Future<Transaction?> getTransactionById(int id) async {
    return await (_database.select(
      _database.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Récupère les transactions avec leurs contreparties
  ///
  /// Retourne les transactions avec les informations
  /// de contrepartie associées via un JOIN.
  Future<List<TransactionWithCounterparty>> getTransactionsWithCounterparty(
    int accountId,
  ) async {
    final query =
        _database.select(_database.transactions).join([
            leftOuterJoin(
              _database.counterparties,
              _database.counterparties.id.equalsExp(
                _database.transactions.counterpartyId,
              ),
            ),
          ])
          ..where(_database.transactions.accountId.equals(accountId))
          ..orderBy([
            OrderingTerm.desc(_database.transactions.date),
            OrderingTerm.desc(_database.transactions.id),
          ]);

    final results = await query.get();
    final transactionsWithCounterparty = <TransactionWithCounterparty>[];

    for (final row in results) {
      final transaction = row.readTable(_database.transactions);
      final counterparty = row.readTableOrNull(_database.counterparties);

      transactionsWithCounterparty.add(
        TransactionWithCounterparty(
          transaction: transaction,
          counterpartyName: counterparty?.name,
          counterpartyIcon: counterparty?.icon,
        ),
      );
    }

    return transactionsWithCounterparty;
  }

  /// Récupère les transactions autour d'aujourd'hui (passé et futur)
  ///
  /// Cette méthode retourne les transactions dans une perspective
  /// temporelle avec celles du passé et celles programmées pour le futur.
  Future<List<TransactionWithCounterparty>> getTransactionsAroundToday(
    int accountId, {
    int pastDays = 7,
    int futureDays = 7,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: pastDays));
    final endDate = now.add(Duration(days: futureDays));

    final query =
        _database.select(_database.transactions).join([
            leftOuterJoin(
              _database.counterparties,
              _database.counterparties.id.equalsExp(
                _database.transactions.counterpartyId,
              ),
            ),
          ])
          ..where(
            _database.transactions.accountId.equals(accountId) &
                _database.transactions.date.isBetweenValues(startDate, endDate),
          )
          ..orderBy([
            OrderingTerm.asc(_database.transactions.date),
            OrderingTerm.asc(_database.transactions.id),
          ]);

    final results = await query.get();
    final transactionsWithCounterparty = <TransactionWithCounterparty>[];

    for (final row in results) {
      final transaction = row.readTable(_database.transactions);
      final counterparty = row.readTableOrNull(_database.counterparties);

      transactionsWithCounterparty.add(
        TransactionWithCounterparty(
          transaction: transaction,
          counterpartyName: counterparty?.name,
          counterpartyIcon: counterparty?.icon,
        ),
      );
    }

    return transactionsWithCounterparty;
  }

  /// Crée une nouvelle transaction
  Future<int> createTransaction({
    required int accountId,
    int? counterpartyId,
    int? category1Id,
    int? category2Id,
    int? category3Id,
    int? category4Id,
    required String transactionType,
    required String currency,
    required double amount,
    double? amountBeforeConversion,
    String? title,
    String? comment,
    required DateTime date,
    required int status,
  }) async {
    return await _database
        .into(_database.transactions)
        .insert(
          TransactionsCompanion(
            accountId: Value(accountId),
            counterpartyId: Value(counterpartyId),
            category1Id: Value(category1Id),
            category2Id: Value(category2Id),
            category3Id: Value(category3Id),
            category4Id: Value(category4Id),
            transactionType: Value(transactionType),
            currency: Value(currency),
            amount: Value(amount),
            amountBeforeConversion: Value(amountBeforeConversion),
            title: Value(title),
            comment: Value(comment),
            date: Value(date),
            status: Value(status),
          ),
        );
  }

  /// Met à jour une transaction
  Future<bool> updateTransaction(
    int id, {
    int? accountId,
    int? counterpartyId,
    int? category1Id,
    int? category2Id,
    int? category3Id,
    int? category4Id,
    String? transactionType,
    String? currency,
    double? amount,
    double? amountBeforeConversion,
    String? title,
    String? comment,
    DateTime? date,
    int? status,
  }) async {
    final companion = TransactionsCompanion(
      accountId: accountId != null ? Value(accountId) : const Value.absent(),
      counterpartyId: counterpartyId != null
          ? Value(counterpartyId)
          : const Value.absent(),
      category1Id: category1Id != null
          ? Value(category1Id)
          : const Value.absent(),
      category2Id: category2Id != null
          ? Value(category2Id)
          : const Value.absent(),
      category3Id: category3Id != null
          ? Value(category3Id)
          : const Value.absent(),
      category4Id: category4Id != null
          ? Value(category4Id)
          : const Value.absent(),
      transactionType: transactionType != null
          ? Value(transactionType)
          : const Value.absent(),
      currency: currency != null ? Value(currency) : const Value.absent(),
      amount: amount != null ? Value(amount) : const Value.absent(),
      amountBeforeConversion: amountBeforeConversion != null
          ? Value(amountBeforeConversion)
          : const Value.absent(),
      title: title != null ? Value(title) : const Value.absent(),
      comment: comment != null ? Value(comment) : const Value.absent(),
      date: date != null ? Value(date) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
    );

    final updatedRows = await (_database.update(
      _database.transactions,
    )..where((t) => t.id.equals(id))).write(companion);

    return updatedRows > 0;
  }

  /// Supprime une transaction
  Future<bool> deleteTransaction(int id) async {
    final deletedRows = await (_database.delete(
      _database.transactions,
    )..where((t) => t.id.equals(id))).go();

    return deletedRows > 0;
  }

  /// Récupère les transactions par type (DEBIT/CREDIT)
  Future<List<Transaction>> getTransactionsByType(
    int accountId,
    String transactionType,
  ) async {
    return await (_database.select(_database.transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.transactionType.equals(transactionType),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Récupère les transactions par statut
  Future<List<Transaction>> getTransactionsByStatus(
    int accountId,
    int status,
  ) async {
    return await (_database.select(_database.transactions)
          ..where(
            (t) => t.accountId.equals(accountId) & t.status.equals(status),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Récupère les transactions dans une plage de dates
  Future<List<Transaction>> getTransactionsByDateRange(
    int accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await (_database.select(_database.transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.date.isBetweenValues(startDate, endDate),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Récupère les transactions par contrepartie
  Future<List<Transaction>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  ) async {
    return await (_database.select(_database.transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.counterpartyId.equals(counterpartyId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Recherche de transactions par titre ou commentaire
  Future<List<Transaction>> searchTransactions(
    int accountId,
    String searchTerm,
  ) async {
    final lowerSearchTerm = searchTerm.toLowerCase();

    return await (_database.select(_database.transactions)
          ..where(
            (t) =>
                t.accountId.equals(accountId) &
                (t.title.lower().contains(lowerSearchTerm) |
                    t.comment.lower().contains(lowerSearchTerm)),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Récupère le nombre total de transactions d'un compte
  Future<int> getTransactionCount(int accountId) async {
    final result = await (_database.select(
      _database.transactions,
    )..where((t) => t.accountId.equals(accountId))).get();
    return result.length;
  }

  /// Récupère les transactions récentes
  Future<List<Transaction>> getRecentTransactions(
    int accountId, {
    int limit = 10,
  }) async {
    return await (_database.select(_database.transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
  }
}
