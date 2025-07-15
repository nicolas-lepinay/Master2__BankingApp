import 'package:bankapp/data/database/database.dart';

abstract class LocalDataSource {
  /// Initialize the datasource
  Future<void> initialize();
  
  /// Close the datasource
  Future<void> close();
  
  /// Clear all data
  Future<void> clearAll();
  
  /// Get database instance
  AppDatabase get database;
}