import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/core/services/firebase_functions_service.dart';
import 'package:bankapp/core/services/smart_exchange_rate_service.dart';
import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/data/datasources/remote/exchange_rate_remote_datasource.dart';
import 'package:bankapp/data/repositories/database/followed_transaction_database_repository.dart';
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

final followedTransactionDatabaseRepositoryProvider =
    Provider<FollowedTransactionDatabaseRepository>((ref) {
      final database = ref.watch(databaseProvider);
      return FollowedTransactionDatabaseRepository(database);
    });

final exchangeRateLocalDataSourceProvider =
    Provider<ExchangeRateLocalDataSource>((ref) {
      final database = ref.watch(databaseProvider);
      return ExchangeRateLocalDataSourceImpl(database);
    });

final firebaseFunctionsServiceProvider = Provider<FirebaseFunctionsService>((
  ref,
) {
  return FirebaseFunctionsService();
});

final exchangeRateRemoteDataSourceProvider =
    Provider<ExchangeRateRemoteDataSource>((ref) {
      return ExchangeRateRemoteDataSourceImpl(
        firebaseFunctionsService: ref.watch(firebaseFunctionsServiceProvider),
      );
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
    ref.watch(followedTransactionDatabaseRepositoryProvider),
    ref.watch(accountLocalDataSourceProvider),
    ref.watch(counterpartyLocalDataSourceProvider),
    ref.watch(categoryLocalDataSourceProvider),
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

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepositoryImpl(
    ref.watch(exchangeRateLocalDataSourceProvider),
    ref.watch(exchangeRateRemoteDataSourceProvider),
  );
});

final currencyConversionServiceProvider = Provider<CurrencyConversionService>((
  ref,
) {
  return CurrencyConversionService(
    ref.watch(cacheManagerProvider),
    ref.watch(exchangeRateRepositoryProvider),
  );
});

final smartExchangeRateServiceProvider = Provider<SmartExchangeRateService>((
  ref,
) {
  return SmartExchangeRateService(
    ref.watch(cacheManagerProvider),
    ref.watch(exchangeRateRepositoryProvider),
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
    ref.watch(exchangeRateRepositoryProvider),
    ref.watch(smartExchangeRateServiceProvider),
  );
});

final accountViewModelProvider =
    StateNotifierProvider<AccountViewModel, AccountViewState>((ref) {
      return AccountViewModel(
        ref.watch(accountRepositoryProvider),
        ref.watch(smartExchangeRateServiceProvider),
      );
    });

final transactionViewModelProvider =
    StateNotifierProvider<TransactionViewModel, TransactionViewState>((ref) {
      return TransactionViewModel(
        ref.watch(transactionRepositoryProvider),
        ref,
      );
    });

final counterpartyViewModelProvider =
    StateNotifierProvider<CounterpartyViewModel, CounterpartyViewState>((ref) {
      return CounterpartyViewModel(ref.watch(counterpartyRepositoryProvider));
    });

final searchViewModelProvider =
    StateNotifierProvider<SearchViewModel, SearchViewState>((ref) {
      return SearchViewModel(
        ref.watch(transactionRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
        ref.watch(counterpartyRepositoryProvider),
      );
    });

final currencyViewModelProvider =
    StateNotifierProvider<CurrencyViewModel, CurrencyViewState>((ref) {
      return CurrencyViewModel(ref.watch(currencyConversionServiceProvider));
    });

final followedTransactionViewModelProvider = StateNotifierProvider<
    FollowedTransactionViewModel, FollowedTransactionViewState>((ref) {
  return FollowedTransactionViewModel(
    ref.watch(transactionRepositoryProvider),
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

/// Provider pour les contreparties
final counterpartiesProvider = Provider<List<domain.Counterparty>>((ref) {
  final counterpartyState = ref.watch(counterpartyViewModelProvider);
  return counterpartyState.counterparties;
});

/// Provider pour la contrepartie sélectionnée
final selectedCounterpartyProvider = Provider<domain.Counterparty?>((ref) {
  final counterpartyState = ref.watch(counterpartyViewModelProvider);
  return counterpartyState.selectedCounterparty;
});

/// Provider pour les transactions suivies
final followedTransactionsListProvider = Provider<List<domain.TransactionWithBalance>>((ref) {
  final followedState = ref.watch(followedTransactionViewModelProvider);
  return followedState.followedTransactions;
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

/// Provider pour obtenir l'AccountSummary d'un compte spécifique
final accountSummaryByIdProvider =
    FutureProvider.family<domain.AccountSummary, int>((ref, accountId) async {
      final accountRepository = ref.watch(accountRepositoryProvider);
      return accountRepository.getAccountSummary(accountId);
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

/// Provider pour les transactions suivies (MVVM version)
final followedTransactionsProvider =
    FutureProvider<List<domain.TransactionWithBalance>>((ref) async {
      final transactionRepository = ref.watch(transactionRepositoryProvider);
      return transactionRepository.getFollowedTransactionsWithDetails();
    });

/// Provider pour les IDs des transactions suivies
final followedTransactionIdsProvider = FutureProvider<List<int>>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.getFollowedTransactionIds();
});

/// Provider pour vérifier si une transaction est suivie
final isTransactionFollowedProvider = FutureProvider.family<bool, int>((
  ref,
  transactionId,
) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return transactionRepository.isTransactionFollowed(transactionId);
});

// ============================================================================
// TRANSACTION WITH COUNTERPARTY PROVIDERS
// ============================================================================

// ============================================================================
// INVALIDATION HELPERS
// ============================================================================

/// Invalide tous les providers liés aux comptes et leurs résumés
void invalidateAccountProviders(Ref ref) {
  // Invalider les providers des comptes
  ref.invalidate(accountViewModelProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(selectedAccountProvider);
  ref.invalidate(selectedAccountSummaryProvider);

  // Invalider les providers d'account summary (tous les ID)
  ref.invalidate(accountSummaryByIdProvider);
}

/// Invalide tous les providers liés aux transactions
void invalidateTransactionProviders(Ref ref) {
  // Invalider les providers des transactions
  ref.invalidate(transactionViewModelProvider);
  ref.invalidate(filteredTransactionsProvider);
  ref.invalidate(paginatedTransactionsProvider);

  // Invalider aussi les résumés de comptes car ils dépendent des transactions
  invalidateAccountProviders(ref);
}

// Provider supprimé car inutilisé et remplacé par l'architecture MVVM des repositories
