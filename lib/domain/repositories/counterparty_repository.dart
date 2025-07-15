import 'package:bankapp/domain/entities/entities.dart';

abstract class CounterpartyRepository {
  /// Get all counterparties
  Future<List<Counterparty>> getAllCounterparties();
  
  /// Get counterparty by ID
  Future<Counterparty?> getCounterpartyById(int id);
  
  /// Search counterparties by name
  Future<List<Counterparty>> searchCounterpartiesByName(String name);
  
  /// Create a new counterparty
  Future<Counterparty> createCounterparty(Counterparty counterparty);
  
  /// Update an existing counterparty
  Future<Counterparty> updateCounterparty(Counterparty counterparty);
  
  /// Delete a counterparty
  Future<void> deleteCounterparty(int id);
  
  /// Check if counterparty is used in transactions
  Future<bool> isUsedInTransactions(int counterpartyId);
  
  /// Get counterparty usage statistics
  Future<Map<String, int>> getCounterpartyUsageStats(int counterpartyId);
  
  /// Stream to watch counterparties changes
  Stream<List<Counterparty>> watchAllCounterparties();
  
  /// Stream to watch specific counterparty changes
  Stream<Counterparty?> watchCounterpartyById(int id);
}