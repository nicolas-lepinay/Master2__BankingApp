import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:drift/drift.dart';

class TransactionModel {
  final int id;
  final int accountId;
  final int? counterpartyId;
  final int? category1Id;
  final int? category2Id;
  final int? category3Id;
  final int? category4Id;
  final domain.TransactionType type;
  final String currency;
  final double amount;
  final double? amountConverted;
  final String? originalCurrency;
  final String? title;
  final String? comment;
  final DateTime date;
  final domain.TransactionStatus status;

  const TransactionModel({
    required this.id,
    required this.accountId,
    this.counterpartyId,
    this.category1Id,
    this.category2Id,
    this.category3Id,
    this.category4Id,
    required this.type,
    required this.currency,
    required this.amount,
    this.amountConverted,
    this.originalCurrency,
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
      category1Id: data.category1Id,
      category2Id: data.category2Id,
      category3Id: data.category3Id,
      category4Id: data.category4Id,
      type: _mapTransactionType(data.transactionType),
      currency: data.currency,
      amount: data.amount,
      amountConverted: data.amountConverted,
      originalCurrency: data.originalCurrency,
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
      category1Id: transaction.category1Id,
      category2Id: transaction.category2Id,
      category3Id: transaction.category3Id,
      category4Id: transaction.category4Id,
      type: transaction.type,
      currency: transaction.currency,
      amount: transaction.amount,
      amountConverted: transaction.amountConverted,
      originalCurrency: transaction.originalCurrency,
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
      category1Id: category1Id,
      category2Id: category2Id,
      category3Id: category3Id,
      category4Id: category4Id,
      type: type,
      currency: currency,
      amount: amount,
      amountConverted: amountConverted,
      originalCurrency: originalCurrency,
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
      category1Id: Value(category1Id),
      category2Id: Value(category2Id),
      category3Id: Value(category3Id),
      category4Id: Value(category4Id),
      transactionType: Value(_mapTransactionTypeToString(type)),
      currency: Value(currency),
      amount: Value(amount),
      amountConverted: Value(amountConverted),
      originalCurrency: Value(originalCurrency),
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
    int? category1Id,
    int? category2Id,
    int? category3Id,
    int? category4Id,
    domain.TransactionType? type,
    String? currency,
    double? amount,
    double? amountConverted,
    String? originalCurrency,
    String? title,
    String? comment,
    DateTime? date,
    domain.TransactionStatus? status,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      category1Id: category1Id ?? this.category1Id,
      category2Id: category2Id ?? this.category2Id,
      category3Id: category3Id ?? this.category3Id,
      category4Id: category4Id ?? this.category4Id,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      amountConverted: amountConverted ?? this.amountConverted,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
