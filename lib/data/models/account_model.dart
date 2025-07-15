import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:drift/drift.dart';

class AccountModel {
  final int id;
  final String name;
  final String currency;
  final double initialBalance;
  final DateTime creationDate;
  final String? icon;

  const AccountModel({
    required this.id,
    required this.name,
    required this.currency,
    required this.initialBalance,
    required this.creationDate,
    this.icon,
  });

  factory AccountModel.fromDrift(Account data) {
    return AccountModel(
      id: data.id,
      name: data.name,
      currency: data.currency,
      initialBalance: data.initialBalance,
      creationDate: data.creationDate,
      icon: data.icon,
    );
  }

  factory AccountModel.fromEntity(domain.Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      currency: account.currency,
      initialBalance: account.initialBalance,
      creationDate: account.creationDate,
      icon: account.icon,
    );
  }

  domain.Account toEntity() {
    return domain.Account(
      id: id,
      name: name,
      currency: currency,
      initialBalance: initialBalance,
      creationDate: creationDate,
      icon: icon,
    );
  }

  AccountsCompanion toCompanion() {
    return AccountsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      name: Value(name),
      currency: Value(currency),
      initialBalance: Value(initialBalance),
      creationDate: Value(creationDate),
      icon: Value(icon),
    );
  }

  AccountModel copyWith({
    int? id,
    String? name,
    String? currency,
    double? initialBalance,
    DateTime? creationDate,
    String? icon,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      creationDate: creationDate ?? this.creationDate,
      icon: icon ?? this.icon,
    );
  }
}