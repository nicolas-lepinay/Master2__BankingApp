import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/data/database/models/models.dart';
import 'package:bankapp/data/repositories/database/database_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour l'instance de la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Providers pour les repositories de base de données
final userDatabaseRepositoryProvider = Provider<UserDatabaseRepository>((ref) {
  final database = ref.read(databaseProvider);
  return UserDatabaseRepository(database);
});

final accountDatabaseRepositoryProvider = Provider<AccountDatabaseRepository>((
  ref,
) {
  final database = ref.read(databaseProvider);
  return AccountDatabaseRepository(database);
});

final counterpartyDatabaseRepositoryProvider =
    Provider<CounterpartyDatabaseRepository>((ref) {
      final database = ref.read(databaseProvider);
      return CounterpartyDatabaseRepository(database);
    });

final transactionDatabaseRepositoryProvider =
    Provider<TransactionDatabaseRepository>((ref) {
      final database = ref.read(databaseProvider);
      return TransactionDatabaseRepository(database);
    });

final followedTransactionDatabaseRepositoryProvider =
    Provider<FollowedTransactionDatabaseRepository>((ref) {
      final database = ref.read(databaseProvider);
      return FollowedTransactionDatabaseRepository(database);
    });

// Provider pour l'utilisateur actuel
final currentUserProvider = FutureProvider<User>((ref) async {
  final userRepository = ref.read(userDatabaseRepositoryProvider);
  return userRepository.getCurrentUser();
});

// Provider pour les comptes
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final accountRepository = ref.read(accountDatabaseRepositoryProvider);
  return accountRepository.getAllAccounts();
});

// Provider pour un compte spécifique avec son résumé
final accountSummaryProvider = FutureProvider.family<AccountSummary, int>((
  ref,
  accountId,
) async {
  final accountRepository = ref.read(accountDatabaseRepositoryProvider);
  return accountRepository.getAccountSummary(accountId);
});

// Provider pour les transactions avec solde d'un compte
final transactionsWithBalanceProvider =
    FutureProvider.family<List<TransactionWithBalance>, int>((
      ref,
      accountId,
    ) async {
      final accountRepository = ref.read(accountDatabaseRepositoryProvider);
      return accountRepository.getTransactionsWithBalance(accountId);
    });

// Provider pour une transaction spécifique
final transactionProvider = FutureProvider.family<Transaction?, int>((
  ref,
  transactionId,
) async {
  final transactionRepository = ref.read(transactionDatabaseRepositoryProvider);
  return transactionRepository.getTransactionById(transactionId);
});

// Provider pour une transaction spécifique avec son tiers
final transactionWithCounterpartyProvider =
    FutureProvider.family<TransactionWithCounterparty?, int>((
      ref,
      transactionId,
    ) async {
      final transactionRepository = ref.read(
        transactionDatabaseRepositoryProvider,
      );
      final transaction = await transactionRepository.getTransactionById(
        transactionId,
      );

      if (transaction == null) return null;

      String? counterpartyName;
      String? counterpartyIcon;

      if (transaction.counterpartyId != null) {
        final counterpartyRepository = ref.read(
          counterpartyDatabaseRepositoryProvider,
        );
        final counterparty = await counterpartyRepository.getCounterpartyById(
          transaction.counterpartyId!,
        );
        counterpartyName = counterparty?.name;
        counterpartyIcon = counterparty?.icon;
      }

      return TransactionWithCounterparty(
        transaction: transaction,
        counterpartyName: counterpartyName,
        counterpartyIcon: counterpartyIcon,
      );
    });

// Provider pour les tiers
final counterpartiesProvider = FutureProvider<List<Counterparty>>((ref) async {
  final counterpartyRepository = ref.read(
    counterpartyDatabaseRepositoryProvider,
  );
  return counterpartyRepository.getAllCounterparties();
});

/// Provider pour récupérer toutes les transactions suivies avec leurs détails
final followedTransactionsProvider =
    FutureProvider<List<TransactionWithCounterparty>>((ref) async {
      final followedRepository = ref.read(
        followedTransactionDatabaseRepositoryProvider,
      );
      return followedRepository.getFollowedTransactionsWithDetails();
    });

/// Provider pour récupérer seulement les IDs des transactions suivies
final followedTransactionIdsProvider = FutureProvider<List<int>>((ref) async {
  final followedRepository = ref.read(
    followedTransactionDatabaseRepositoryProvider,
  );
  return followedRepository.getFollowedTransactionIds();
});

/// Provider pour vérifier si une transaction spécifique est suivie
final isTransactionFollowedProvider = FutureProvider.family<bool, int>((
  ref,
  transactionId,
) async {
  final followedRepository = ref.read(
    followedTransactionDatabaseRepositoryProvider,
  );
  return followedRepository.isTransactionFollowed(transactionId);
});

/// Provider pour les transactions suivies (entités Transaction simples)
final followedTransactionsSimpleProvider =
    FutureProvider<List<FollowedTransaction>>((ref) async {
      final followedRepository = ref.read(
        followedTransactionDatabaseRepositoryProvider,
      );
      return followedRepository.getFollowedTransactions();
    });

/// Provider pour récupérer les transactions centrées autour d'aujourd'hui
final transactionsAroundTodayProvider =
    FutureProvider.family<List<TransactionWithCounterparty>, int>((
      ref,
      accountId,
    ) async {
      final transactionRepository = ref.read(
        transactionDatabaseRepositoryProvider,
      );
      return transactionRepository.getTransactionsAroundToday(accountId);
    });
