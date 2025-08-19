import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

abstract class TransactionRepository {
  /// Get all transactions
  Future<List<Transaction>> getAllTransactions();

  /// Get transactions by account ID
  Future<List<Transaction>> getTransactionsByAccountId(int accountId);

  /// Get transaction by ID
  Future<Transaction?> getTransactionById(int id);

  /// Create a new transaction
  Future<Transaction> createTransaction(Transaction transaction);

  /// Update an existing transaction
  Future<Transaction> updateTransaction(Transaction transaction);

  /// Delete a transaction
  Future<void> deleteTransaction(int id);

  /// Get transactions with balance for an account
  Future<List<TransactionWithBalance>> getTransactionsWithBalance(
    int accountId,
  );

  /// Get transactions with balance in date range
  Future<List<TransactionWithBalance>> getTransactionsWithBalanceInRange(
    int accountId,
    DateRange dateRange,
  );

  /// Get transactions around today for an account
  Future<List<TransactionWithBalance>> getTransactionsAroundToday(
    int accountId,
  );

  /// Search transactions by keyword
  Future<List<TransactionWithBalance>> searchTransactionsByKeyword(
    int accountId,
    String keyword,
  );

  /// Filter transactions by amount range
  Future<List<TransactionWithBalance>> filterTransactionsByAmount(
    int accountId,
    double? minAmount,
    double? maxAmount,
  );

  /// Get transactions by category
  Future<List<TransactionWithBalance>> getTransactionsByCategory(
    int accountId,
    int categoryId,
  );

  /// Get transactions by counterparty
  Future<List<TransactionWithBalance>> getTransactionsByCounterparty(
    int accountId,
    int counterpartyId,
  );

  /// Stream to watch transactions changes
  Stream<List<Transaction>> watchAllTransactions();

  /// Stream to watch transactions for specific account
  Stream<List<Transaction>> watchTransactionsByAccountId(int accountId);

  /// Stream to watch transactions with balance for specific account
  Stream<List<TransactionWithBalance>> watchTransactionsWithBalance(
    int accountId,
  );

  /// Get all followed transactions with details
  Future<List<TransactionWithBalance>> getFollowedTransactionsWithDetails();

  /// Get IDs of followed transactions
  Future<List<int>> getFollowedTransactionIds();

  /// Check if a transaction is followed
  Future<bool> isTransactionFollowed(int transactionId);

  /// Follow a transaction
  Future<void> followTransaction(int transactionId);

  /// Unfollow a transaction
  Future<void> unfollowTransaction(int transactionId);

  /// Toggle transaction status
  Future<void> toggleTransactionStatus(int transactionId);
}
