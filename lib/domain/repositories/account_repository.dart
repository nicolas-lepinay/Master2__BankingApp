import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/domain/value_objects/value_objects.dart';

abstract class AccountRepository {
  /// Get all accounts
  Future<List<Account>> getAllAccounts();
  
  /// Get account by ID
  Future<Account?> getAccountById(int id);
  
  /// Create a new account
  Future<Account> createAccount(Account account);
  
  /// Update an existing account
  Future<Account> updateAccount(Account account);
  
  /// Delete an account
  Future<void> deleteAccount(int id);
  
  /// Get account summary with transactions and balance
  Future<AccountSummary> getAccountSummary(int accountId);
  
  /// Get account balance at specific date
  Future<AccountBalance> getAccountBalanceAtDate(int accountId, DateTime date);
  
  /// Get current account balance
  Future<AccountBalance> getCurrentAccountBalance(int accountId);
  
  /// Stream to watch accounts changes
  Stream<List<Account>> watchAllAccounts();
  
  /// Stream to watch specific account changes
  Stream<Account?> watchAccountById(int id);
  
  /// Stream to watch account summary changes
  Stream<AccountSummary> watchAccountSummary(int accountId);
}