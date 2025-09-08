import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'dart:async';

/// État pour le TransactionEditViewModel - gestion de l'édition d'une transaction
class TransactionEditViewState extends BaseViewState {
  /// Transaction originale avant modification
  final domain.Transaction? originalTransaction;
  
  /// Transaction en cours d'édition (avec modifications)
  final domain.Transaction? editingTransaction;
  
  /// Indique si l'opération d'édition est en cours
  final bool isUpdating;
  
  /// Indique si les modifications ont été sauvegardées avec succès
  final bool isSaved;
  
  /// Message de validation des champs
  final String? validationMessage;

  const TransactionEditViewState({
    this.originalTransaction,
    this.editingTransaction,
    this.isUpdating = false,
    this.isSaved = false,
    this.validationMessage,
  });

  TransactionEditViewState copyWith({
    domain.Transaction? originalTransaction,
    domain.Transaction? editingTransaction,
    bool? isUpdating,
    bool? isSaved,
    String? validationMessage,
    bool clearValidationMessage = false,
  }) {
    return TransactionEditViewState(
      originalTransaction: originalTransaction ?? this.originalTransaction,
      editingTransaction: editingTransaction ?? this.editingTransaction,
      isUpdating: isUpdating ?? this.isUpdating,
      isSaved: isSaved ?? this.isSaved,
      validationMessage: clearValidationMessage ? null : (validationMessage ?? this.validationMessage),
    );
  }

  // États dérivés
  bool get hasTransaction => originalTransaction != null;
  bool get hasChanges => originalTransaction != null && 
                        editingTransaction != null && 
                        !_transactionsEqual(originalTransaction!, editingTransaction!);
  bool get isLoading => isUpdating;
  bool get canSave => hasTransaction && hasChanges && !isUpdating && validationMessage == null;

  /// Compare deux transactions pour détecter les changements
  bool _transactionsEqual(domain.Transaction a, domain.Transaction b) {
    return a.accountId == b.accountId &&
           a.type == b.type &&
           a.amount == b.amount &&
           a.currency == b.currency &&
           a.title == b.title &&
           a.comment == b.comment &&
           a.date == b.date &&
           a.status == b.status &&
           a.counterpartyId == b.counterpartyId &&
           a.category1Id == b.category1Id &&
           a.category2Id == b.category2Id &&
           a.category3Id == b.category3Id &&
           a.category4Id == b.category4Id;
  }

  List<Object?> get props => [
    originalTransaction,
    editingTransaction, 
    isUpdating,
    isSaved,
    validationMessage,
  ];
}

/// ViewModel pour l'édition d'une transaction
/// Suit l'architecture MVVM par use case - se concentre uniquement sur l'édition
class TransactionEditViewModel extends BaseViewModel<TransactionEditViewState> {
  final int _transactionId;
  final TransactionRepository _transactionRepository;
  StreamSubscription<TransactionEvent>? _eventSubscription;

  TransactionEditViewModel(
    this._transactionId,
    this._transactionRepository,
  ) : super(const TransactionEditViewState()) {
    _initializeEventBus();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void resetToInitialState() {
    state = const TransactionEditViewState();
  }

  // ============================================================================
  // EVENT BUS INTEGRATION
  // ============================================================================

  void _initializeEventBus() {
    final eventBus = AppEventBus.instance;
    _eventSubscription = eventBus.on<TransactionEvent>().listen((event) {
      _handleTransactionEvent(event);
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    // Si la transaction éditée est modifiée ailleurs, recharger
    if (event is TransactionUpdatedEvent && event.updatedTransaction.id == _transactionId) {
      _handleTransactionUpdatedExternally(event);
    } else if (event is TransactionDeletedEvent && event.transactionId == _transactionId) {
      _handleTransactionDeleted(event);
    }
  }

  void _handleTransactionUpdatedExternally(TransactionUpdatedEvent event) {
    // La transaction a été modifiée ailleurs, mettre à jour la transaction originale
    state = state.copyWith(
      originalTransaction: event.updatedTransaction,
      editingTransaction: event.updatedTransaction,
      isSaved: false,
    );
  }

  void _handleTransactionDeleted(TransactionDeletedEvent event) {
    // La transaction a été supprimée, vider l'état
    state = state.copyWith(
      originalTransaction: null,
      editingTransaction: null,
      isSaved: false,
    );
  }

  // ============================================================================
  // CHARGEMENT ET INITIALISATION
  // ============================================================================

  /// Initialise l'édition en chargeant la transaction
  Future<void> initialize() async {
    await loadTransaction();
  }

  /// Charge la transaction à éditer
  Future<void> loadTransaction() async {
    await executeWithErrorHandling(() async {
      final transaction = await _transactionRepository.getTransactionById(_transactionId);
      
      if (transaction == null) {
        throw Exception('Transaction non trouvée');
      }

      state = state.copyWith(
        originalTransaction: transaction,
        editingTransaction: transaction,
        isSaved: false,
        clearValidationMessage: true,
      );
    });
  }

  /// Rafraîchit les données de la transaction
  Future<void> refresh() async {
    await loadTransaction();
  }

  // ============================================================================
  // MODIFICATION DES CHAMPS
  // ============================================================================

  /// Met à jour le type de transaction
  void updateType(domain.TransactionType type) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(type: type);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour le montant
  void updateAmount(double amount) {
    if (state.editingTransaction == null) return;
    
    final validationError = _validateAmount(amount);
    final updatedTransaction = state.editingTransaction!.copyWith(amount: amount);
    
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      validationMessage: validationError,
    );
  }

  /// Met à jour la devise
  void updateCurrency(String currency) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(currency: currency);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour le titre
  void updateTitle(String? title) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(title: title);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour le commentaire
  void updateComment(String? comment) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(comment: comment);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour la date
  void updateDate(DateTime date) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(date: date);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour le compte
  void updateAccount(int accountId) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(accountId: accountId);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour la contrepartie
  void updateCounterparty(int? counterpartyId) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(counterpartyId: counterpartyId);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour les catégories
  void updateCategories(List<int>? categoryIds) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(
      category1Id: categoryIds?.isNotEmpty == true ? categoryIds![0] : null,
      category2Id: categoryIds != null && categoryIds.length > 1 ? categoryIds[1] : null,
      category3Id: categoryIds != null && categoryIds.length > 2 ? categoryIds[2] : null,
      category4Id: categoryIds != null && categoryIds.length > 3 ? categoryIds[3] : null,
    );
    
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  /// Met à jour le statut
  void updateStatus(domain.TransactionStatus status) {
    if (state.editingTransaction == null) return;
    
    final updatedTransaction = state.editingTransaction!.copyWith(status: status);
    state = state.copyWith(
      editingTransaction: updatedTransaction,
      clearValidationMessage: true,
    );
  }

  // ============================================================================
  // SAUVEGARDE
  // ============================================================================

  /// Sauvegarde les modifications
  Future<bool> saveTransaction() async {
    if (!state.canSave) return false;

    state = state.copyWith(isUpdating: true);

    try {
      await executeWithErrorHandling(() async {
        await _transactionRepository.updateTransaction(state.editingTransaction!);

        // Notifier l'Event Bus
        final eventBus = AppEventBus.instance;
        eventBus.fire(TransactionUpdatedEvent(
          updatedTransaction: state.editingTransaction!,
          accountId: state.editingTransaction!.accountId,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_transaction_updated',
        ));

        // Mettre à jour l'état pour refléter la sauvegarde
        state = state.copyWith(
          originalTransaction: state.editingTransaction,
          isSaved: true,
          isUpdating: false,
        );
      });

      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false);
      return false;
    }
  }

  /// Annule les modifications et revient à la transaction originale
  void cancelChanges() {
    if (state.originalTransaction == null) return;
    
    state = state.copyWith(
      editingTransaction: state.originalTransaction,
      isSaved: false,
      clearValidationMessage: true,
    );
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  String? _validateAmount(double amount) {
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    if (amount > 999999999) {
      return 'Le montant est trop élevé';
    }
    return null;
  }

  /// Valide tous les champs de la transaction
  String? validateTransaction() {
    if (state.editingTransaction == null) {
      return 'Aucune transaction à valider';
    }

    final transaction = state.editingTransaction!;
    
    final amountError = _validateAmount(transaction.amount);
    if (amountError != null) return amountError;
    
    if (transaction.currency.isEmpty) {
      return 'La devise est requise';
    }
    
    return null;
  }

  // ============================================================================
  // GETTERS UTILITAIRES
  // ============================================================================

  /// ID de la transaction en cours d'édition
  int get transactionId => _transactionId;

  /// Transaction originale (avant modifications)
  domain.Transaction? get originalTransaction => state.originalTransaction;

  /// Transaction en cours d'édition
  domain.Transaction? get editingTransaction => state.editingTransaction;

  /// Type de transaction actuel
  domain.TransactionType? get currentType => state.editingTransaction?.type;

  /// Montant actuel
  double? get currentAmount => state.editingTransaction?.amount;

  /// Devise actuelle
  String? get currentCurrency => state.editingTransaction?.currency;

  /// Titre actuel
  String? get currentTitle => state.editingTransaction?.title;

  /// Commentaire actuel
  String? get currentComment => state.editingTransaction?.comment;

  /// Date actuelle
  DateTime? get currentDate => state.editingTransaction?.date;

  /// ID du compte actuel
  int? get currentAccountId => state.editingTransaction?.accountId;

  /// ID de la contrepartie actuelle
  int? get currentCounterpartyId => state.editingTransaction?.counterpartyId;

  /// IDs des catégories actuelles
  List<int> get currentCategoryIds {
    final transaction = state.editingTransaction;
    if (transaction == null) return [];
    
    final categoryIds = <int>[];
    if (transaction.category1Id != null) categoryIds.add(transaction.category1Id!);
    if (transaction.category2Id != null) categoryIds.add(transaction.category2Id!);
    if (transaction.category3Id != null) categoryIds.add(transaction.category3Id!);
    if (transaction.category4Id != null) categoryIds.add(transaction.category4Id!);
    
    return categoryIds;
  }

  /// Statut actuel
  domain.TransactionStatus? get currentStatus => state.editingTransaction?.status;
}