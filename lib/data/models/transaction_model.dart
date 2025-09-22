import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:drift/drift.dart';

class TransactionModel {
  final int id;
  final int accountId;
  final int? counterpartyId;
  final int? deepestCategoryId;
  final domain.TransactionType type;
  final double amount; // Montant toujours dans la devise du compte
  final String currency; // Devise du compte (identique à account.currency)
  final double? amountBeforeConversion; // Montant original avant conversion (optionnel)
  final String? currencyBeforeConversion; // Devise originale avant conversion (optionnel)
  final String? title;
  final String? comment;
  final DateTime date;
  final domain.TransactionStatus status;

  const TransactionModel({
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

  factory TransactionModel.fromDrift(Transaction data) {
    return TransactionModel(
      id: data.id,
      accountId: data.accountId,
      counterpartyId: data.counterpartyId,
      deepestCategoryId: data.deepestCategoryId,
      type: _mapTransactionType(data.transactionType),
      amount: data.amount,
      currency: data.currency,
      amountBeforeConversion: data.amountBeforeConversion,
      currencyBeforeConversion: data.currencyBeforeConversion,
      title: data.title,
      comment: data.comment,
      date: data.date,
      status: _mapTransactionStatus(data.status),
    );
  }

  factory TransactionModel.fromEntity(domain.Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      accountId: transaction.accountId,
      counterpartyId: transaction.counterpartyId,
      deepestCategoryId: transaction.deepestCategoryId,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      amountBeforeConversion: transaction.amountBeforeConversion,
      currencyBeforeConversion: transaction.currencyBeforeConversion,
      title: transaction.title,
      comment: transaction.comment,
      date: transaction.date,
      status: transaction.status,
    );
  }

  domain.Transaction toEntity() {
    return domain.Transaction(
      id: id,
      accountId: accountId,
      counterpartyId: counterpartyId,
      deepestCategoryId: deepestCategoryId,
      type: type,
      amount: amount,
      currency: currency,
      amountBeforeConversion: amountBeforeConversion,
      currencyBeforeConversion: currencyBeforeConversion,
      title: title,
      comment: comment,
      date: date,
      status: status,
    );
  }

  TransactionsCompanion toCompanion() {
    return TransactionsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      accountId: Value(accountId),
      counterpartyId: Value(counterpartyId),
      deepestCategoryId: Value(deepestCategoryId),
      transactionType: Value(_mapTransactionTypeToString(type)),
      amount: Value(amount),
      currency: Value(currency),
      amountBeforeConversion: Value(amountBeforeConversion),
      currencyBeforeConversion: Value(currencyBeforeConversion),
      title: Value(title),
      comment: Value(comment),
      date: Value(date),
      status: Value(_mapTransactionStatusToInt(status)),
    );
  }

  static domain.TransactionType _mapTransactionType(String type) {
    switch (type) {
      case 'income':
        return domain.TransactionType.income;
      case 'expense':
        return domain.TransactionType.expense;
      default:
        return domain.TransactionType.expense;
    }
  }

  static String _mapTransactionTypeToString(domain.TransactionType type) {
    switch (type) {
      case domain.TransactionType.income:
        return 'income';
      case domain.TransactionType.expense:
        return 'expense';
    }
  }

  static domain.TransactionStatus _mapTransactionStatus(int status) {
    switch (status) {
      case 0:
        return domain.TransactionStatus.pending;
      case 1:
        return domain.TransactionStatus.completed;
      default:
        return domain.TransactionStatus.pending;
    }
  }

  static int _mapTransactionStatusToInt(domain.TransactionStatus status) {
    switch (status) {
      case domain.TransactionStatus.pending:
        return 0;
      case domain.TransactionStatus.completed:
        return 1;
    }
  }

  TransactionModel copyWith({
    int? id,
    int? accountId,
    int? counterpartyId,
    int? deepestCategoryId,
    domain.TransactionType? type,
    double? amount,
    String? currency,
    double? amountBeforeConversion,
    String? currencyBeforeConversion,
    String? title,
    String? comment,
    DateTime? date,
    domain.TransactionStatus? status,
  }) {
    return TransactionModel(
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
}
