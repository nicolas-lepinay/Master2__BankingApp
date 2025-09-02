import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

enum TransactionStatus { pending, completed }

class Transaction extends Equatable {
  final int id;
  final int accountId;
  final int? counterpartyId;
  final int? category1Id;
  final int? category2Id;
  final int? category3Id;
  final int? category4Id;
  final TransactionType type;
  final double amount; // Montant toujours dans la devise du compte
  final String currency; // Devise du compte (identique à account.currency)
  final double? amountBeforeConversion; // Montant original avant conversion (optionnel)
  final String? currencyBeforeConversion; // Devise originale avant conversion (optionnel)
  final String? title;
  final String? comment;
  final DateTime date;
  final TransactionStatus status;

  const Transaction({
    required this.id,
    required this.accountId,
    this.counterpartyId,
    this.category1Id,
    this.category2Id,
    this.category3Id,
    this.category4Id,
    required this.type,
    required this.amount,
    required this.currency,
    this.amountBeforeConversion,
    this.currencyBeforeConversion,
    this.title,
    this.comment,
    required this.date,
    required this.status,
  });

  Transaction copyWith({
    int? id,
    int? accountId,
    int? counterpartyId,
    int? category1Id,
    int? category2Id,
    int? category3Id,
    int? category4Id,
    TransactionType? type,
    double? amount,
    String? currency,
    double? amountBeforeConversion,
    String? currencyBeforeConversion,
    String? title,
    String? comment,
    DateTime? date,
    TransactionStatus? status,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      category1Id: category1Id ?? this.category1Id,
      category2Id: category2Id ?? this.category2Id,
      category3Id: category3Id ?? this.category3Id,
      category4Id: category4Id ?? this.category4Id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      amountBeforeConversion: amountBeforeConversion ?? this.amountBeforeConversion,
      currencyBeforeConversion: currencyBeforeConversion ?? this.currencyBeforeConversion,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  double get signedAmount => type == TransactionType.income ? amount : -amount;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isPending => status == TransactionStatus.pending;

  bool get hasCounterparty => counterpartyId != null;
  bool get hasCategories =>
      category1Id != null ||
      category2Id != null ||
      category3Id != null ||
      category4Id != null;

  // Nouveaux getters pour la conversion
  bool get hasConversion => currencyBeforeConversion != null && amountBeforeConversion != null;
  bool get isConverted => hasConversion;

  List<int> get categoryIds => [
    if (category1Id != null) category1Id!,
    if (category2Id != null) category2Id!,
    if (category3Id != null) category3Id!,
    if (category4Id != null) category4Id!,
  ];

  @override
  List<Object?> get props => [
    id,
    accountId,
    counterpartyId,
    category1Id,
    category2Id,
    category3Id,
    category4Id,
    type,
    amount,
    currency,
    amountBeforeConversion,
    currencyBeforeConversion,
    title,
    comment,
    date,
    status,
  ];

  @override
  bool get stringify => true;
}
