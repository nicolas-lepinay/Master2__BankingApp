import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/core/services/smart_exchange_rate_service.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// État pour AccountManagementViewModel - gestion CRUD des comptes
class AccountManagementViewState extends BaseViewState {
  /// Compte en cours de création/modification
  final domain.Account? currentAccount;
  
  /// Indique si une opération est en cours
  final bool isProcessing;
  
  /// Indique si la création/modification a été complétée avec succès
  final bool isCompleted;
  
  /// Message de validation
  final String? validationMessage;
  
  /// Nom temporaire pour validation
  final String? tempName;
  
  /// Devise temporaire pour validation
  final String? tempCurrency;
  
  /// Solde initial temporaire pour validation
  final double? tempInitialBalance;
  
  /// Icône temporaire pour validation
  final String? tempIcon;

  const AccountManagementViewState({
    this.currentAccount,
    this.isProcessing = false,
    this.isCompleted = false,
    this.validationMessage,
    this.tempName,
    this.tempCurrency,
    this.tempInitialBalance,
    this.tempIcon,
  });

  AccountManagementViewState copyWith({
    domain.Account? currentAccount,
    bool? isProcessing,
    bool? isCompleted,
    String? validationMessage,
    String? tempName,
    String? tempCurrency,
    double? tempInitialBalance,
    String? tempIcon,
    bool clearCurrentAccount = false,
    bool clearValidationMessage = false,
    bool clearTempName = false,
    bool clearTempCurrency = false,
    bool clearTempInitialBalance = false,
    bool clearTempIcon = false,
  }) {
    return AccountManagementViewState(
      currentAccount: clearCurrentAccount ? null : (currentAccount ?? this.currentAccount),
      isProcessing: isProcessing ?? this.isProcessing,
      isCompleted: isCompleted ?? this.isCompleted,
      validationMessage: clearValidationMessage ? null : (validationMessage ?? this.validationMessage),
      tempName: clearTempName ? null : (tempName ?? this.tempName),
      tempCurrency: clearTempCurrency ? null : (tempCurrency ?? this.tempCurrency),
      tempInitialBalance: clearTempInitialBalance ? null : (tempInitialBalance ?? this.tempInitialBalance),
      tempIcon: clearTempIcon ? null : (tempIcon ?? this.tempIcon),
    );
  }

  // États dérivés
  bool get hasAccount => currentAccount != null;
  bool get canSave => hasValidData && !isProcessing && !isCompleted;
  bool get isLoading => isProcessing;
  
  /// Vérifie si les données temporaires sont valides
  bool get hasValidData {
    return tempName?.isNotEmpty == true &&
           tempCurrency?.isNotEmpty == true &&
           tempInitialBalance != null;
  }
  
  /// Vérifie si les données ont changé par rapport au compte original
  bool get hasChanges {
    if (currentAccount == null) return hasValidData; // Nouveau compte
    
    return currentAccount!.name != (tempName ?? currentAccount!.name) ||
           currentAccount!.currency != (tempCurrency ?? currentAccount!.currency) ||
           currentAccount!.initialBalance != (tempInitialBalance ?? currentAccount!.initialBalance) ||
           currentAccount!.icon != (tempIcon ?? currentAccount!.icon);
  }

  List<Object?> get props => [
    currentAccount,
    isProcessing,
    isCompleted,
    validationMessage,
    tempName,
    tempCurrency,
    tempInitialBalance,
    tempIcon,
  ];
}

/// ViewModel pour la gestion des comptes (CRUD)
/// Suit l'architecture MVVM par use case - se concentre uniquement sur la gestion des comptes
class AccountManagementViewModel extends BaseViewModel<AccountManagementViewState> {
  final AccountRepository _accountRepository;
  final SmartExchangeRateService? _smartExchangeRateService;

  AccountManagementViewModel(
    this._accountRepository,
    this._smartExchangeRateService,
  ) : super(const AccountManagementViewState());

  @override
  void resetToInitialState() {
    state = const AccountManagementViewState();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  /// Initialise pour la création d'un nouveau compte
  void initializeForCreation() {
    state = const AccountManagementViewState();
  }
  
  /// Initialise pour la modification d'un compte existant
  Future<void> initializeForEdit(int accountId) async {
    try {
      state = state.copyWith(isProcessing: true);
      
      final account = await _accountRepository.getAccountById(accountId);
      if (account == null) {
        state = state.copyWith(
          isProcessing: false,
          validationMessage: 'Compte non trouvé',
        );
        return;
      }
      
      state = state.copyWith(
        currentAccount: account,
        tempName: account.name,
        tempCurrency: account.currency,
        tempInitialBalance: account.initialBalance,
        tempIcon: account.icon,
        isProcessing: false,
        isCompleted: false,
        clearValidationMessage: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing account for edit: $e');
      }
      state = state.copyWith(
        isProcessing: false,
        validationMessage: 'Erreur lors du chargement du compte',
      );
    }
  }

  // ============================================================================
  // FIELD UPDATES
  // ============================================================================
  
  /// Met à jour le nom temporaire
  void updateName(String name) {
    state = state.copyWith(
      tempName: name,
      clearValidationMessage: true,
    );
    _validateData();
  }
  
  /// Met à jour la devise temporaire
  void updateCurrency(String currency) {
    state = state.copyWith(
      tempCurrency: currency,
      clearValidationMessage: true,
    );
    _validateData();
  }
  
  /// Met à jour le solde initial temporaire
  void updateInitialBalance(double initialBalance) {
    state = state.copyWith(
      tempInitialBalance: initialBalance,
      clearValidationMessage: true,
    );
    _validateData();
  }
  
  /// Met à jour l'icône temporaire
  void updateIcon(String? icon) {
    state = state.copyWith(
      tempIcon: icon,
      clearTempIcon: icon == null,
      clearValidationMessage: true,
    );
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================
  
  /// Valide les données actuelles
  String? validateAccount() {
    final name = state.tempName?.trim();
    final currency = state.tempCurrency?.trim();
    final initialBalance = state.tempInitialBalance;
    
    if (name == null || name.isEmpty) {
      return 'Le nom du compte est requis';
    }
    
    if (name.length < 2) {
      return 'Le nom du compte doit contenir au moins 2 caractères';
    }
    
    if (name.length > 50) {
      return 'Le nom du compte ne peut pas dépasser 50 caractères';
    }
    
    if (currency == null || currency.isEmpty) {
      return 'La devise est requise';
    }
    
    if (currency.length != 3) {
      return 'La devise doit être un code à 3 lettres (ex: EUR, USD)';
    }
    
    if (initialBalance == null) {
      return 'Le solde initial est requis';
    }
    
    if (initialBalance < -999999999) {
      return 'Le solde initial ne peut pas être inférieur à -999,999,999';
    }
    
    if (initialBalance > 999999999) {
      return 'Le solde initial ne peut pas être supérieur à 999,999,999';
    }
    
    return null; // Pas d'erreur
  }
  
  /// Validation automatique lors des mises à jour
  void _validateData() {
    final validationResult = validateAccount();
    if (validationResult != state.validationMessage) {
      state = state.copyWith(
        validationMessage: validationResult,
        clearValidationMessage: validationResult == null,
      );
    }
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================
  
  /// Crée un nouveau compte
  Future<bool> createAccount() async {
    final validationResult = validateAccount();
    if (validationResult != null) {
      state = state.copyWith(validationMessage: validationResult);
      return false;
    }
    
    if (!state.hasValidData || state.isProcessing) return false;
    
    try {
      state = state.copyWith(isProcessing: true);
      
      final newAccount = domain.Account(
        id: 0, // Sera assigné par la base de données
        name: state.tempName!.trim(),
        currency: state.tempCurrency!.trim().toUpperCase(),
        initialBalance: state.tempInitialBalance!,
        creationDate: DateTime.now(),
        icon: state.tempIcon,
      );
      
      final createdAccount = await _accountRepository.createAccount(newAccount);
      
      // Notifier l'Event Bus
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountCreatedEvent(
        account: createdAccount,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_created',
      ));
      
      // S'assurer que les taux de change sont disponibles pour la devise
      _ensureExchangeRatesForCurrency(createdAccount.currency);
      
      state = state.copyWith(
        currentAccount: createdAccount,
        isProcessing: false,
        isCompleted: true,
        clearValidationMessage: true,
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating account: $e');
      }
      state = state.copyWith(
        isProcessing: false,
        validationMessage: 'Erreur lors de la création du compte',
      );
      return false;
    }
  }
  
  /// Met à jour le compte existant
  Future<bool> updateAccount() async {
    final validationResult = validateAccount();
    if (validationResult != null) {
      state = state.copyWith(validationMessage: validationResult);
      return false;
    }
    
    if (!state.hasAccount || !state.hasValidData || !state.hasChanges || state.isProcessing) {
      return false;
    }
    
    try {
      state = state.copyWith(isProcessing: true);
      
      final updatedAccount = state.currentAccount!.copyWith(
        name: state.tempName!.trim(),
        currency: state.tempCurrency!.trim().toUpperCase(),
        initialBalance: state.tempInitialBalance!,
        icon: state.tempIcon,
      );
      
      await _accountRepository.updateAccount(updatedAccount);
      
      // Notifier l'Event Bus
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountUpdatedEvent(
        updatedAccount: updatedAccount,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_updated',
      ));
      
      state = state.copyWith(
        currentAccount: updatedAccount,
        isProcessing: false,
        isCompleted: true,
        clearValidationMessage: true,
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating account: $e');
      }
      state = state.copyWith(
        isProcessing: false,
        validationMessage: 'Erreur lors de la modification du compte',
      );
      return false;
    }
  }
  
  /// Supprime un compte avec confirmation
  Future<bool> deleteAccount(int accountId) async {
    if (state.isProcessing) return false;
    
    try {
      state = state.copyWith(isProcessing: true);
      
      // Récupérer le compte avant suppression pour l'événement
      final accountToDelete = await _accountRepository.getAccountById(accountId);
      if (accountToDelete == null) {
        state = state.copyWith(
          isProcessing: false,
          validationMessage: 'Compte non trouvé',
        );
        return false;
      }
      
      await _accountRepository.deleteAccount(accountId);
      
      // Notifier l'Event Bus
      final eventBus = AppEventBus.instance;
      eventBus.fire(AccountDeletedEvent(
        accountId: accountId,
        deletedAccount: accountToDelete,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_account_deleted',
      ));
      
      state = state.copyWith(
        isProcessing: false,
        isCompleted: true,
        clearCurrentAccount: true,
        clearValidationMessage: true,
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      state = state.copyWith(
        isProcessing: false,
        validationMessage: 'Erreur lors de la suppression du compte',
      );
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// S'assure que les taux de change sont disponibles pour une devise
  /// (Méthode asynchrone non-bloquante)
  void _ensureExchangeRatesForCurrency(String currency) {
    if (_smartExchangeRateService == null) return;
    
    // Exécuter en arrière-plan sans bloquer l'UI
    Future(() async {
      try {
        await _smartExchangeRateService.ensureCurrencyAvailable(currency);
        // Succès : les taux de change sont maintenant disponibles
      } catch (e) {
        // Échec non-bloquant : l'utilisateur pourra utiliser l'app normalement
        // Les conversions afficheront un message d'erreur approprié
        if (kDebugMode) {
          print('Warning: Could not ensure exchange rates for $currency: $e');
        }
      }
    });
  }
  
  /// Annule les modifications en cours
  void cancelChanges() {
    if (state.currentAccount != null) {
      // Restaurer les valeurs originales
      state = state.copyWith(
        tempName: state.currentAccount!.name,
        tempCurrency: state.currentAccount!.currency,
        tempInitialBalance: state.currentAccount!.initialBalance,
        tempIcon: state.currentAccount!.icon,
        isCompleted: false,
        clearValidationMessage: true,
      );
    } else {
      // Nouveau compte - réinitialiser
      state = state.copyWith(
        clearTempName: true,
        clearTempCurrency: true,
        clearTempInitialBalance: true,
        clearTempIcon: true,
        isCompleted: false,
        clearValidationMessage: true,
      );
    }
  }

  // ============================================================================
  // GETTERS UTILITAIRES
  // ============================================================================
  
  /// Compte actuellement géré
  domain.Account? get currentAccount => state.currentAccount;
  
  /// Nom temporaire
  String? get currentName => state.tempName;
  
  /// Devise temporaire
  String? get currentCurrency => state.tempCurrency;
  
  /// Solde initial temporaire
  double? get currentInitialBalance => state.tempInitialBalance;
  
  /// Icône temporaire
  String? get currentIcon => state.tempIcon;
  
  /// Indique si une opération est en cours
  bool get isProcessing => state.isProcessing;
  
  /// Indique si l'opération est terminée
  bool get isCompleted => state.isCompleted;
  
  /// Indique si on peut sauvegarder
  bool get canSave => state.canSave;
  
  /// Indique s'il y a des changements
  bool get hasChanges => state.hasChanges;
  
  /// Message de validation actuel
  String? get validationMessage => state.validationMessage;
  
  /// Indique si on est en mode création (pas de compte existant)
  bool get isCreating => !state.hasAccount;
  
  /// Indique si on est en mode modification (compte existant)
  bool get isEditing => state.hasAccount;
}