import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final int id;
  final String name;
  final String currency;
  final double initialBalance;
  final DateTime creationDate;
  final String? icon;

  const Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.initialBalance,
    required this.creationDate,
    this.icon,
  });

  Account copyWith({
    int? id,
    String? name,
    String? currency,
    double? initialBalance,
    DateTime? creationDate,
    String? icon,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      creationDate: creationDate ?? this.creationDate,
      icon: icon ?? this.icon,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        currency,
        initialBalance,
        creationDate,
        icon,
      ];

  @override
  bool get stringify => true;
}