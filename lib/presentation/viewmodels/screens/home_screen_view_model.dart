import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/account_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'dart:async';

/// État pour le HomeScreenViewModel - gestion de l'écran d'accueil
class HomeScreenViewState extends BaseViewState {
  /// Liste des comptes de l'utilisateur
  final List<domain.Account> accounts;
  
  /// Compte actuellement sélectionné
  final domain.Account? selectedAccount;
  
  /// Résumé du compte sélectionné (avec soldes calculés)
  final domain.AccountSummary? selectedAccountSummary;
  
  /// Message de bienvenue personnalisé
  final String welcomeMessage;
  
  /// État d'animation des cartes (expanded/collapsed)
  final bool isCardsExpanded;
  
  /// Index de la carte actuellement visible dans le carousel
  final int selectedCardIndex;
  
  /// Indique si l'animation de collection des cartes doit être jouée
  final bool shouldPlayCardAnimation;

  const HomeScreenViewState({
    this.accounts = const [],
    this.selectedAccount,
    this.selectedAccountSummary,
    this.welcomeMessage = '',
    this.isCardsExpanded = false,
    this.selectedCardIndex = 0,
    this.shouldPlayCardAnimation = false,
  });

  HomeScreenViewState copyWith({
    List<domain.Account>? accounts,
    domain.Account? selectedAccount,
    domain.AccountSummary? selectedAccountSummary,
    String? welcomeMessage,
    bool? isCardsExpanded,
    int? selectedCardIndex,
    bool? shouldPlayCardAnimation,
    bool clearSelectedAccount = false,
    bool clearSelectedAccountSummary = false,
  }) {
    return HomeScreenViewState(
      accounts: accounts ?? this.accounts,
      selectedAccount: clearSelectedAccount ? null : (selectedAccount ?? this.selectedAccount),
      selectedAccountSummary: clearSelectedAccountSummary ? null : (selectedAccountSummary ?? this.selectedAccountSummary),
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      isCardsExpanded: isCardsExpanded ?? this.isCardsExpanded,
      selectedCardIndex: selectedCardIndex ?? this.selectedCardIndex,
      shouldPlayCardAnimation: shouldPlayCardAnimation ?? this.shouldPlayCardAnimation,
    );
  }

  // États dérivés
  bool get hasAccounts => accounts.isNotEmpty;
  bool get hasSelectedAccount => selectedAccount != null;
  bool get hasSelectedAccountSummary => selectedAccountSummary != null;
  
  /// Obtient les transactions récentes du compte sélectionné
  List<domain.TransactionWithBalance> get recentTransactions {
    return selectedAccountSummary?.recentTransactions ?? [];
  }
  
  /// Obtient le solde actuel du compte sélectionné
  double get currentBalance {
    return selectedAccountSummary?.currentBalance.amount ?? 0.0;
  }
  
  /// Obtient la devise du compte sélectionné
  String get currentCurrency {
    return selectedAccount?.currency ?? 'EUR';
  }
}

/// ViewModel pour l'écran d'accueil
/// 
/// Ce ViewModel gère l'état de l'écran d'accueil, incluant :
/// - La liste des comptes de l'utilisateur
/// - La sélection et navigation entre les comptes
/// - Les messages de bienvenue personnalisés
/// - Les états d'animation des cartes
/// - La communication avec l'Event Bus pour la réactivité
class HomeScreenViewModel extends BaseViewModel<HomeScreenViewState> {
  final AccountRepository _accountRepository;
  StreamSubscription<AccountEvent>? _accountEventSubscription;
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  HomeScreenViewModel(
    this._accountRepository,
  ) : super(const HomeScreenViewState()) {
    _subscribeToEvents();
  }

  // ============================================================================
  // GESTION DES ÉVÉNEMENTS EVENT BUS
  // ============================================================================

  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de comptes
    _accountEventSubscription = eventBus.accountEvents.listen((event) {
      _handleAccountEvent(event);
    });

    // Écouter les événements de transactions pour mettre à jour les soldes
    _transactionEventSubscription = eventBus.transactionEvents.listen((event) {
      _handleTransactionEvent(event);
    });
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
      case AccountSelectedEvent():
        _handleAccountSelected(event);
        break;
      default:
        break;
    }
  }

  void _handleTransactionEvent(TransactionEvent event) {
    // Si une transaction affecte le compte sélectionné, recharger son résumé
    if (state.selectedAccount?.id == event.accountId) {
      _refreshSelectedAccountSummary();
    }
  }

  void _handleAccountCreated(AccountCreatedEvent event) {
    // Recharger la liste des comptes
    refresh();
  }

  void _handleAccountUpdated(AccountUpdatedEvent event) {
    // Recharger la liste des comptes et mettre à jour le sélectionné si nécessaire
    refresh();
    if (state.selectedAccount?.id == event.updatedAccount.id) {
      state = state.copyWith(selectedAccount: event.updatedAccount);
    }
  }

  void _handleAccountDeleted(AccountDeletedEvent event) {
    // Recharger la liste des comptes
    refresh();
    // Si le compte supprimé était sélectionné, le désélectionner
    if (state.selectedAccount?.id == event.accountId) {
      state = state.copyWith(clearSelectedAccount: true, clearSelectedAccountSummary: true);
    }
  }

  void _handleAccountSelected(AccountSelectedEvent event) {
    // Ne pas gérer ici pour éviter les boucles - la sélection se fait via selectAccount()
  }

  // ============================================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================================

  /// Initialise l'écran d'accueil
  Future<void> initialize() async {
    if (state.hasAccounts) return; // Éviter le double chargement
    
    await executeWithErrorHandling(() async {
      // Charger les comptes
      final accounts = await _accountRepository.getAllAccounts();
      
      // Générer le message de bienvenue
      final welcomeMessage = await _generateWelcomeMessage();
      
      state = state.copyWith(
        accounts: accounts,
        welcomeMessage: welcomeMessage,
      );
      
      // Sélectionner automatiquement le premier compte s'il existe
      if (accounts.isNotEmpty) {
        await selectAccount(accounts[0].id, notifyEventBus: false);
      }
    });
  }

  /// Rafraîchit les données de l'écran d'accueil
  Future<void> refresh() async {
    await executeWithErrorHandling(() async {
      // Recharger les comptes
      final accounts = await _accountRepository.getAllAccounts();
      
      // Régénérer le message de bienvenue
      final welcomeMessage = await _generateWelcomeMessage();
      
      state = state.copyWith(
        accounts: accounts,
        welcomeMessage: welcomeMessage,
      );
      
      // Recharger le résumé du compte sélectionné si il existe encore
      if (state.selectedAccount != null) {
        final stillExists = accounts.any((account) => account.id == state.selectedAccount!.id);
        if (stillExists) {
          await _refreshSelectedAccountSummary();
        } else {
          // Le compte sélectionné n'existe plus, sélectionner le premier disponible
          state = state.copyWith(clearSelectedAccount: true, clearSelectedAccountSummary: true);
          if (accounts.isNotEmpty) {
            await selectAccount(accounts[0].id, notifyEventBus: false);
          }
        }
      }
    });
  }

  /// Génère un message de bienvenue personnalisé
  Future<String> _generateWelcomeMessage() async {
    // Pour l'instant, logique simple - peut être étendue avec l'heure, nom utilisateur, etc.
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Bonjour !';
    } else if (hour < 18) {
      return 'Bon après-midi !';
    } else {
      return 'Bonsoir !';
    }
  }

  // ============================================================================
  // GESTION DE LA SÉLECTION DES COMPTES
  // ============================================================================

  /// Sélectionne un compte par son ID
  Future<void> selectAccount(int accountId, {bool notifyEventBus = true}) async {
    final account = state.accounts.firstWhere(
      (account) => account.id == accountId,
      orElse: () => throw StateError('Account with id $accountId not found'),
    );

    state = state.copyWith(selectedAccount: account);

    // Charger le résumé du compte sélectionné
    await _refreshSelectedAccountSummary();

    // Notifier l'Event Bus si demandé
    if (notifyEventBus) {
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountSelectedEvent(
        accountId: accountId,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_selected',
      ));
    }
  }

  /// Sélectionne un compte par son index dans la liste
  Future<void> selectAccountByIndex(int index) async {
    if (index >= 0 && index < state.accounts.length) {
      state = state.copyWith(selectedCardIndex: index);
      await selectAccount(state.accounts[index].id);
    }
  }

  /// Rafraîchit le résumé du compte sélectionné
  Future<void> _refreshSelectedAccountSummary() async {
    if (state.selectedAccount == null) return;

    await executeWithErrorHandling(() async {
      final accountSummary = await _accountRepository.getAccountSummary(
        state.selectedAccount!.id,
      );
      
      state = state.copyWith(selectedAccountSummary: accountSummary);
    });
  }

  // ============================================================================
  // GESTION DES ANIMATIONS
  // ============================================================================

  /// Met à jour l'état d'expansion des cartes
  void setCardsExpanded(bool expanded) {
    state = state.copyWith(isCardsExpanded: expanded);
  }

  /// Met à jour l'état d'animation de collection des cartes
  void setShouldPlayCardAnimation(bool shouldPlay) {
    state = state.copyWith(shouldPlayCardAnimation: shouldPlay);
  }

  /// Met à jour l'index de la carte sélectionnée
  void setSelectedCardIndex(int index) {
    state = state.copyWith(selectedCardIndex: index);
  }

  // ============================================================================
  // ACTIONS UTILISATEUR
  // ============================================================================

  /// Action pour créer un nouveau compte
  Future<void> createAccount(String name, String currency, double initialBalance) async {
    await executeWithErrorHandling(() async {
      final newAccount = domain.Account(
        id: 0, // L'ID sera généré par la base de données
        name: name,
        currency: currency,
        initialBalance: initialBalance,
        creationDate: DateTime.now(),
      );
      
      final createdAccount = await _accountRepository.createAccount(newAccount);
      
      // L'Event Bus notifiera automatiquement les autres ViewModels
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountCreatedEvent(
        account: createdAccount,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_created',
      ));
      
      // Recharger et sélectionner le nouveau compte
      await refresh();
      await selectAccount(createdAccount.id, notifyEventBus: false); // Éviter double notification
    });
  }

  /// Action pour supprimer un compte
  Future<void> deleteAccount(int accountId) async {
    await executeWithErrorHandling(() async {
      final accountToDelete = state.accounts.firstWhere(
        (account) => account.id == accountId,
        orElse: () => throw StateError('Account with id $accountId not found'),
      );
      
      await _accountRepository.deleteAccount(accountId);
      
      // Notifier l'Event Bus
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountDeletedEvent(
        accountId: accountId,
        deletedAccount: accountToDelete,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_deleted',
      ));
      
      // Recharger les données
      await refresh();
    });
  }

  // ============================================================================
  // GETTERS UTILITAIRES
  // ============================================================================

  /// Obtient un compte par son ID
  domain.Account? getAccountById(int accountId) {
    try {
      return state.accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient l'index d'un compte dans la liste
  int getAccountIndex(int accountId) {
    return state.accounts.indexWhere((account) => account.id == accountId);
  }

  /// Vérifie si l'app est prête pour l'affichage
  bool get isAppReady => state.hasAccounts || (!isLoading && !hasError);

  // ============================================================================
  // GESTION DU CYCLE DE VIE
  // ============================================================================

  @override
  void resetToInitialState() {
    state = const HomeScreenViewState();
  }

  @override
  void dispose() {
    _accountEventSubscription?.cancel();
    _transactionEventSubscription?.cancel();
    super.dispose();
  }
}