import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// État pour le TransactionDeletionViewModel - gestion de la suppression d'une transaction
class TransactionDeletionViewState extends BaseViewState {
  /// Transaction à supprimer
  final domain.Transaction? transaction;
  
  /// Indique si l'opération de suppression est en cours
  final bool isDeleting;
  
  /// Indique si la suppression a été confirmée par l'utilisateur
  final bool isConfirmed;
  
  /// Indique si la suppression a été complétée avec succès
  final bool isDeleted;
  
  /// Message de confirmation personnalisé (optionnel)
  final String? confirmationMessage;

  const TransactionDeletionViewState({
    this.transaction,
    this.isDeleting = false,
    this.isConfirmed = false,
    this.isDeleted = false,
    this.confirmationMessage,
  });

  TransactionDeletionViewState copyWith({
    domain.Transaction? transaction,
    bool? isDeleting,
    bool? isConfirmed,
    bool? isDeleted,
    String? confirmationMessage,
    bool clearTransaction = false,
    bool clearConfirmationMessage = false,
  }) {
    return TransactionDeletionViewState(
      transaction: clearTransaction ? null : (transaction ?? this.transaction),
      isDeleting: isDeleting ?? this.isDeleting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isDeleted: isDeleted ?? this.isDeleted,
      confirmationMessage: clearConfirmationMessage ? null : (confirmationMessage ?? this.confirmationMessage),
    );
  }

  // États dérivés
  bool get hasTransaction => transaction != null;
  bool get canDelete => hasTransaction && !isDeleting && !isDeleted;
  bool get needsConfirmation => hasTransaction && !isConfirmed && !isDeleted;
  bool get isLoading => isDeleting;

  /// Message de confirmation par défaut basé sur la transaction
  String get defaultConfirmationMessage {
    if (transaction == null) return 'Êtes-vous sûr de vouloir supprimer cette transaction ?';
    
    final title = transaction!.title?.isNotEmpty == true 
        ? transaction!.title! 
        : 'cette transaction';
    return 'Êtes-vous sûr de vouloir supprimer "$title" ? Cette action est irréversible.';
  }

  /// Message à afficher pour la confirmation
  String get displayConfirmationMessage => 
      confirmationMessage ?? defaultConfirmationMessage;

  List<Object?> get props => [
    transaction,
    isDeleting,
    isConfirmed,
    isDeleted,
    confirmationMessage,
  ];
}

/// ViewModel pour la suppression d'une transaction
/// Suit l'architecture MVVM par use case - se concentre uniquement sur la suppression
class TransactionDeletionViewModel extends BaseViewModel<TransactionDeletionViewState> {
  final int _transactionId;
  final TransactionRepository _transactionRepository;
  StreamSubscription<TransactionEvent>? _eventSubscription;

  TransactionDeletionViewModel(
    this._transactionId,
    this._transactionRepository,
  ) : super(const TransactionDeletionViewState()) {
    _initializeEventBus();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  void resetToInitialState() {
    state = const TransactionDeletionViewState();
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
    // Si la transaction à supprimer est modifiée ailleurs, recharger
    if (event is TransactionUpdatedEvent && event.updatedTransaction.id == _transactionId) {
      _handleTransactionUpdated(event);
    } else if (event is TransactionDeletedEvent && event.transactionId == _transactionId) {
      _handleTransactionDeleted(event);
    }
  }

  void _handleTransactionUpdated(TransactionUpdatedEvent event) {
    // La transaction a été modifiée ailleurs, mettre à jour
    state = state.copyWith(transaction: event.updatedTransaction);
  }

  void _handleTransactionDeleted(TransactionDeletedEvent event) {
    // La transaction a été supprimée ailleurs, marquer comme supprimée
    state = state.copyWith(isDeleted: true, isDeleting: false);
  }

  // ============================================================================
  // CHARGEMENT ET INITIALISATION
  // ============================================================================

  /// Initialise la suppression en chargeant la transaction
  Future<void> initialize() async {
    await loadTransaction();
  }

  /// Charge la transaction à supprimer
  Future<void> loadTransaction() async {
    try {
      final transaction = await _transactionRepository.getTransactionById(_transactionId);
      
      if (transaction == null) {
        // Transaction not found - keep state as null
        return;
      }

      state = state.copyWith(
        transaction: transaction,
        isConfirmed: false,
        isDeleted: false,
      );
    } catch (error) {
      // Log error but don't crash - keep transaction as null
      if (kDebugMode) {
        print('Error loading transaction: $error');
      }
    }
  }

  /// Rafraîchit les données de la transaction
  Future<void> refresh() async {
    await loadTransaction();
  }

  // ============================================================================
  // GESTION DE LA CONFIRMATION
  // ============================================================================

  /// Confirme l'intention de supprimer la transaction
  void confirmDeletion() {
    if (!state.hasTransaction || state.isDeleted) return;
    
    state = state.copyWith(isConfirmed: true);
  }

  /// Annule la confirmation de suppression
  void cancelConfirmation() {
    state = state.copyWith(isConfirmed: false);
  }

  /// Définit un message de confirmation personnalisé
  void setConfirmationMessage(String? message) {
    state = state.copyWith(
      confirmationMessage: message,
      clearConfirmationMessage: message == null,
    );
  }

  // ============================================================================
  // SUPPRESSION
  // ============================================================================

  /// Supprime la transaction (avec confirmation automatique si pas déjà confirmée)
  Future<bool> deleteTransaction({bool skipConfirmation = false}) async {
    if (!state.hasTransaction || state.isDeleting || state.isDeleted) return false;

    // Si pas encore confirmé et pas de skip, confirmer d'abord
    if (!skipConfirmation && !state.isConfirmed) {
      confirmDeletion();
    }

    state = state.copyWith(isDeleting: true);

    try {
      await _transactionRepository.deleteTransaction(_transactionId);

      // Notifier l'Event Bus
      final eventBus = AppEventBus.instance;
      eventBus.fire(TransactionDeletedEvent(
        transactionId: _transactionId,
        accountId: state.transaction!.accountId,
        deletedTransaction: state.transaction!,
        timestamp: DateTime.now(),
        eventId: '${DateTime.now().millisecondsSinceEpoch}_transaction_deleted',
      ));

      // Marquer comme supprimée
      state = state.copyWith(
        isDeleted: true,
        isDeleting: false,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting transaction: $e');
      }
      state = state.copyWith(isDeleting: false);
      return false;
    }
  }

  /// Supprime la transaction sans demander de confirmation
  Future<bool> forceDelete() async {
    return await deleteTransaction(skipConfirmation: true);
  }

  /// Supprime la transaction avec confirmation préalable
  Future<bool> deleteWithConfirmation() async {
    if (!state.isConfirmed) {
      confirmDeletion();
    }
    return await deleteTransaction();
  }

  // ============================================================================
  // GETTERS UTILITAIRES
  // ============================================================================

  /// ID de la transaction à supprimer
  int get transactionId => _transactionId;

  /// Transaction à supprimer
  domain.Transaction? get transaction => state.transaction;

  /// Titre de la transaction (pour affichage)
  String get transactionTitle => state.transaction?.title ?? 'Transaction';

  /// Montant de la transaction (pour affichage)
  double? get transactionAmount => state.transaction?.amount;

  /// Devise de la transaction (pour affichage)
  String? get transactionCurrency => state.transaction?.currency;

  /// Date de la transaction (pour affichage)
  DateTime? get transactionDate => state.transaction?.date;

  /// Type de transaction (pour affichage)
  domain.TransactionType? get transactionType => state.transaction?.type;

  /// Indique si la transaction est une dépense
  bool get isExpense => state.transaction?.isExpense ?? false;

  /// Indique si la transaction est un revenu
  bool get isIncome => state.transaction?.isIncome ?? false;

  /// Statut actuel de la confirmation
  bool get isConfirmed => state.isConfirmed;

  /// Statut actuel de la suppression
  bool get isDeleting => state.isDeleting;

  /// Indique si la suppression est terminée
  bool get isDeleted => state.isDeleted;

  /// Indique si la suppression peut être effectuée
  bool get canDelete => state.canDelete;

  /// Indique si une confirmation est nécessaire
  bool get needsConfirmation => state.needsConfirmation;

  /// Message de confirmation à afficher
  String get confirmationMessage => state.displayConfirmationMessage;
}