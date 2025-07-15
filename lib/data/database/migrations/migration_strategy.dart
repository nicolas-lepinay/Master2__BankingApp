import 'package:drift/drift.dart';
import '../app_database.dart';
import 'initial_data.dart';

/// Stratégie de migration pour la base de données
/// 
/// Gère les migrations et l'insertion des données initiales
MigrationStrategy createMigrationStrategy() {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      // Créer toutes les tables
      await m.createAll();
      
      // Insérer les données initiales
      await insertInitialData(m.database as AppDatabase);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // TODO: Implémenter les migrations futures si nécessaire
    },
  );
}