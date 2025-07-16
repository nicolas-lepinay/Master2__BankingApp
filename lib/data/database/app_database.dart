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
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Constructeur avec connexion configurée
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => createMigrationStrategy();

  // Méthodes de commodité pour compatibilité avec l'ancien code
  // TODO: Migrer vers les repositories spécialisés

  /// Trouve ou crée un tiers par nom
  Future<int> findOrCreateCounterparty(String name) async {
    // Chercher d'abord un tiers existant
    final existing = await (select(
      counterparties,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    // Créer un nouveau tiers
    final newCounterparty = CounterpartiesCompanion(
      name: Value(name),
      icon: const Value(null),
    );

    return await into(counterparties).insert(newCounterparty);
  }

  /// Supprime une transaction des suivies
  Future<void> removeFollowedTransaction(int transactionId) async {
    await (delete(
      followedTransactions,
    )..where((tbl) => tbl.transactionId.equals(transactionId))).go();
  }
}
