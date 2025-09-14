import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/services/brandfetch_service.dart';
import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/core/services/firebase_functions_service.dart';
import 'package:bankapp/core/services/image_download_service.dart';
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

final brandfetchServiceProvider = Provider<BrandfetchService>((ref) {
  return BrandfetchService();
});

final imageDownloadServiceProvider = Provider<ImageDownloadService>((ref) {
  return ImageDownloadService();
});

final imageDownloadRepositoryProvider = Provider<ImageDownloadRepository>((
  ref,
) {
  return ImageDownloadRepositoryImpl(
    ref.watch(imageDownloadServiceProvider),
    ref.watch(counterpartyRepositoryProvider),
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



final counterpartyViewModelProvider =
    StateNotifierProvider<CounterpartyViewModel, CounterpartyViewState>((ref) {
      return CounterpartyViewModel(ref.watch(counterpartyRepositoryProvider));
    });

final searchViewModelProvider =
    StateNotifierProvider<SearchResultsViewModel, SearchResultsViewState>((
      ref,
    ) {
      return SearchResultsViewModel(
        ref.watch(transactionRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
        ref.watch(counterpartyRepositoryProvider),
      );
    });

final currencyViewModelProvider =
    StateNotifierProvider<CurrencyViewModel, CurrencyViewState>((ref) {
      return CurrencyViewModel(ref.watch(currencyConversionServiceProvider));
    });

final followedTransactionViewModelProvider =
    StateNotifierProvider<
      FollowedTransactionViewModel,
      FollowedTransactionViewState
    >((ref) {
      return FollowedTransactionViewModel(
        ref.watch(transactionRepositoryProvider),
      );
    });

final logoSearchViewModelProvider =
    StateNotifierProvider<LogoSearchViewModel, LogoSearchViewState>((ref) {
      return LogoSearchViewModel(
        brandfetchService: ref.watch(brandfetchServiceProvider),
      );
    });

/// Provider pour TransactionCreationViewModel avec WidgetRef
/// Utilise .family pour passer le WidgetRef nécessaire à l'invalidation des providers
final transactionCreationViewModelProvider =
    StateNotifierProvider.family<
      TransactionCreationViewModel,
      TransactionCreationViewState,
      WidgetRef
    >((ref, widgetRef) {
      return TransactionCreationViewModel(
        ref.watch(transactionRepositoryProvider),
        ref.watch(counterpartyRepositoryProvider),
        ref.watch(imageDownloadRepositoryProvider),
        widgetRef, // 🆕 Passer le WidgetRef pour l'invalidation
      );
    });

/// Provider pour TransactionListViewModel - nouveau ViewModel par écran
/// Utilise l'Event Bus pour la communication découplée
final transactionListViewModelProvider =
    StateNotifierProvider<TransactionListViewModel, TransactionListViewState>((
      ref,
    ) {
      return TransactionListViewModel(ref.watch(transactionRepositoryProvider));
    });

/// Provider pour HomeScreenViewModel - ViewModel pour l'écran d'accueil
/// Gère les comptes, messages de bienvenue et états d'animation
final homeScreenViewModelProvider =
    StateNotifierProvider<HomeScreenViewModel, HomeScreenViewState>((ref) {
      return HomeScreenViewModel(ref.watch(accountRepositoryProvider));
    });

/// Provider pour TransactionDetailViewModel - ViewModel pour l'écran de détail d'une transaction
/// Utilise .family pour passer l'ID de la transaction nécessaire au ViewModel
final transactionDetailViewModelProvider =
    StateNotifierProvider.family<
      TransactionDetailViewModel,
      TransactionDetailViewState,
      int
    >((ref, transactionId) {
      return TransactionDetailViewModel(
        transactionId,
        ref.watch(transactionRepositoryProvider),
        ref.watch(accountRepositoryProvider),
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

// ============================================================================
// FAMILY PROVIDERS (avec paramètres)
// ============================================================================


/// Provider réactif pour obtenir l'AccountSummary d'un compte spécifique
/// Se met à jour automatiquement via les événements Event Bus
final accountSummaryByIdProvider =
    FutureProvider.family<domain.AccountSummary, int>((ref, accountId) async {
      // 🔥 Écouter les événements Event Bus pour invalider automatiquement
      final eventBus = AppEventBus.instance;
      
      // S'abonner aux événements de transaction pour ce compte
      final subscription = eventBus.transactionEvents
          .where((event) => event.accountId == accountId)
          .listen((_) {
        // Invalider ce provider quand une transaction change pour ce compte
        ref.invalidateSelf();
      });
      
      // Cleanup de la souscription
      ref.onDispose(() {
        subscription.cancel();
      });
      
      final accountRepository = ref.watch(accountRepositoryProvider);
      return accountRepository.getAccountSummary(accountId);
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



// ============================================================================
// FEATURE VIEWMODELS PROVIDERS - Par fonctionnalité spécifique
// ============================================================================

/// Provider pour le TransactionEditViewModel
/// Utilise un provider.family pour accepter l'ID de la transaction
final transactionEditViewModelProvider =
    StateNotifierProvider.family<
      TransactionEditViewModel,
      TransactionEditViewState,
      int
    >((ref, transactionId) {
      return TransactionEditViewModel(
        transactionId,
        ref.watch(transactionRepositoryProvider),
      );
    });

/// Provider pour le TransactionDeletionViewModel
/// Utilise un provider.family pour accepter l'ID de la transaction
final transactionDeletionViewModelProvider =
    StateNotifierProvider.family<
      TransactionDeletionViewModel,
      TransactionDeletionViewState,
      int
    >((ref, transactionId) {
      return TransactionDeletionViewModel(
        transactionId,
        ref.watch(transactionRepositoryProvider),
      );
    });

/// Provider pour le AccountManagementViewModel
/// ViewModel pour la gestion CRUD des comptes
final accountManagementViewModelProvider = StateNotifierProvider<
    AccountManagementViewModel,
    AccountManagementViewState
>((ref) {
  return AccountManagementViewModel(
    ref.watch(accountRepositoryProvider),
    ref.watch(smartExchangeRateServiceProvider),
  );
});
