import 'package:drift/drift.dart';
import 'tables/tables.dart';
import 'database_connection.dart';
import 'migrations/migration_strategy.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Constructeur avec connexion configurée
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => createMigrationStrategy();
}