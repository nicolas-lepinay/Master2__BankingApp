import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'migrations/migration_strategy.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// Base de données principale de l'application
///
/// Cette classe configure la base de données Drift avec toutes les tables
/// et délègue les opérations spécialisées aux repositories correspondants.
@DriftDatabase(
  tables: [
    Users,
    Accounts,
    Categories,
    Counterparties,
    Transactions,
    FollowedTransactions,
    ExchangeRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Constructeur avec connexion configurée
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => createMigrationStrategy();

  // Base de données configurée avec les repositories spécialisés
  // Toutes les opérations CRUD utilisent maintenant l'architecture MVVM
}
