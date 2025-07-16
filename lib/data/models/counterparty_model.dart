import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:drift/drift.dart';

class CounterpartyModel {
  final int id;
  final String name;
  final String? icon;

  const CounterpartyModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CounterpartyModel.fromDrift(Counterparty data) {
    return CounterpartyModel(
      id: data.id,
      name: data.name,
      icon: data.icon,
    );
  }

  factory CounterpartyModel.fromEntity(domain.Counterparty counterparty) {
    return CounterpartyModel(
      id: counterparty.id,
      name: counterparty.name,
      icon: counterparty.icon,
    );
  }

  domain.Counterparty toEntity() {
    return domain.Counterparty(
      id: id,
      name: name,
      icon: icon,
    );
  }

  CounterpartiesCompanion toCompanion() {
    return CounterpartiesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      name: Value(name),
      icon: Value(icon),
    );
  }

  CounterpartyModel copyWith({
    int? id,
    String? name,
    String? icon,
  }) {
    return CounterpartyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}