import 'package:bankapp/data/database/database.dart';
import 'package:bankapp/data/models/models.dart';
import 'package:drift/drift.dart';

abstract class CounterpartyLocalDataSource {
  /// Get all counterparties
  Future<List<CounterpartyModel>> getAllCounterparties();
  
  /// Get counterparty by ID
  Future<CounterpartyModel?> getCounterpartyById(int id);
  
  /// Search counterparties by name
  Future<List<CounterpartyModel>> searchCounterpartiesByName(String name);
  
  /// Create a new counterparty
  Future<CounterpartyModel> createCounterparty(CounterpartyModel counterparty);
  
  /// Update an existing counterparty
  Future<CounterpartyModel> updateCounterparty(CounterpartyModel counterparty);
  
  /// Delete a counterparty
  Future<void> deleteCounterparty(int id);
  
  /// Stream to watch counterparties changes
  Stream<List<CounterpartyModel>> watchAllCounterparties();
  
  /// Stream to watch specific counterparty changes
  Stream<CounterpartyModel?> watchCounterpartyById(int id);
}

class CounterpartyLocalDataSourceImpl implements CounterpartyLocalDataSource {
  final AppDatabase _database;
  
  CounterpartyLocalDataSourceImpl(this._database);
  
  @override
  Future<List<CounterpartyModel>> getAllCounterparties() async {
    final counterparties = await (_database.select(_database.counterparties)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
      .get();
    
    return counterparties.map((counterparty) => CounterpartyModel.fromDrift(counterparty)).toList();
  }
  
  @override
  Future<CounterpartyModel?> getCounterpartyById(int id) async {
    final counterparty = await (_database.select(_database.counterparties)
      ..where((tbl) => tbl.id.equals(id)))
      .getSingleOrNull();
    
    return counterparty != null ? CounterpartyModel.fromDrift(counterparty) : null;
  }
  
  @override
  Future<List<CounterpartyModel>> searchCounterpartiesByName(String name) async {
    final counterparties = await (_database.select(_database.counterparties)
      ..where((tbl) => tbl.name.like('%$name%'))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
      .get();
    
    return counterparties.map((counterparty) => CounterpartyModel.fromDrift(counterparty)).toList();
  }
  
  @override
  Future<CounterpartyModel> createCounterparty(CounterpartyModel counterparty) async {
    final companion = counterparty.toCompanion();
    final id = await _database.into(_database.counterparties).insert(companion);
    return counterparty.copyWith(id: id);
  }
  
  @override
  Future<CounterpartyModel> updateCounterparty(CounterpartyModel counterparty) async {
    final companion = counterparty.toCompanion();
    await _database.update(_database.counterparties).replace(companion);
    return counterparty;
  }
  
  @override
  Future<void> deleteCounterparty(int id) async {
    await (_database.delete(_database.counterparties)
      ..where((tbl) => tbl.id.equals(id)))
      .go();
  }
  
  @override
  Stream<List<CounterpartyModel>> watchAllCounterparties() {
    return (_database.select(_database.counterparties)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc)]))
      .watch()
      .map((counterparties) => counterparties.map((counterparty) => CounterpartyModel.fromDrift(counterparty)).toList());
  }
  
  @override
  Stream<CounterpartyModel?> watchCounterpartyById(int id) {
    return (_database.select(_database.counterparties)
      ..where((tbl) => tbl.id.equals(id)))
      .watchSingleOrNull()
      .map((counterparty) => counterparty != null ? CounterpartyModel.fromDrift(counterparty) : null);
  }
}