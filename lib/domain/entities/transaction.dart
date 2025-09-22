import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

enum TransactionStatus { pending, completed }

class Transaction extends Equatable {
  final int id;
  final int accountId;
  final int? counterpartyId;
  final int? deepestCategoryId;
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
    this.deepestCategoryId,
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
    int? deepestCategoryId,
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
      deepestCategoryId: deepestCategoryId ?? this.deepestCategoryId,
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
  bool get hasCategories => deepestCategoryId != null;

  // Nouveaux getters pour la conversion
  bool get hasConversion => currencyBeforeConversion != null && amountBeforeConversion != null;
  bool get isConverted => hasConversion;

  /// Getter de compatibilité - retourne une liste avec le deepestCategoryId
  /// Note: La hiérarchie complète sera récupérée via le CacheManager
  List<int> get categoryIds {
    return deepestCategoryId != null ? [deepestCategoryId!] : [];
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    counterpartyId,
    deepestCategoryId,
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
