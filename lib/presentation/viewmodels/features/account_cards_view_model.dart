import 'dart:async';
import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/account_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';

/// État pour la gestion des cartes de comptes
class AccountCardsViewState extends BaseViewState {
  /// Map des résumés de comptes par ID pour un accès O(1)
  final Map<int, domain.AccountSummary> accountSummaries;
  
  /// Liste des comptes actuellement disponibles
  final List<domain.Account> accounts;
  
  /// États de chargement par compte
  final Map<int, bool> loadingStates;

  const AccountCardsViewState({
    this.accountSummaries = const {},
    this.accounts = const [],
    this.loadingStates = const {},
  });

  /// Obtient le résumé d'un compte par ID
  domain.AccountSummary? getAccountSummary(int accountId) => 
      accountSummaries[accountId];
  
  /// Vérifie si un compte est en cours de chargement
  bool isAccountLoading(int accountId) => loadingStates[accountId] ?? false;
  
  /// Vérifie si des comptes existent
  bool get hasAccounts => accounts.isNotEmpty;

  AccountCardsViewState copyWith({
    Map<int, domain.AccountSummary>? accountSummaries,
    List<domain.Account>? accounts,
    Map<int, bool>? loadingStates,
  }) {
    return AccountCardsViewState(
      accountSummaries: accountSummaries ?? this.accountSummaries,
      accounts: accounts ?? this.accounts,
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }

  @override
  String toString() =>
      'AccountCardsViewState(accounts: ${accounts.length}, summaries: ${accountSummaries.length})';
}

/// ViewModel uniforme pour la gestion des cartes de comptes
/// Utilise l'Event Bus exactement comme PerspectiveListView pour une architecture cohérente
class AccountCardsViewModel extends BaseViewModel<AccountCardsViewState> {
  final AccountRepository _accountRepository;
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;
  StreamSubscription<AccountEvent>? _accountEventSubscription;

  AccountCardsViewModel(this._accountRepository) 
      : super(const AccountCardsViewState()) {
    _subscribeToEvents();
    initialize();
  }

  // ============================================================================
  // GESTION DES ÉVÉNEMENTS EVENT BUS - Pattern identique à PerspectiveListView
  // ============================================================================

  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de transaction pour mettre à jour les soldes
    _transactionEventSubscription = eventBus.transactionEvents.listen((event) {
      _handleTransactionEvent(event);
    });
    
    // Écouter les événements de comptes pour les modifications/suppressions
    _accountEventSubscription = eventBus.accountEvents.listen((event) {
      _handleAccountEvent(event);
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    switch (event) {
      case TransactionCreatedEvent():
        _handleTransactionCreated(event);
        break;
      case TransactionUpdatedEvent():
        _handleTransactionUpdated(event);
        break;
      case TransactionDeletedEvent():
        _handleTransactionDeleted(event);
        break;
      default:
        break;
    }
  }

  void _handleAccountEvent(AccountEvent event) {
    switch (event) {
      case AccountCreatedEvent():
        _handleAccountCreated(event);
        break;
      case AccountUpdatedEvent():
        _handleAccountUpdated(event);
        break;
      case AccountDeletedEvent():
        _handleAccountDeleted(event);
        break;
      default:
        break;
    }
  }

  // ============================================================================
  // GESTIONNAIRES D'ÉVÉNEMENTS SPÉCIFIQUES
  // ============================================================================

  void _handleTransactionCreated(TransactionCreatedEvent event) {
    // Recharger le résumé du compte concerné par la nouvelle transaction
    _refreshAccountSummary(event.accountId);
  }

  void _handleTransactionUpdated(TransactionUpdatedEvent event) {
    // Recharger le résumé du compte concerné par la modification
    _refreshAccountSummary(event.accountId);
  }

  void _handleTransactionDeleted(TransactionDeletedEvent event) {
    // Recharger le résumé du compte concerné par la suppression
    _refreshAccountSummary(event.accountId);
  }

  void _handleAccountCreated(AccountCreatedEvent event) {
    // Recharger tous les comptes et leurs résumés
    initialize();
  }

  void _handleAccountUpdated(AccountUpdatedEvent event) {
    // Mettre à jour le compte dans la liste et recharger son résumé
    final updatedAccounts = state.accounts.map((account) {
      return account.id == event.updatedAccount.id ? event.updatedAccount : account;
    }).toList();

    state = state.copyWith(accounts: updatedAccounts);
    _refreshAccountSummary(event.updatedAccount.id);
  }

  void _handleAccountDeleted(AccountDeletedEvent event) {
    // Retirer le compte supprimé de la liste et de la cache
    final updatedAccounts = state.accounts.where((account) => account.id != event.accountId).toList();
    final updatedSummaries = Map<int, domain.AccountSummary>.from(state.accountSummaries);
    final updatedLoadingStates = Map<int, bool>.from(state.loadingStates);
    
    updatedSummaries.remove(event.accountId);
    updatedLoadingStates.remove(event.accountId);

    state = state.copyWith(
      accounts: updatedAccounts,
      accountSummaries: updatedSummaries,
      loadingStates: updatedLoadingStates,
    );
  }

  // ============================================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================================

  /// Initialise le ViewModel en chargeant tous les comptes
  Future<void> initialize() async {
    await executeWithErrorHandling(() async {
      final accounts = await _accountRepository.getAllAccounts();
      
      state = state.copyWith(accounts: accounts);
      
      // Charger les résumés de tous les comptes en parallèle
      await _loadAllAccountSummaries();
    });
  }

  /// Charge les résumés de tous les comptes
  Future<void> _loadAllAccountSummaries() async {
    final futures = state.accounts.map((account) => _loadAccountSummary(account.id));
    await Future.wait(futures);
  }

  /// Charge le résumé d'un compte spécifique
  Future<void> _loadAccountSummary(int accountId) async {
    // Marquer comme en chargement
    final updatedLoadingStates = Map<int, bool>.from(state.loadingStates);
    updatedLoadingStates[accountId] = true;
    state = state.copyWith(loadingStates: updatedLoadingStates);

    try {
      final accountSummary = await _accountRepository.getAccountSummary(accountId);
      
      // Mettre à jour le résumé dans le cache
      final updatedSummaries = Map<int, domain.AccountSummary>.from(state.accountSummaries);
      updatedSummaries[accountId] = accountSummary;
      
      // Marquer comme chargé
      updatedLoadingStates[accountId] = false;
      
      state = state.copyWith(
        accountSummaries: updatedSummaries,
        loadingStates: updatedLoadingStates,
      );
    } catch (e) {
      // Marquer comme erreur (plus en chargement)
      updatedLoadingStates[accountId] = false;
      state = state.copyWith(loadingStates: updatedLoadingStates);
      
      // L'erreur est gérée par executeWithErrorHandling dans le BaseViewModel
      rethrow;
    }
  }

  /// Actualise le résumé d'un compte spécifique (appelé par les événements)
  Future<void> _refreshAccountSummary(int accountId) async {
    // Vérifier que le compte existe dans notre état
    if (state.accounts.any((account) => account.id == accountId)) {
      await _loadAccountSummary(accountId);
    }
  }

  /// Actualise tous les résumés de comptes
  Future<void> refresh() async {
    await initialize();
  }

  // ============================================================================
  // MÉTHODES ABSTRAITES BASEVIEWMODEL
  // ============================================================================

  @override
  void resetToInitialState() {
    state = const AccountCardsViewState();
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    _accountEventSubscription?.cancel();
    super.dispose();
  }
}