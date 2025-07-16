import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/transaction_with_balance.dart';
import 'package:bankapp/domain/value_objects/account_balance.dart';
import 'package:bankapp/domain/value_objects/date_range.dart';
import 'package:bankapp/domain/value_objects/money.dart';
import 'package:equatable/equatable.dart';

class AccountSummary extends Equatable {
  final Account account;
  final AccountBalance currentBalance;
  final List<TransactionWithBalance> recentTransactions;
  final int totalTransactionsCount;
  final Money totalIncome;
  final Money totalExpenses;
  final DateTime lastTransactionDate;

  const AccountSummary({
    required this.account,
    required this.currentBalance,
    required this.recentTransactions,
    required this.totalTransactionsCount,
    required this.totalIncome,
    required this.totalExpenses,
    required this.lastTransactionDate,
  });

  AccountSummary copyWith({
    Account? account,
    AccountBalance? currentBalance,
    List<TransactionWithBalance>? recentTransactions,
    int? totalTransactionsCount,
    Money? totalIncome,
    Money? totalExpenses,
    DateTime? lastTransactionDate,
  }) {
    return AccountSummary(
      account: account ?? this.account,
      currentBalance: currentBalance ?? this.currentBalance,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      totalTransactionsCount:
          totalTransactionsCount ?? this.totalTransactionsCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }

  Money get netAmount => totalIncome.subtract(totalExpenses);

  bool get hasTransactions => totalTransactionsCount > 0;
  bool get hasRecentTransactions => recentTransactions.isNotEmpty;

  String get displayCurrentBalance =>
      '${currentBalance.amount.toStringAsFixed(2)} ${currentBalance.currency}';

  String get displayTotalIncome =>
      '+${totalIncome.amount.toStringAsFixed(2)} ${totalIncome.currency}';

  String get displayTotalExpenses =>
      '-${totalExpenses.amount.toStringAsFixed(2)} ${totalExpenses.currency}';

  String get displayNetAmount {
    final symbol = netAmount.isPositive ? '+' : '';
    return '$symbol${netAmount.amount.toStringAsFixed(2)} ${netAmount.currency}';
  }

  List<TransactionWithBalance> getTransactionsInRange(DateRange dateRange) {
    return recentTransactions
        .where((tx) => dateRange.contains(tx.transaction.date))
        .toList();
  }

  List<TransactionWithBalance> getIncomeTransactions() {
    return recentTransactions.where((tx) => tx.isIncome).toList();
  }

  List<TransactionWithBalance> getExpenseTransactions() {
    return recentTransactions.where((tx) => tx.isExpense).toList();
  }

  double getBalanceChangePercentage() {
    if (account.initialBalance == 0) return 0.0;
    final change = currentBalance.amount - account.initialBalance;
    return (change / account.initialBalance) * 100;
  }

  bool get isBalancePositive => currentBalance.isPositive;
  bool get isBalanceNegative => currentBalance.isNegative;

  @override
  List<Object?> get props => [
    account,
    currentBalance,
    recentTransactions,
    totalTransactionsCount,
    totalIncome,
    totalExpenses,
    lastTransactionDate,
  ];

  @override
  bool get stringify => true;
}
