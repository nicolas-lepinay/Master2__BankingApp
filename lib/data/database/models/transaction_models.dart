
/// Classe helper pour représenter une transaction avec son solde après opération
class TransactionWithBalance {
  final dynamic transaction; // Type générique pour compatibilité avec Drift
  final double balanceAfter;

  const TransactionWithBalance({
    required this.transaction,
    required this.balanceAfter,
  });

  @override
  String toString() => 'TransactionWithBalance(transaction: $transaction, balanceAfter: $balanceAfter)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionWithBalance &&
          runtimeType == other.runtimeType &&
          transaction == other.transaction &&
          balanceAfter == other.balanceAfter;

  @override
  int get hashCode => transaction.hashCode ^ balanceAfter.hashCode;
}

/// Classe helper pour représenter une transaction avec sa contrepartie
class TransactionWithCounterparty {
  final dynamic transaction; // Type générique pour compatibilité avec Drift
  final String? counterpartyName;
  final String? counterpartyIcon;

  const TransactionWithCounterparty({
    required this.transaction,
    this.counterpartyName,
    this.counterpartyIcon,
  });

  @override
  String toString() => 'TransactionWithCounterparty(transaction: $transaction, counterpartyName: $counterpartyName, counterpartyIcon: $counterpartyIcon)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionWithCounterparty &&
          runtimeType == other.runtimeType &&
          transaction == other.transaction &&
          counterpartyName == other.counterpartyName &&
          counterpartyIcon == other.counterpartyIcon;

  @override
  int get hashCode => transaction.hashCode ^ counterpartyName.hashCode ^ counterpartyIcon.hashCode;
}