import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/repositories/repositories.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/providers/database_provider.dart';
import 'package:bankapp/presentation/viewmodels/viewmodels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// DATASOURCES PROVIDERS
// ============================================================================

final accountLocalDataSourceProvider = Provider<AccountLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return AccountLocalDataSourceImpl(database);
});

final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>(
  (ref) {
    final database = ref.watch(databaseProvider);
    return TransactionLocalDataSourceImpl(database);
  },
);

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  return CategoryLocalDataSourceImpl(database);
});

final counterpartyLocalDataSourceProvider =
    Provider<CounterpartyLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return CounterpartyLocalDataSourceImpl(database);
    });

// ============================================================================
// SERVICES PROVIDERS
// ============================================================================

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager.instance;
});

final userPreferencesServiceProvider = Provider<UserPreferencesService>((ref) {
  return UserPreferencesService.instance;
});

// ============================================================================
// REPOSITORIES PROVIDERS
// ============================================================================

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    ref.watch(accountLocalDataSourceProvider),
    ref.watch(cacheManagerProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(transactionLocalDataSourceProvider),
    ref.watch(cacheManagerProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    ref.watch(categoryLocalDataSourceProvider),
    ref.watch(cacheManagerProvider),
  );
});

final counterpartyRepositoryProvider = Provider<CounterpartyRepository>((ref) {
  return CounterpartyRepositoryImpl(
    ref.watch(counterpartyLocalDataSourceProvider),
    ref.watch(cacheManagerProvider),
  );
});

// ============================================================================
// VIEWMODELS PROVIDERS
// ============================================================================

final appViewModelProvider = StateNotifierProvider<AppViewModel, AppViewState>((
  ref,
) {
  return AppViewModel(
    ref.watch(cacheManagerProvider),
    ref.watch(accountLocalDataSourceProvider),
    ref.watch(transactionLocalDataSourceProvider),
    ref.watch(categoryLocalDataSourceProvider),
    ref.watch(counterpartyLocalDataSourceProvider),
    ref.watch(userPreferencesServiceProvider),
  );
});

final accountViewModelProvider =
    StateNotifierProvider<AccountViewModel, AccountViewState>((ref) {
      return AccountViewModel(ref.watch(accountRepositoryProvider));
    });

final transactionViewModelProvider =
    StateNotifierProvider<TransactionViewModel, TransactionViewState>((ref) {
      return TransactionViewModel(ref.watch(transactionRepositoryProvider));
    });

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchViewState>((ref) {
      return SearchViewModel(
        ref.watch(transactionRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
        ref.watch(counterpartyRepositoryProvider),
      );
    });

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

/// Provider pour l'état d'initialisation de l'application
final appInitializationProvider = Provider<bool>((ref) {
  final appState = ref.watch(appViewModelProvider);
  return appState.isInitialized;
});

/// Provider pour l'état de chargement de l'application
final appLoadingProvider = Provider<bool>((ref) {
  final appState = ref.watch(appViewModelProvider);
  return appState.isLoading;
});

/// Provider pour les erreurs de l'application
final appErrorProvider = Provider<String?>((ref) {
  final appState = ref.watch(appViewModelProvider);
  return appState.error;
});

/// Provider pour le nom d'utilisateur
final userNameProvider = Provider<String?>((ref) {
  final appState = ref.watch(appViewModelProvider);
  return appState.userName;
});

/// Provider pour le message de bienvenue
final welcomeMessageProvider = Provider<String>((ref) {
  final appState = ref.watch(appViewModelProvider);
  return appState.welcomeMessage;
});

/// Provider pour les comptes
final accountsProvider = Provider<List<domain.Account>>((ref) {
  final accountState = ref.watch(accountViewModelProvider);
  return accountState.accounts;
});

/// Provider pour le compte sélectionné
final selectedAccountProvider = Provider<domain.Account?>((ref) {
  final accountState = ref.watch(accountViewModelProvider);
  return accountState.selectedAccount;
});

/// Provider pour le résumé du compte sélectionné
final selectedAccountSummaryProvider = Provider<domain.AccountSummary?>((ref) {
  final accountState = ref.watch(accountViewModelProvider);
  return accountState.selectedAccountSummary;
});

/// Provider pour les transactions filtrées
final filteredTransactionsProvider =
    Provider<List<domain.TransactionWithBalance>>((ref) {
      final transactionState = ref.watch(transactionViewModelProvider);
      return transactionState.filteredTransactions;
    });

/// Provider pour les transactions paginées
final paginatedTransactionsProvider =
    Provider<List<domain.TransactionWithBalance>>((ref) {
      final transactionState = ref.watch(transactionViewModelProvider);
      return transactionState.paginatedTransactions;
    });

/// Provider pour les résultats de recherche
final searchResultsProvider = Provider<List<domain.TransactionWithBalance>>((
  ref,
) {
  final searchState = ref.watch(searchViewModelProvider);
  return searchState.searchResults;
});

/// Provider pour les résultats de recherche paginés
final paginatedSearchResultsProvider =
    Provider<List<domain.TransactionWithBalance>>((ref) {
      final searchState = ref.watch(searchViewModelProvider);
      return searchState.paginatedResults;
    });

// ============================================================================
// FAMILY PROVIDERS (avec paramètres)
// ============================================================================

/// Provider pour charger les transactions d'un compte spécifique
final accountTransactionsProvider =
    FutureProvider.family<List<domain.TransactionWithBalance>, int>((
      ref,
      accountId,
    ) async {
      final transactionViewModel = ref.watch(
        transactionViewModelProvider.notifier,
      );
      await transactionViewModel.loadTransactions(accountId);
      return ref.watch(filteredTransactionsProvider);
    });

/// Provider pour obtenir un compte par ID
final accountByIdProvider = Provider.family<domain.Account?, int>((
  ref,
  accountId,
) {
  final accountViewModel = ref.watch(accountViewModelProvider.notifier);
  return accountViewModel.getAccountById(accountId);
});

/// Provider pour obtenir une transaction par ID
final transactionByIdProvider =
    Provider.family<domain.TransactionWithBalance?, int>((ref, transactionId) {
      final transactionViewModel = ref.watch(
        transactionViewModelProvider.notifier,
      );
      return transactionViewModel.getTransactionById(transactionId);
    });

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

/// Provider pour le solde actuel du compte sélectionné
final currentBalanceProvider = Provider<double?>((ref) {
  final accountViewModel = ref.watch(accountViewModelProvider.notifier);
  return accountViewModel.currentBalance;
});

/// Provider pour le total des revenus filtrés
final filteredIncomeTotalProvider = Provider<double>((ref) {
  final transactionViewModel = ref.watch(transactionViewModelProvider.notifier);
  return transactionViewModel.filteredIncomeTotal;
});

/// Provider pour le total des dépenses filtrées
final filteredExpenseTotalProvider = Provider<double>((ref) {
  final transactionViewModel = ref.watch(transactionViewModelProvider.notifier);
  return transactionViewModel.filteredExpenseTotal;
});

/// Provider pour le montant net filtré
final filteredNetAmountProvider = Provider<double>((ref) {
  final transactionViewModel = ref.watch(transactionViewModelProvider.notifier);
  return transactionViewModel.filteredNetAmount;
});

/// Provider pour les statistiques de l'application
final appStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final appViewModel = ref.watch(appViewModelProvider.notifier);
  return appViewModel.getAppStats();
});

/// Provider pour les statistiques de recherche
final searchStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final searchViewModel = ref.watch(searchViewModelProvider.notifier);
  return searchViewModel.getSearchStats();
});

// ============================================================================
// UTILITY PROVIDERS
// ============================================================================

/// Provider pour savoir si l'application est prête
final isAppReadyProvider = Provider<bool>((ref) {
  final appViewModel = ref.watch(appViewModelProvider.notifier);
  return appViewModel.isAppReady;
});

/// Provider pour obtenir les transactions récentes
final recentTransactionsProvider =
    Provider<List<domain.TransactionWithBalance>>((ref) {
      final accountViewModel = ref.watch(accountViewModelProvider.notifier);
      return accountViewModel.recentTransactions;
    });

/// Provider pour obtenir les suggestions de recherche
final searchSuggestionsProvider = Provider.family<List<String>, String>((
  ref,
  query,
) {
  final searchViewModel = ref.watch(searchViewModelProvider.notifier);
  return searchViewModel.getSearchSuggestions(query);
});

// ============================================================================
// FOLLOWED TRANSACTIONS PROVIDERS
// ============================================================================
/*
/// Provider pour les transactions suivies (MVVM version)
final followedTransactionsProvider = FutureProvider<List<domain.TransactionWithBalance>>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getFollowedTransactionsWithDetails();
});

/// Provider pour les IDs des transactions suivies
final followedTransactionIdsProvider = FutureProvider<List<int>>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getFollowedTransactionIds();
});

/// Provider pour vérifier si une transaction est suivie
final isTransactionFollowedProvider = FutureProvider.family<bool, int>((ref, transactionId) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.isTransactionFollowed(transactionId);
});

// ============================================================================
// TRANSACTION WITH COUNTERPARTY PROVIDERS
// ============================================================================

/// Provider pour une transaction avec son tiers (MVVM version)
final transactionWithCounterpartyProvider = FutureProvider.family<domain.TransactionWithBalance?, int>((ref, transactionId) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final counterpartyRepository = ref.watch(counterpartyRepositoryProvider);
  
  final transaction = await transactionRepository.getTransactionById(transactionId);
  if (transaction == null) return null;
  
  // Le TransactionWithBalance contient déjà les informations de counterparty
  return transaction;
});
*/
