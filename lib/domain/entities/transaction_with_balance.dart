import 'package:bankapp/domain/entities/account.dart';
import 'package:bankapp/domain/entities/category.dart';
import 'package:bankapp/domain/entities/counterparty.dart';
import 'package:bankapp/domain/entities/transaction.dart';
import 'package:bankapp/domain/value_objects/account_balance.dart';
import 'package:bankapp/domain/value_objects/money.dart';
import 'package:equatable/equatable.dart';

class TransactionWithBalance extends Equatable {
  final Transaction transaction;
  final Account account;
  final AccountBalance balanceAfter;
  final Counterparty? counterparty;
  final List<Category> categories;

  const TransactionWithBalance({
    required this.transaction,
    required this.account,
    required this.balanceAfter,
    this.counterparty,
    this.categories = const [],
  });

  TransactionWithBalance copyWith({
    Transaction? transaction,
    Account? account,
    AccountBalance? balanceAfter,
    Counterparty? counterparty,
    List<Category>? categories,
  }) {
    return TransactionWithBalance(
      transaction: transaction ?? this.transaction,
      account: account ?? this.account,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      counterparty: counterparty ?? this.counterparty,
      categories: categories ?? this.categories,
    );
  }

  Money get transactionAmount =>
      Money(amount: transaction.amount, currency: transaction.currency);

  Money get signedAmount =>
      Money(amount: transaction.signedAmount, currency: transaction.currency);

  bool get isIncome => transaction.isIncome;
  bool get isExpense => transaction.isExpense;
  bool get isCompleted => transaction.isCompleted;
  bool get isPending => transaction.isPending;

  bool get hasCounterparty => counterparty != null;
  bool get hasCategories => categories.isNotEmpty;

  String get displayTitle =>
      transaction.title ?? counterparty?.name ?? 'Transaction';

  String get displayAmount {
    final symbol = isIncome ? '+' : '-';
    return '$symbol${transactionAmount.amount.toStringAsFixed(2)} ${transactionAmount.currency}';
  }

  String get displayBalance =>
      '${balanceAfter.amount.toStringAsFixed(2)} ${balanceAfter.currency}';

  bool matchesKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return displayTitle.toLowerCase().contains(lowerKeyword) ||
        (transaction.comment?.toLowerCase().contains(lowerKeyword) ?? false) ||
        (counterparty?.name.toLowerCase().contains(lowerKeyword) ?? false) ||
        categories.any((cat) => cat.label.toLowerCase().contains(lowerKeyword));
  }

  bool isInAmountRange(double? minAmount, double? maxAmount) {
    final amount = transaction.amount;
    if (minAmount != null && amount < minAmount) return false;
    if (maxAmount != null && amount > maxAmount) return false;
    return true;
  }

  @override
  List<Object?> get props => [
    transaction,
    account,
    balanceAfter,
    counterparty,
    categories,
  ];

  @override
  bool get stringify => true;
}
