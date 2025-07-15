import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/data/models/models.dart';

abstract class AccountLocalDataSource {
  /// Get all accounts
  Future<List<AccountModel>> getAllAccounts();
  
  /// Get account by ID
  Future<AccountModel?> getAccountById(int id);
  
  /// Create a new account
  Future<AccountModel> createAccount(AccountModel account);
  
  /// Update an existing account
  Future<AccountModel> updateAccount(AccountModel account);
  
  /// Delete an account
  Future<void> deleteAccount(int id);
  
  /// Stream to watch accounts changes
  Stream<List<AccountModel>> watchAllAccounts();
  
  /// Stream to watch specific account changes
  Stream<AccountModel?> watchAccountById(int id);
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  final AppDatabase _database;
  
  AccountLocalDataSourceImpl(this._database);
  
  @override
  Future<List<AccountModel>> getAllAccounts() async {
    final accounts = await _database.select(_database.accounts).get();
    return accounts.map((account) => AccountModel.fromDrift(account)).toList();
  }
  
  @override
  Future<AccountModel?> getAccountById(int id) async {
    final account = await (_database.select(_database.accounts)
      ..where((tbl) => tbl.id.equals(id)))
      .getSingleOrNull();
    
    return account != null ? AccountModel.fromDrift(account) : null;
  }
  
  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    final companion = account.toCompanion();
    final id = await _database.into(_database.accounts).insert(companion);
    return account.copyWith(id: id);
  }
  
  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    final companion = account.toCompanion();
    await _database.update(_database.accounts).replace(companion);
    return account;
  }
  
  @override
  Future<void> deleteAccount(int id) async {
    await (_database.delete(_database.accounts)
      ..where((tbl) => tbl.id.equals(id)))
      .go();
  }
  
  @override
  Stream<List<AccountModel>> watchAllAccounts() {
    return _database.select(_database.accounts).watch().map(
      (accounts) => accounts.map((account) => AccountModel.fromDrift(account)).toList()
    );
  }
  
  @override
  Stream<AccountModel?> watchAccountById(int id) {
    return (_database.select(_database.accounts)
      ..where((tbl) => tbl.id.equals(id)))
      .watchSingleOrNull()
      .map((account) => account != null ? AccountModel.fromDrift(account) : null);
  }
}