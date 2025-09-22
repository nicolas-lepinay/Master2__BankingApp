import 'package:bankapp/core/services/smart_exchange_rate_service.dart';
import 'package:bankapp/core/services/user_preferences_service.dart';
import 'package:bankapp/core/utils/app_logger.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/data/datasources/local/local_datasources.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';

/// États de l'application
enum AppInitializationState {
  initial,
  loadingCache,
  loadingUserPreferences,
  checkingFirstLaunch,
  initialized,
  error,
}

/// État de l'application
class AppViewState extends BaseViewState {
  final AppInitializationState initializationState;
  final bool isFirstLaunch;
  final String? userName;
  final double initializationProgress;
  final String? currentStep;
  final String? error;

  const AppViewState({
    this.initializationState = AppInitializationState.initial,
    this.isFirstLaunch = true,
    this.userName,
    this.initializationProgress = 0.0,
    this.currentStep,
    this.error,
  });

  AppViewState copyWith({
    AppInitializationState? initializationState,
    bool? isFirstLaunch,
    String? userName,
    double? initializationProgress,
    String? currentStep,
    String? error,
  }) {
    return AppViewState(
      initializationState: initializationState ?? this.initializationState,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      userName: userName ?? this.userName,
      initializationProgress:
          initializationProgress ?? this.initializationProgress,
      currentStep: currentStep ?? this.currentStep,
      error: error ?? this.error,
    );
  }

  AppViewState loading(String step, double progress) {
    return copyWith(
      currentStep: step,
      initializationProgress: progress,
      error: null,
    );
  }

  AppViewState success({
    AppInitializationState? initializationState,
    bool? isFirstLaunch,
    String? userName,
  }) {
    return AppViewState(
      initializationState: initializationState ?? this.initializationState,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      userName: userName ?? this.userName,
      initializationProgress: 1.0,
      currentStep: null,
      error: null,
    );
  }

  AppViewState failure(String errorMessage) {
    return copyWith(
      initializationState: AppInitializationState.error,
      error: errorMessage,
    );
  }

  bool get isInitialized =>
      initializationState == AppInitializationState.initialized;
  bool get isLoading =>
      initializationState != AppInitializationState.initialized &&
      initializationState != AppInitializationState.error;
  bool get hasError => error != null;
  bool get hasUserName => userName != null && userName!.isNotEmpty;

  String get welcomeMessage =>
      hasUserName ? 'Bonjour, $userName !' : 'Bonjour !';

  @override
  String toString() =>
      'AppViewState(initializationState: $initializationState, isFirstLaunch: $isFirstLaunch, userName: $userName, progress: $initializationProgress, error: $error)';
}

/// ViewModel principal de l'application
class AppViewModel extends BaseViewModel<AppViewState> {
  final CacheManager _cacheManager;
  final AccountLocalDataSource _accountDataSource;
  final TransactionLocalDataSource _transactionDataSource;
  final CategoryLocalDataSource _categoryDataSource;
  final CounterpartyLocalDataSource _counterpartyDataSource;
  final UserPreferencesService _userPreferencesService;
  final ExchangeRateRepository? _exchangeRateRepository;
  final SmartExchangeRateService? _smartExchangeRateService;

  AppViewModel(
    this._cacheManager,
    this._accountDataSource,
    this._transactionDataSource,
    this._categoryDataSource,
    this._counterpartyDataSource,
    this._userPreferencesService,
    this._exchangeRateRepository,
    this._smartExchangeRateService,
  ) : super(const AppViewState());

  /// Initialise l'application
  Future<void> initializeApp() async {
    await executeWithErrorHandling(() async {
      // Étape 1 : Vérifier le premier lancement
      state = state.copyWith(
        initializationState: AppInitializationState.checkingFirstLaunch,
      );
      state = state.loading('Vérification du premier lancement...', 0.1);

      await _userPreferencesService.init();
      final isFirstLaunch = _userPreferencesService.isFirstLaunch();
      final userName = _userPreferencesService.getUserName();

      state = state.copyWith(isFirstLaunch: isFirstLaunch, userName: userName);

      // Étape 2 : Charger les préférences utilisateur
      state = state.copyWith(
        initializationState: AppInitializationState.loadingUserPreferences,
      );
      state = state.loading('Chargement des préférences utilisateur...', 0.2);

      // Attendre un peu pour montrer le progress
      await Future.delayed(const Duration(milliseconds: 500));

      // Étape 3 : Initialiser le cache
      state = state.copyWith(
        initializationState: AppInitializationState.loadingCache,
      );
      state = state.loading('Chargement des données...', 0.3);

      if (!_cacheManager.isInitialized) {
        await _initializeCache();
      }

      // Étape 4 : Gestion intelligente des taux de change
      if (_smartExchangeRateService != null) {
        state = state.loading('Synchronisation des taux de change...', 0.85);
        await _smartLoadExchangeRates();
      }

      // Étape 5 : Finalisation
      state = state.loading('Finalisation...', 0.9);
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.success(
        initializationState: AppInitializationState.initialized,
        isFirstLaunch: isFirstLaunch,
        userName: userName,
      );
    });
  }

  /// Initialise le cache avec toutes les données
  Future<void> _initializeCache() async {
    // Charger les comptes
    state = state.loading('Chargement des comptes...', 0.4);
    final accounts = await _accountDataSource.getAllAccounts();

    // Charger les transactions
    state = state.loading('Chargement des transactions...', 0.5);
    final transactions = await _transactionDataSource.getAllTransactions();

    // Charger les catégories
    state = state.loading('Chargement des catégories...', 0.6);
    final categories = await _categoryDataSource.getAllCategories();

    // Charger les contreparties
    state = state.loading('Chargement des contreparties...', 0.7);
    final counterparties = await _counterpartyDataSource.getAllCounterparties();

    // Charger les IDs des transactions suivies
    state = state.loading('Chargement des transactions suivies...', 0.75);
    final followedTransactionIds = await _transactionDataSource
        .getFollowedTransactionIds();

    // Initialiser le cache
    state = state.loading('Initialisation du cache...', 0.8);
    await _cacheManager.initialize(
      accounts: accounts,
      transactions: transactions,
      categories: categories,
      counterparties: counterparties,
      followedTransactionIds: followedTransactionIds,
      exchangeRateRepository: _exchangeRateRepository,
    );
  }

  /// Gestion intelligente des taux de change au démarrage
  Future<void> _smartLoadExchangeRates() async {
    if (_smartExchangeRateService == null) return;

    try {
      final service = _smartExchangeRateService;

      if (service.isCacheEmpty()) {
        // Cas 1 : Cache vide → Charger devise locale
        state = state.loading('Détection de votre devise locale...', 0.86);
        final result = await service.initializeEmptyCache();

        if (result.success) {
          // Cache initialisé avec la devise locale
          AppLogger.info(
            'AppViewState',
            '_smartLoadExchangeRates',
            '✅ Exchange rates cache was empty → it has been populated with user\'s local currency.',
          );
        } else {
          // Échec non-bloquant : l'app continue de fonctionner
        }
      } else {
        // Cas 2 : Cache existant → Mise à jour sélective des taux expirés
        state = state.loading('Mise à jour des taux expirés...', 0.87);
        final result = await service.updateExpiredRatesWithTimeout();

        if (result.success && result.updatedCurrencies.isNotEmpty) {
          // Taux mis à jour avec succès
          AppLogger.info(
            'AppViewState',
            '_smartLoadExchangeRates',
            '✅ Exchange rates cache already existed but was stale → it has been updated successfully.',
          );
        } else {
          // Échec ou aucune mise à jour nécessaire : continuer avec cache existant
          AppLogger.info(
            'AppViewState',
            '_smartLoadExchangeRates',
            'Exchange rates cache already exists and has not been updated (either it was up-to-date or the update failed).',
          );
        }
      }
    } catch (e) {
      // Ignorer les erreurs - pas critique pour l'initialisation de l'app
    }
  }

  /// Définit le nom d'utilisateur lors du premier lancement
  Future<void> setUserName(String name) async {
    await executeWithErrorHandling(() async {
      state = state.loading('Sauvegarde du nom d\'utilisateur...', 0.5);

      final success = await _userPreferencesService.setUserName(name);
      if (!success) {
        state = state.failure(
          'Impossible de sauvegarder le nom d\'utilisateur',
        );
        return;
      }

      state = state.copyWith(userName: name, isFirstLaunch: false);

      // Continuer l'initialisation
      await initializeApp();
    });
  }

  /// Réinitialise l'application (pour le développement)
  Future<void> resetApp() async {
    await executeWithErrorHandling(() async {
      state = state.loading('Réinitialisation...', 0.0);

      // Effacer les préférences utilisateur
      await _userPreferencesService.clearAll();

      // Nettoyer le cache
      _cacheManager.dispose();

      // Réinitialiser l'état
      state = const AppViewState();

      // Relancer l'initialisation
      await initializeApp();
    });
  }

  /// Met à jour le nom d'utilisateur
  Future<void> updateUserName(String newName) async {
    await executeWithErrorHandling(() async {
      final success = await _userPreferencesService.setUserName(newName);
      if (!success) {
        state = state.failure(
          'Impossible de mettre à jour le nom d\'utilisateur',
        );
        return;
      }

      state = state.copyWith(userName: newName);
    });
  }

  /// Vérifie si l'application est prête
  bool get isAppReady => state.isInitialized && _cacheManager.isInitialized;

  /// Obtient le message de bienvenue
  String get welcomeMessage => state.welcomeMessage;

  /// Obtient les statistiques de l'application
  Map<String, dynamic> getAppStats() {
    if (!_cacheManager.isInitialized) {
      return {
        'accounts': 0,
        'transactions': 0,
        'categories': 0,
        'counterparties': 0,
        'cacheInitialized': false,
      };
    }

    return {
      'accounts': _cacheManager.getAllAccounts().length,
      'transactions': _cacheManager.getAllTransactions().length,
      'categories': _cacheManager.getAllCategories().length,
      'counterparties': _cacheManager.getAllCounterparties().length,
      'cacheInitialized': true,
      'userName': state.userName,
      'isFirstLaunch': state.isFirstLaunch,
    };
  }

  /// Force une réinitialisation du cache
  Future<void> refreshCache() async {
    await executeWithErrorHandling(() async {
      state = state.loading('Actualisation du cache...', 0.0);

      // Nettoyer le cache existant
      _cacheManager.dispose();

      // Réinitialiser le cache
      await _initializeCache();

      state = state.success(
        initializationState: AppInitializationState.initialized,
        isFirstLaunch: state.isFirstLaunch,
        userName: state.userName,
      );
    });
  }

  /// Obtient les informations de débogage
  Map<String, dynamic> getDebugInfo() {
    return {
      'state': state.toString(),
      'cacheInitialized': _cacheManager.isInitialized,
      'cacheIsLoading': _cacheManager.isLoading,
      'appStats': getAppStats(),
      'userPreferences': {
        'userName': _userPreferencesService.getUserName(),
        'isFirstLaunch': _userPreferencesService.isFirstLaunch(),
        'hasUserName': _userPreferencesService.hasUserName(),
      },
    };
  }

  @override
  void resetToInitialState() {
    state = const AppViewState();
    // Note : On ne relance pas automatiquement l'initialisation
    // car cela doit être fait explicitement par l'UI
  }
}
