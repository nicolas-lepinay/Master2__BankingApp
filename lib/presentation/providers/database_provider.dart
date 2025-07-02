import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bankapp/data/database/database.dart';

// Provider pour l'instance de la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
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

// Provider pour les tiers
final counterpartiesProvider = FutureProvider<List<Counterparty>>((ref) async {
  final database = ref.read(databaseProvider);
  return database.select(database.counterparties).get();
});
