import 'package:equatable/equatable.dart';

class Counterparty extends Equatable {
  final int id;
  final String name;
  final String? icon;

  const Counterparty({
    required this.id,
    required this.name,
    this.icon,
  });

  Counterparty copyWith({
    int? id,
    String? name,
    String? icon,
  }) {
    return Counterparty(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }

  @override
  List<Object?> get props => [id, name, icon];

  @override
  bool get stringify => true;
}