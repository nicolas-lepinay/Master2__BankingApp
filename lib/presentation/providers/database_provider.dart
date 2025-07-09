import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:bankapp/data/database/database.dart';

// Provider pour l'instance de la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Provider pour l'utilisateur actuel
final currentUserProvider = FutureProvider<User>((ref) async {
  final database = ref.read(databaseProvider);
  return database.getCurrentUser();
});

// Provider pour les comptes
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.select(database.accounts).get();
});

// Provider pour un compte spécifique avec son résumé
final accountSummaryProvider = FutureProvider.family<AccountSummary, int>((
  ref,
  accountId,
) async {
  final database = ref.read(databaseProvider);
  return database.getAccountSummary(accountId);
});

// Provider pour les transactions avec solde d'un compte
final transactionsWithBalanceProvider =
    FutureProvider.family<List<TransactionWithBalance>, int>((
      ref,
      accountId,
    ) async {
      final database = ref.read(databaseProvider);
      return database.getTransactionsWithBalance(accountId);
    });

// Provider pour une transaction spécifique
final transactionProvider = FutureProvider.family<Transaction, int>((
  ref,
  transactionId,
) async {
  final database = ref.read(databaseProvider);
  return (database.select(
    database.transactions,
  )..where((t) => t.id.equals(transactionId))).getSingle();
});

// Provider pour les catégories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.select(database.categories).get();
});

// Provider pour une transaction spécifique avec son tiers
final transactionWithCounterpartyProvider =
    FutureProvider.family<TransactionWithCounterparty?, int>((
      ref,
      transactionId,
    ) async {
      final database = ref.read(databaseProvider);

      final query = database.select(database.transactions).join([
        leftOuterJoin(
          database.counterparties,
          database.counterparties.id.equalsExp(
            database.transactions.counterpartyId,
          ),
        ),
      ])..where(database.transactions.id.equals(transactionId));

      final result = await query.getSingleOrNull();

      if (result == null) return null;

      final transaction = result.readTable(database.transactions);
      final counterparty = result.readTableOrNull(database.counterparties);

      return TransactionWithCounterparty(
        transaction: transaction,
        counterparty: counterparty,
      );
    });

// Provider pour les tiers
final counterpartiesProvider = FutureProvider<List<Counterparty>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.select(database.counterparties).get();
});

// =====================================================
// PROVIDERS POUR LES TRANSACTIONS SUIVIES
// =====================================================

/// Provider pour récupérer toutes les transactions suivies avec leurs détails
final followedTransactionsProvider =
    FutureProvider<List<TransactionWithCounterparty>>((ref) async {
      final database = ref.read(databaseProvider);
      return database.getFollowedTransactionsWithDetails();
    });

/// Provider pour récupérer seulement les IDs des transactions suivies
final followedTransactionIdsProvider = FutureProvider<List<int>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.getFollowedTransactionIds();
});

/// Provider pour vérifier si une transaction spécifique est suivie
final isTransactionFollowedProvider = FutureProvider.family<bool, int>((
  ref,
  transactionId,
) async {
  final database = ref.read(databaseProvider);
  return database.isTransactionFollowed(transactionId);
});

/// Provider pour les transactions suivies (entités Transaction simples)
final followedTransactionsSimpleProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final database = ref.read(databaseProvider);
  return database.getFollowedTransactions();
});
