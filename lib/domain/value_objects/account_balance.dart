import 'package:bankapp/domain/value_objects/money.dart';
import 'package:equatable/equatable.dart';

class AccountBalance extends Equatable {
  final Money balance;
  final DateTime calculatedAt;

  const AccountBalance({required this.balance, required this.calculatedAt});

  AccountBalance add(Money amount) {
    return AccountBalance(
      balance: balance.add(amount),
      calculatedAt: DateTime.now(),
    );
  }

  AccountBalance subtract(Money amount) {
    return AccountBalance(
      balance: balance.subtract(amount),
      calculatedAt: DateTime.now(),
    );
  }

  AccountBalance applyTransaction(Money transactionAmount) {
    return AccountBalance(
      balance: balance.add(transactionAmount),
      calculatedAt: DateTime.now(),
    );
  }

  bool get isPositive => balance.isPositive;
  bool get isNegative => balance.isNegative;
  bool get isZero => balance.isZero;

  double get amount => balance.amount;
  String get currency => balance.currency;

  @override
  List<Object?> get props => [balance, calculatedAt];

  @override
  bool get stringify => true;

  @override
  String toString() => 'Balance: $balance (calculated at $calculatedAt)';
}
