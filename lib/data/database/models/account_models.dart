/// Classe helper pour représenter un résumé de compte
class AccountSummary {
  final dynamic account; // Type générique pour compatibilité avec Drift
  final double currentBalance;
  final double confirmedBalance;
  final double totalExpenses;
  final double totalRevenues;

  const AccountSummary({
    required this.account,
    required this.currentBalance,
    required this.confirmedBalance,
    required this.totalExpenses,
    required this.totalRevenues,
  });

  /// Calcule le pourcentage de variation du solde
  double getBalanceChangePercentage() {
    if (confirmedBalance == 0) return 0.0;
    final difference = currentBalance - confirmedBalance;
    return (difference / confirmedBalance) * 100;
  }

  /// Calcule le solde net (revenus - dépenses)
  double get netBalance => totalRevenues - totalExpenses;

  /// Indique si le compte est en déficit
  bool get isInDeficit => currentBalance < 0;

  /// Indique si le compte a des transactions en attente
  bool get hasPendingTransactions => currentBalance != confirmedBalance;

  @override
  String toString() => 'AccountSummary(account: $account, currentBalance: $currentBalance, confirmedBalance: $confirmedBalance, totalExpenses: $totalExpenses, totalRevenues: $totalRevenues)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSummary &&
          runtimeType == other.runtimeType &&
          account == other.account &&
          currentBalance == other.currentBalance &&
          confirmedBalance == other.confirmedBalance &&
          totalExpenses == other.totalExpenses &&
          totalRevenues == other.totalRevenues;

  @override
  int get hashCode => 
      account.hashCode ^
      currentBalance.hashCode ^
      confirmedBalance.hashCode ^
      totalExpenses.hashCode ^
      totalRevenues.hashCode;
}