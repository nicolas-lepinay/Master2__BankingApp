import 'package:bankapp/core/services/smart_exchange_rate_service.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

/// État pour la gestion des comptes
class AccountViewState extends BaseViewState {
  final List<domain.Account> accounts;
  final domain.Account? selectedAccount;
  final domain.AccountSummary? selectedAccountSummary;
  final bool isLoading;
  final String? error;

  const AccountViewState({
    this.accounts = const [],
    this.selectedAccount,
    this.selectedAccountSummary,
    this.isLoading = false,
    this.error,
  });

  AccountViewState copyWith({
    List<domain.Account>? accounts,
    domain.Account? selectedAccount,
    domain.AccountSummary? selectedAccountSummary,
    bool? isLoading,
    String? error,
  }) {
    return AccountViewState(
      accounts: accounts ?? this.accounts,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedAccountSummary:
          selectedAccountSummary ?? this.selectedAccountSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  AccountViewState loading() {
    return copyWith(isLoading: true, error: null);
  }

  AccountViewState success({
    List<domain.Account>? accounts,
    domain.Account? selectedAccount,
    domain.AccountSummary? selectedAccountSummary,
  }) {
    return AccountViewState(
      accounts: accounts ?? this.accounts,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedAccountSummary:
          selectedAccountSummary ?? this.selectedAccountSummary,
      isLoading: false,
      error: null,
    );
  }

  AccountViewState failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }

  bool get hasError => error != null;
  bool get hasAccounts => accounts.isNotEmpty;
  bool get hasSelectedAccount => selectedAccount != null;
  bool get hasSelectedAccountSummary => selectedAccountSummary != null;

  @override
  String toString() =>
      'AccountViewState(accounts: ${accounts.length}, selectedAccount: ${selectedAccount?.id}, isLoading: $isLoading, error: $error)';
}

/// ViewModel pour la gestion des comptes
class AccountViewModel extends BaseViewModel<AccountViewState> {
  final AccountRepository _accountRepository;
  final SmartExchangeRateService? _smartExchangeRateService;

  AccountViewModel(this._accountRepository, this._smartExchangeRateService)
    : super(const AccountViewState()) {
    _init();
  }

  /// Initialise le ViewModel
  Future<void> _init() async {
    await loadAccounts();
  }

  /// Charge tous les comptes
  Future<void> loadAccounts() async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final accounts = await _accountRepository.getAllAccounts();

      state = state.success(accounts: accounts);

      // Sélectionner le premier compte par défaut si aucun n'est sélectionné
      if (accounts.isNotEmpty && state.selectedAccount == null) {
        await selectAccount(accounts.first.id);
      }
    });
  }

  /// Sélectionne un compte
  Future<void> selectAccount(int accountId) async {
    await executeWithErrorHandling(() async {
      final account = await _accountRepository.getAccountById(accountId);
      if (account == null) {
        state = state.failure('Compte non trouvé');
        return;
      }

      state = state.copyWith(selectedAccount: account);

      // Charger le résumé du compte
      await _loadAccountSummary(accountId);
    });
  }

  /// Charge le résumé du compte sélectionné
  Future<void> _loadAccountSummary(int accountId) async {
    await executeWithErrorHandling(() async {
      final summary = await _accountRepository.getAccountSummary(accountId);
      state = state.copyWith(selectedAccountSummary: summary);
    });
  }

  /// Crée un nouveau compte
  Future<void> createAccount({
    required String name,
    required String currency,
    required double initialBalance,
    String? icon,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final newAccount = domain.Account(
        id: 0, // Sera assigné par la base de données
        name: name,
        currency: currency,
        initialBalance: initialBalance,
        creationDate: DateTime.now(),
        icon: icon,
      );

      final createdAccount = await _accountRepository.createAccount(newAccount);

      // Recharger la liste des comptes
      await loadAccounts();

      // Sélectionner le nouveau compte
      await selectAccount(createdAccount.id);

      // Cas 3 : Mise à jour asynchrone des taux de change pour la devise du compte
      _ensureExchangeRatesForCurrency(currency);
    });
  }

  /// Met à jour un compte
  Future<void> updateAccount({
    required int accountId,
    required String name,
    required String currency,
    required double initialBalance,
    String? icon,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final existingAccount = await _accountRepository.getAccountById(
        accountId,
      );
      if (existingAccount == null) {
        state = state.failure('Compte non trouvé');
        return;
      }

      final updatedAccount = existingAccount.copyWith(
        name: name,
        currency: currency,
        initialBalance: initialBalance,
        icon: icon,
      );

      await _accountRepository.updateAccount(updatedAccount);

      // Recharger la liste des comptes
      await loadAccounts();

      // Maintenir la sélection si c'était le compte sélectionné
      if (state.selectedAccount?.id == accountId) {
        await selectAccount(accountId);
      }
    });
  }

  /// Supprime un compte
  Future<void> deleteAccount(int accountId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      await _accountRepository.deleteAccount(accountId);

      // Recharger la liste des comptes
      await loadAccounts();

      // Si le compte supprimé était sélectionné, sélectionner le premier disponible
      if (state.selectedAccount?.id == accountId) {
        if (state.accounts.isNotEmpty) {
          await selectAccount(state.accounts.first.id);
        } else {
          state = state.copyWith(
            selectedAccount: null,
            selectedAccountSummary: null,
          );
        }
      }
    });
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadAccounts();
    if (state.selectedAccount != null) {
      await _loadAccountSummary(state.selectedAccount!.id);
    }
  }

  /// Obtient un compte par ID
  domain.Account? getAccountById(int accountId) {
    try {
      return state.accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient le solde actuel du compte sélectionné
  double? get currentBalance =>
      state.selectedAccountSummary?.currentBalance.amount;

  /// Obtient la devise du compte sélectionné
  String? get selectedAccountCurrency => state.selectedAccount?.currency;

  /// Obtient le nom du compte sélectionné
  String? get selectedAccountName => state.selectedAccount?.name;

  /// Obtient l'icône du compte sélectionné
  String? get selectedAccountIcon => state.selectedAccount?.icon;

  /// Obtient les transactions récentes du compte sélectionné
  List<domain.TransactionWithBalance> get recentTransactions =>
      state.selectedAccountSummary?.recentTransactions ?? [];

  /// Obtient le nombre total de transactions du compte sélectionné
  int get totalTransactionsCount =>
      state.selectedAccountSummary?.totalTransactionsCount ?? 0;

  /// Obtient le total des revenus du compte sélectionné
  double get totalIncome =>
      state.selectedAccountSummary?.totalIncome.amount ?? 0;

  /// Obtient le total des dépenses du compte sélectionné
  double get totalExpenses =>
      state.selectedAccountSummary?.totalExpenses.amount ?? 0;

  /// Obtient le montant net du compte sélectionné
  double get netAmount => state.selectedAccountSummary?.netAmount.amount ?? 0;

  /// Obtient le pourcentage de changement du solde
  double get balanceChangePercentage =>
      state.selectedAccountSummary?.getBalanceChangePercentage() ?? 0;

  /// Indique si le solde est positif
  bool get isBalancePositive =>
      state.selectedAccountSummary?.isBalancePositive ?? false;

  /// Indique si le solde est négatif
  bool get isBalanceNegative =>
      state.selectedAccountSummary?.isBalanceNegative ?? false;

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
      }
    });
  }

  @override
  void resetToInitialState() {
    state = const AccountViewState();
    _init();
  }
}
