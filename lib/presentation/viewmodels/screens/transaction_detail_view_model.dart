import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/account_repository.dart';
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/viewmodels/base/base_view_model.dart';
import 'dart:async';

/// État pour le TransactionDetailViewModel - gestion des détails d'une transaction
class TransactionDetailViewState extends BaseViewState {
  /// Transaction de base
  final domain.Transaction? transaction;
  
  /// Compte associé à la transaction
  final domain.Account? account;
  
  /// Indique si la transaction est suivie
  final bool isFollowed;
  
  /// Indique si une opération est en cours (toggle, delete, etc.)
  final bool isProcessing;

  const TransactionDetailViewState({
    this.transaction,
    this.account,
    this.isFollowed = false,
    this.isProcessing = false,
  });

  TransactionDetailViewState copyWith({
    domain.Transaction? transaction,
    domain.Account? account,
    bool? isFollowed,
    bool? isProcessing,
    bool clearTransaction = false,
    bool clearAccount = false,
  }) {
    return TransactionDetailViewState(
      transaction: clearTransaction ? null : (transaction ?? this.transaction),
      account: clearAccount ? null : (account ?? this.account),
      isFollowed: isFollowed ?? this.isFollowed,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  // États dérivés
  bool get hasTransaction => transaction != null;
  bool get hasAccount => account != null;
  
  /// Indique si la transaction est une dépense
  bool get isExpense => transaction?.isExpense ?? false;
  
  /// Indique si la transaction est un revenu
  bool get isIncome => transaction?.isIncome ?? false;
  
  /// Indique si la transaction est complétée
  bool get isCompleted => transaction?.isCompleted ?? false;
  
  /// Indique si la transaction est en attente
  bool get isPending => transaction?.isPending ?? false;
  
  /// Obtient le montant formaté avec le signe
  double get signedAmount => transaction?.signedAmount ?? 0.0;
}

/// ViewModel pour l'écran de détail d'une transaction
/// 
/// Ce ViewModel gère :
/// - Le chargement des détails d'une transaction
/// - Les opérations CRUD (toggle status, delete, edit)
/// - Le suivi des transactions (follow/unfollow)
/// - La communication avec l'Event Bus pour la réactivité
class TransactionDetailViewModel extends BaseViewModel<TransactionDetailViewState> {
  final int _transactionId;
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  StreamSubscription<TransactionEvent>? _transactionEventSubscription;

  TransactionDetailViewModel(
    this._transactionId,
    this._transactionRepository,
    this._accountRepository,
  ) : super(const TransactionDetailViewState()) {
    _subscribeToEvents();
  }

  // ============================================================================
  // GESTION DES ÉVÉNEMENTS EVENT BUS
  // ============================================================================

  void _subscribeToEvents() {
    final eventBus = AppEventBus.instance;

    // Écouter les événements de transactions
    _transactionEventSubscription = eventBus.transactionEvents.listen((event) {
      _handleTransactionEvent(event);
    });
  }

  void _handleTransactionEvent(TransactionEvent event) {
    // Si l'événement concerne notre transaction, recharger
    if (event is TransactionUpdatedEvent && event.updatedTransaction.id == _transactionId) {
      _handleTransactionUpdated(event);
    } else if (event is TransactionDeletedEvent && event.transactionId == _transactionId) {
      _handleTransactionDeleted(event);
    } else if (event is TransactionFollowStatusChangedEvent && event.transactionId == _transactionId) {
      _handleFollowStatusChanged(event);
    }
  }

  void _handleTransactionUpdated(TransactionUpdatedEvent event) {
    // Recharger les détails de la transaction
    loadTransactionDetails();
  }

  void _handleTransactionDeleted(TransactionDeletedEvent event) {
    // Vider l'état car la transaction n'existe plus
    state = state.copyWith(clearTransaction: true, clearAccount: true);
  }

  void _handleFollowStatusChanged(TransactionFollowStatusChangedEvent event) {
    // Mettre à jour le statut de suivi
    state = state.copyWith(isFollowed: event.isFollowed);
  }

  // ============================================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================================

  /// Initialise le ViewModel et charge les détails de la transaction
  Future<void> initialize() async {
    await loadTransactionDetails();
  }

  /// Charge les détails complets de la transaction
  Future<void> loadTransactionDetails() async {
    await executeWithErrorHandling(() async {
      // Charger la transaction
      final transaction = await _transactionRepository.getTransactionById(_transactionId);
      
      if (transaction == null) {
        throw Exception('Transaction non trouvée');
      }

      // Charger le compte associé
      final account = await _accountRepository.getAccountById(
        transaction.accountId,
      );

      // Vérifier si la transaction est suivie
      final isFollowed = await _transactionRepository.isTransactionFollowed(_transactionId);

      state = state.copyWith(
        transaction: transaction,
        account: account,
        isFollowed: isFollowed,
      );
    });
  }

  /// Rafraîchit les données de la transaction
  Future<void> refresh() async {
    await loadTransactionDetails();
  }

  // ============================================================================
  // OPÉRATIONS CRUD
  // ============================================================================

  /// Bascule le statut de la transaction (completed/pending)
  Future<bool> toggleTransactionStatus() async {
    if (!state.hasTransaction || state.isProcessing) return false;

    state = state.copyWith(isProcessing: true);

    try {
      await executeWithErrorHandling(() async {
        await _transactionRepository.toggleTransactionStatus(_transactionId);

        // Notifier l'Event Bus
        final eventBus = AppEventBus.instance;
        eventBus.fire(TransactionUpdatedEvent(
          updatedTransaction: state.transaction!,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_transaction_status_toggled',
          accountId: state.transaction!.accountId,
        ));

        // Recharger les données
        await loadTransactionDetails();
      });

      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Supprime la transaction
  Future<bool> deleteTransaction() async {
    if (!state.hasTransaction || state.isProcessing) return false;

    state = state.copyWith(isProcessing: true);

    try {
      await executeWithErrorHandling(() async {
        final transaction = state.transaction!;
        
        await _transactionRepository.deleteTransaction(_transactionId);

        // Notifier l'Event Bus
        final eventBus = AppEventBus.instance;
        eventBus.fire(TransactionDeletedEvent(
          transactionId: _transactionId,
          deletedTransaction: transaction,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_transaction_deleted',
          accountId: transaction.accountId,
        ));
      });

      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Bascule le suivi de la transaction (follow/unfollow)
  Future<bool> toggleFollowTransaction() async {
    if (!state.hasTransaction || state.isProcessing) return false;

    state = state.copyWith(isProcessing: true);
    final currentFollowStatus = state.isFollowed;

    try {
      await executeWithErrorHandling(() async {
        if (currentFollowStatus) {
          await _transactionRepository.unfollowTransaction(_transactionId);
        } else {
          await _transactionRepository.followTransaction(_transactionId);
        }

        // Notifier l'Event Bus du changement de statut de suivi
        final eventBus = AppEventBus.instance;
        eventBus.fire(TransactionFollowStatusChangedEvent(
          transactionId: _transactionId,
          isFollowed: !currentFollowStatus,
          accountId: state.transaction!.accountId,
          timestamp: DateTime.now(),
          eventId: '${DateTime.now().millisecondsSinceEpoch}_follow_toggled',
        ));

        // Mettre à jour l'état local
        state = state.copyWith(isFollowed: !currentFollowStatus);
      });

      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  // ============================================================================
  // GETTERS UTILITAIRES
  // ============================================================================

  /// Obtient l'ID de la transaction
  int get transactionId => _transactionId;

  /// Indique si la transaction peut être modifiée
  bool get canEdit => state.hasTransaction && !state.isProcessing;

  /// Indique si la transaction peut être supprimée
  bool get canDelete => state.hasTransaction && !state.isProcessing;

  /// Indique si le suivi peut être basculé
  bool get canToggleFollow => state.hasTransaction && !state.isProcessing;

  /// Indique si le statut peut être basculé
  bool get canToggleStatus => state.hasTransaction && !state.isProcessing;

  /// Obtient le nom du compte ou une valeur par défaut
  String get accountName => state.account?.name ?? 'Compte inconnu';

  /// Obtient la devise de la transaction
  String get currency => state.transaction?.currency ?? 'EUR';

  /// Obtient le titre de la transaction ou une valeur par défaut
  String get title => state.transaction?.title ?? 'Transaction';

  /// Obtient le commentaire de la transaction
  String get comment => state.transaction?.comment ?? '';

  /// Indique si la transaction a un commentaire
  bool get hasComment => state.transaction?.comment?.isNotEmpty == true;

  /// Indique si la transaction a été convertie
  bool get isConverted => state.transaction?.isConverted == true;

  /// Obtient le montant avant conversion
  double? get amountBeforeConversion => state.transaction?.amountBeforeConversion;

  /// Obtient la devise avant conversion
  String? get currencyBeforeConversion => state.transaction?.currencyBeforeConversion;

  /// Obtient la date de la transaction
  DateTime? get transactionDate => state.transaction?.date;

  // ============================================================================
  // GESTION DU CYCLE DE VIE
  // ============================================================================

  @override
  void resetToInitialState() {
    state = const TransactionDetailViewState();
  }

  @override
  void dispose() {
    _transactionEventSubscription?.cancel();
    super.dispose();
  }
}