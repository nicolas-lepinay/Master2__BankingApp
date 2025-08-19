import 'package:equatable/equatable.dart';

class Money extends Equatable {
  final double amount;
  final String currency;

  const Money({
    required this.amount,
    required this.currency,
  });

  Money add(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies: $currency and ${other.currency}');
    }
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money subtract(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot subtract different currencies: $currency and ${other.currency}');
    }
    return Money(amount: amount - other.amount, currency: currency);
  }

  Money multiply(double factor) {
    return Money(amount: amount * factor, currency: currency);
  }

  Money divide(double divisor) {
    if (divisor == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Money(amount: amount / divisor, currency: currency);
  }

  Money negate() {
    return Money(amount: -amount, currency: currency);
  }

  bool get isPositive => amount > 0;
  bool get isNegative => amount < 0;
  bool get isZero => amount == 0;

  bool isGreaterThan(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare different currencies: $currency and ${other.currency}');
    }
    return amount > other.amount;
  }

  bool isLessThan(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare different currencies: $currency and ${other.currency}');
    }
    return amount < other.amount;
  }

  bool isEqualTo(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare different currencies: $currency and ${other.currency}');
    }
    return amount == other.amount;
  }

  @override
  List<Object?> get props => [amount, currency];

  @override
  bool get stringify => true;

  @override
  String toString() => '$amount $currency';
}