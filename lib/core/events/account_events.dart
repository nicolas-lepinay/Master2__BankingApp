import 'package:bankapp/core/events/app_events.dart';
import 'package:bankapp/domain/entities/account.dart';

/// Événements liés aux comptes
abstract class AccountEvent extends AppEvent {
  /// ID du compte concerné
  final int accountId;

  const AccountEvent({
    required this.accountId,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, accountId];
}

/// Événement de création d'un nouveau compte
class AccountCreatedEvent extends AccountEvent {
  /// Compte qui vient d'être créé
  final Account account;

  /// Contexte de création
  final String? context;

  AccountCreatedEvent({
    required this.account,
    this.context,
    required super.timestamp,
    required super.eventId,
  }) : super(accountId: account.id);

  @override
  List<Object?> get props => [...super.props, account, context];

  @override
  String toString() =>
      'AccountCreatedEvent(accountId: ${account.id}, name: ${account.name})';
}

/// Événement de modification d'un compte existant
class AccountUpdatedEvent extends AccountEvent {
  /// Compte après modification
  final Account updatedAccount;

  /// Compte avant modification (pour rollback éventuel)
  final Account? previousAccount;

  /// Champs qui ont été modifiés
  final List<String> modifiedFields;

  /// Contexte de modification
  final String? context;

  AccountUpdatedEvent({
    required this.updatedAccount,
    this.previousAccount,
    this.modifiedFields = const [],
    this.context,
    required DateTime timestamp,
    required String eventId,
  }) : super(
         accountId: updatedAccount.id,
         timestamp: timestamp,
         eventId: eventId,
       );

  @override
  List<Object?> get props => [
    ...super.props,
    updatedAccount,
    previousAccount,
    modifiedFields,
    context,
  ];

  @override
  String toString() =>
      'AccountUpdatedEvent(accountId: ${updatedAccount.id}, fields: $modifiedFields)';
}

/// Événement de suppression d'un compte
class AccountDeletedEvent extends AccountEvent {
  /// Compte supprimé (pour rollback éventuel)
  final Account? deletedAccount;

  /// Contexte de suppression
  final String? context;

  const AccountDeletedEvent({
    required super.accountId,
    this.deletedAccount,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, deletedAccount, context];

  @override
  String toString() => 'AccountDeletedEvent(accountId: $accountId)';
}

/// Événement déclenché lorsqu'un logo de Counterparty a été téléchargé
class CounterpartyLogoDownloadedEvent extends AccountEvent {
  /// ID du Counterparty dont le logo a été téléchargé
  final int counterpartyId;

  /// Nom du Counterparty pour logging
  final String? counterpartyName;

  /// Chemin du logo téléchargé
  final String? logoPath;

  const CounterpartyLogoDownloadedEvent({
    required this.counterpartyId,
    this.counterpartyName,
    this.logoPath,
    required super.accountId,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    counterpartyId,
    counterpartyName,
    logoPath,
  ];

  @override
  String toString() =>
      'CounterpartyLogoDownloadedEvent(counterpartyId: $counterpartyId, accountId: $accountId)';
}

/// Événement de sélection d'un compte (changement de compte actuel)
class AccountSelectedEvent extends AccountEvent {
  /// ID du compte précédemment sélectionné
  final int? previousAccountId;

  /// Contexte de sélection (ex: "user_swipe", "navigation", "deep_link")
  final String? context;

  const AccountSelectedEvent({
    required super.accountId,
    this.previousAccountId,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, previousAccountId, context];

  @override
  String toString() =>
      'AccountSelectedEvent(from: $previousAccountId, to: $accountId)';
}

/// Événement de mise à jour du solde d'un compte
class AccountBalanceUpdatedEvent extends AccountEvent {
  /// Nouveau solde
  final double newBalance;

  /// Ancien solde
  final double? previousBalance;

  /// Devise du compte
  final String currency;

  /// Contexte de mise à jour (ex: "transaction_created", "sync", "manual")
  final String? context;

  const AccountBalanceUpdatedEvent({
    required super.accountId,
    required this.newBalance,
    required this.currency,
    this.previousBalance,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    newBalance,
    previousBalance,
    currency,
    context,
  ];

  @override
  String toString() =>
      'AccountBalanceUpdatedEvent(accountId: $accountId, balance: $previousBalance -> $newBalance $currency)';
}

/// Événement de rechargement des données d'un compte
class AccountRefreshedEvent extends AccountEvent {
  /// Contexte du rechargement
  final String? context;

  /// Données qui ont été rechargées
  final List<String> refreshedData;

  const AccountRefreshedEvent({
    required super.accountId,
    this.context,
    this.refreshedData = const ['summary', 'transactions'],
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, context, refreshedData];

  @override
  String toString() =>
      'AccountRefreshedEvent(accountId: $accountId, data: $refreshedData)';
}

/// Événement de rechargement de tous les comptes
class AllAccountsRefreshedEvent extends GlobalAppEvent {
  /// Nombre de comptes chargés
  final int accountCount;

  /// Contexte du rechargement
  final String? context;

  const AllAccountsRefreshedEvent({
    required this.accountCount,
    this.context,
    required super.timestamp,
    required super.eventId,
  });

  @override
  List<Object?> get props => [...super.props, accountCount, context];

  @override
  String toString() => 'AllAccountsRefreshedEvent(count: $accountCount)';
}

/// Factory pour créer les événements de compte avec des IDs uniques
class AccountEventFactory {
  static int _counter = 0;

  static String _generateEventId(String eventType) {
    _counter++;
    return '${eventType}_${DateTime.now().millisecondsSinceEpoch}_$_counter';
  }

  /// Crée un événement de création de compte
  static AccountCreatedEvent createAccountCreatedEvent({
    required Account account,
    String? context,
  }) {
    return AccountCreatedEvent(
      account: account,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_CREATED'),
    );
  }

  /// Crée un événement de modification de compte
  static AccountUpdatedEvent createAccountUpdatedEvent({
    required Account updatedAccount,
    Account? previousAccount,
    List<String> modifiedFields = const [],
    String? context,
  }) {
    return AccountUpdatedEvent(
      updatedAccount: updatedAccount,
      previousAccount: previousAccount,
      modifiedFields: modifiedFields,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_UPDATED'),
    );
  }

  /// Crée un événement de suppression de compte
  static AccountDeletedEvent createAccountDeletedEvent({
    required int accountId,
    Account? deletedAccount,
    String? context,
  }) {
    return AccountDeletedEvent(
      accountId: accountId,
      deletedAccount: deletedAccount,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_DELETED'),
    );
  }

  /// Crée un événement de sélection de compte
  static AccountSelectedEvent createAccountSelectedEvent({
    required int accountId,
    int? previousAccountId,
    String? context,
  }) {
    return AccountSelectedEvent(
      accountId: accountId,
      previousAccountId: previousAccountId,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_SELECTED'),
    );
  }

  /// Crée un événement de mise à jour du solde
  static AccountBalanceUpdatedEvent createAccountBalanceUpdatedEvent({
    required int accountId,
    required double newBalance,
    required String currency,
    double? previousBalance,
    String? context,
  }) {
    return AccountBalanceUpdatedEvent(
      accountId: accountId,
      newBalance: newBalance,
      currency: currency,
      previousBalance: previousBalance,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_BALANCE_UPDATED'),
    );
  }

  /// Crée un événement de rechargement de compte
  static AccountRefreshedEvent createAccountRefreshedEvent({
    required int accountId,
    String? context,
    List<String> refreshedData = const ['summary', 'transactions'],
  }) {
    return AccountRefreshedEvent(
      accountId: accountId,
      context: context,
      refreshedData: refreshedData,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ACCOUNT_REFRESHED'),
    );
  }

  /// Crée un événement de rechargement de tous les comptes
  static AllAccountsRefreshedEvent createAllAccountsRefreshedEvent({
    required int accountCount,
    String? context,
  }) {
    return AllAccountsRefreshedEvent(
      accountCount: accountCount,
      context: context,
      timestamp: DateTime.now(),
      eventId: _generateEventId('ALL_ACCOUNTS_REFRESHED'),
    );
  }
}
