import 'package:bankapp/core/events/app_events.dart';
import 'package:bankapp/domain/entities/transaction.dart';

/// Événements liés aux transactions
abstract class TransactionEvent extends AppEvent {
  /// ID du compte concerné par l'événement
  final int accountId;
  
  const TransactionEvent({
    required this.accountId,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, accountId];
}

/// Événement de création d'une nouvelle transaction
class TransactionCreatedEvent extends TransactionEvent {
  /// Transaction qui vient d'être créée
  final Transaction transaction;
  
  /// Contexte de création (ex: "bottom_sheet", "import", "sync")
  final String? context;
  
  const TransactionCreatedEvent({
    required this.transaction,
    required super.accountId,
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, transaction, context];
  
  @override
  String toString() => 'TransactionCreatedEvent(transactionId: ${transaction.id}, accountId: $accountId, context: $context)';
}

/// Événement de modification d'une transaction existante
class TransactionUpdatedEvent extends TransactionEvent {
  /// Transaction après modification
  final Transaction updatedTransaction;
  
  /// Transaction avant modification (pour rollback éventuel)
  final Transaction? previousTransaction;
  
  /// Champs qui ont été modifiés
  final List<String> modifiedFields;
  
  /// Contexte de modification
  final String? context;
  
  const TransactionUpdatedEvent({
    required this.updatedTransaction,
    required super.accountId,
    this.previousTransaction,
    this.modifiedFields = const [],
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [
    ...super.props, 
    updatedTransaction, 
    previousTransaction,
    modifiedFields,
    context
  ];
  
  @override
  String toString() => 'TransactionUpdatedEvent(transactionId: ${updatedTransaction.id}, fields: $modifiedFields)';
}

/// Événement de suppression d'une transaction
class TransactionDeletedEvent extends TransactionEvent {
  /// ID de la transaction supprimée
  final int transactionId;
  
  /// Transaction supprimée (pour rollback éventuel)
  final Transaction? deletedTransaction;
  
  /// Contexte de suppression
  final String? context;
  
  const TransactionDeletedEvent({
    required this.transactionId,
    required super.accountId,
    this.deletedTransaction,
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, transactionId, deletedTransaction, context];
  
  @override
  String toString() => 'TransactionDeletedEvent(transactionId: $transactionId, accountId: $accountId)';
}

/// Événement de changement de statut de suivi d'une transaction
class TransactionFollowStatusChangedEvent extends TransactionEvent {
  /// ID de la transaction concernée
  final int transactionId;
  
  /// Nouveau statut de suivi
  final bool isFollowed;
  
  const TransactionFollowStatusChangedEvent({
    required this.transactionId,
    required this.isFollowed,
    required super.accountId,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, transactionId, isFollowed];
  
  @override
  String toString() => 'TransactionFollowStatusChangedEvent(transactionId: $transactionId, isFollowed: $isFollowed)';
}

/// Événement de changement de statut d'une transaction (pending/completed)
class TransactionStatusChangedEvent extends TransactionEvent {
  /// ID de la transaction concernée
  final int transactionId;
  
  /// Nouveau statut
  final TransactionStatus newStatus;
  
  /// Ancien statut
  final TransactionStatus? previousStatus;
  
  const TransactionStatusChangedEvent({
    required this.transactionId,
    required this.newStatus,
    required super.accountId,
    this.previousStatus,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, transactionId, newStatus, previousStatus];
  
  @override
  String toString() => 'TransactionStatusChangedEvent(transactionId: $transactionId, status: $previousStatus -> $newStatus)';
}

/// Événement de rechargement des transactions pour un compte
class TransactionsRefreshedEvent extends TransactionEvent {
  /// Nombre de transactions chargées
  final int transactionCount;
  
  /// Contexte du rechargement
  final String? context;
  
  const TransactionsRefreshedEvent({
    required this.transactionCount,
    required super.accountId,
    this.context,
    required super.timestamp,
    required super.eventId,
  });
  
  @override
  List<Object?> get props => [...super.props, transactionCount, context];
  
  @override
  String toString() => 'TransactionsRefreshedEvent(accountId: $accountId, count: $transactionCount)';
}

/// Factory pour créer les événements de transaction avec des IDs uniques
class TransactionEventFactory {
  static int _counter = 0;
  
  static String _generateEventId(String eventType) {
    _counter++;
    return '${eventType}_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }
  
  /// Crée un événement de création de transaction
  static TransactionCreatedEvent createTransactionCreatedEvent({
    required Transaction transaction,
    required int accountId,
    String? context,
  }) {
    return TransactionCreatedEvent(
      transaction: transaction,
      accountId: accountId,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTION_CREATED'),
    );
  }
  
  /// Crée un événement de modification de transaction
  static TransactionUpdatedEvent createTransactionUpdatedEvent({
    required Transaction updatedTransaction,
    required int accountId,
    Transaction? previousTransaction,
    List<String> modifiedFields = const [],
    String? context,
  }) {
    return TransactionUpdatedEvent(
      updatedTransaction: updatedTransaction,
      accountId: accountId,
      previousTransaction: previousTransaction,
      modifiedFields: modifiedFields,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTION_UPDATED'),
    );
  }
  
  /// Crée un événement de suppression de transaction
  static TransactionDeletedEvent createTransactionDeletedEvent({
    required int transactionId,
    required int accountId,
    Transaction? deletedTransaction,
    String? context,
  }) {
    return TransactionDeletedEvent(
      transactionId: transactionId,
      accountId: accountId,
      deletedTransaction: deletedTransaction,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTION_DELETED'),
    );
  }
  
  /// Crée un événement de changement de statut de suivi
  static TransactionFollowStatusChangedEvent createTransactionFollowStatusChangedEvent({
    required int transactionId,
    required bool isFollowed,
    required int accountId,
  }) {
    return TransactionFollowStatusChangedEvent(
      transactionId: transactionId,
      isFollowed: isFollowed,
      accountId: accountId,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTION_FOLLOW_CHANGED'),
    );
  }
  
  /// Crée un événement de changement de statut de transaction
  static TransactionStatusChangedEvent createTransactionStatusChangedEvent({
    required int transactionId,
    required TransactionStatus newStatus,
    required int accountId,
    TransactionStatus? previousStatus,
  }) {
    return TransactionStatusChangedEvent(
      transactionId: transactionId,
      newStatus: newStatus,
      accountId: accountId,
      previousStatus: previousStatus,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTION_STATUS_CHANGED'),
    );
  }
  
  /// Crée un événement de rechargement de transactions
  static TransactionsRefreshedEvent createTransactionsRefreshedEvent({
    required int accountId,
    required int transactionCount,
    String? context,
  }) {
    return TransactionsRefreshedEvent(
      accountId: accountId,
      transactionCount: transactionCount,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('TRANSACTIONS_REFRESHED'),
    );
  }
}