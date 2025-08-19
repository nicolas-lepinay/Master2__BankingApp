import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/models/models.dart';

/// Repository pour les opérations sur les transactions suivies
///
/// Contient toutes les opérations CRUD et logiques métier
/// liées à la gestion des transactions suivies.
class FollowedTransactionDatabaseRepository {
  final AppDatabase _database;

  FollowedTransactionDatabaseRepository(this._database);

  /// Ajoute une transaction aux transactions suivies
  ///
  /// Vérifie d'abord que la transaction existe et qu'elle
  /// n'est pas déjà suivie avant de l'ajouter.
  Future<void> addFollowedTransaction(int transactionId) async {
    // Vérifier que la transaction existe
    final transaction = await (_database.select(
      _database.transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();

    if (transaction == null) {
      throw ArgumentError('Transaction avec ID $transactionId non trouvée');
    }

    // Vérifier si elle n'est pas déjà suivie
    final existingFollow = await (_database.select(
      _database.followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).getSingleOrNull();

    if (existingFollow != null) {
      throw StateError('Transaction déjà suivie');
    }

    // Ajouter la transaction aux suivies
    await _database
        .into(_database.followedTransactions)
        .insert(
          FollowedTransactionsCompanion(
            transactionId: Value(transactionId),
            followedDate: Value(DateTime.now()),
          ),
        );
  }

  /// Retire une transaction des transactions suivies
  Future<void> removeFollowedTransaction(int transactionId) async {
    final deletedRows = await (_database.delete(
      _database.followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).go();

    if (deletedRows == 0) {
      throw StateError('Transaction non trouvée dans les suivies');
    }
  }

  /// Bascule le statut de suivi d'une transaction
  ///
  /// Si la transaction est suivie, elle est retirée.
  /// Si elle n'est pas suivie, elle est ajoutée.
  Future<bool> toggleFollowedTransaction(int transactionId) async {
    final isFollowed = await isTransactionFollowed(transactionId);

    if (isFollowed) {
      await removeFollowedTransaction(transactionId);
      return false;
    } else {
      await addFollowedTransaction(transactionId);
      return true;
    }
  }

  /// Vérifie si une transaction est suivie
  Future<bool> isTransactionFollowed(int transactionId) async {
    final followedTransaction = await (_database.select(
      _database.followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).getSingleOrNull();

    return followedTransaction != null;
  }

  /// Récupère toutes les transactions suivies avec leurs détails
  ///
  /// Retourne les transactions suivies avec les informations
  /// de la transaction et de la contrepartie associées.
  Future<List<TransactionWithCounterparty>>
  getFollowedTransactionsWithDetails() async {
    final query = _database.select(_database.followedTransactions).join([
      leftOuterJoin(
        _database.transactions,
        _database.transactions.id.equalsExp(
          _database.followedTransactions.transactionId,
        ),
      ),
      leftOuterJoin(
        _database.counterparties,
        _database.counterparties.id.equalsExp(
          _database.transactions.counterpartyId,
        ),
      ),
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

  /// Récupère les IDs des transactions suivies
  Future<List<int>> getFollowedTransactionIds() async {
    final results = await _database
        .select(_database.followedTransactions)
        .get();
    return results.map((ft) => ft.transactionId).toList();
  }

  /// Récupère toutes les transactions suivies (entités simples)
  Future<List<FollowedTransaction>> getFollowedTransactions() async {
    return await (_database.select(
      _database.followedTransactions,
    )..orderBy([(ft) => OrderingTerm.desc(ft.followedDate)])).get();
  }

  /// Récupère le nombre de transactions suivies
  Future<int> getFollowedTransactionCount() async {
    final results = await _database
        .select(_database.followedTransactions)
        .get();
    return results.length;
  }

  /// Récupère les transactions suivies pour un compte spécifique
  Future<List<TransactionWithCounterparty>> getFollowedTransactionsByAccount(
    int accountId,
  ) async {
    final query = _database.select(_database.followedTransactions).join([
      innerJoin(
        _database.transactions,
        _database.transactions.id.equalsExp(
              _database.followedTransactions.transactionId,
            ) &
            _database.transactions.accountId.equals(accountId),
      ),
      leftOuterJoin(
        _database.counterparties,
        _database.counterparties.id.equalsExp(
          _database.transactions.counterpartyId,
        ),
      ),
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

  /// Supprime toutes les transactions suivies
  Future<int> clearAllFollowedTransactions() async {
    return await _database.delete(_database.followedTransactions).go();
  }

  /// Récupère les transactions suivies les plus récentes
  Future<List<TransactionWithCounterparty>> getRecentFollowedTransactions({
    int limit = 10,
  }) async {
    final query =
        _database.select(_database.followedTransactions).join([
            leftOuterJoin(
              _database.transactions,
              _database.transactions.id.equalsExp(
                _database.followedTransactions.transactionId,
              ),
            ),
            leftOuterJoin(
              _database.counterparties,
              _database.counterparties.id.equalsExp(
                _database.transactions.counterpartyId,
              ),
            ),
          ])
          ..orderBy([
            OrderingTerm.desc(_database.followedTransactions.followedDate),
          ])
          ..limit(limit);

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
}
