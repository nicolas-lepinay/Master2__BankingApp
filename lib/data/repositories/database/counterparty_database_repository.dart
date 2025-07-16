import 'package:drift/drift.dart';

import '../../database/app_database.dart';

/// Repository pour les opérations sur les contreparties/tiers
///
/// Contient toutes les opérations CRUD et logiques métier
/// liées à la gestion des contreparties dans la base de données.
class CounterpartyDatabaseRepository {
  final AppDatabase _database;

  CounterpartyDatabaseRepository(this._database);

  /// Trouve ou crée une contrepartie par nom
  ///
  /// Cette méthode cherche d'abord une contrepartie existante
  /// avec le nom fourni (insensible à la casse). Si aucune
  /// contrepartie n'est trouvée, elle en crée une nouvelle.
  Future<int> findOrCreateCounterparty(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Le nom du tiers ne peut pas être vide');
    }

    // Chercher un tiers existant (insensible à la casse)
    final existingCounterparty =
        await (_database.select(_database.counterparties)..where(
              (c) => c.name.lower().equals(normalizedName.toLowerCase()),
            ))
            .getSingleOrNull();

    if (existingCounterparty != null) {
      return existingCounterparty.id;
    }

    // Créer un nouveau tiers s'il n'existe pas
    final newCounterpartyId = await _database
        .into(_database.counterparties)
        .insert(
          CounterpartiesCompanion(
            name: Value(normalizedName),
            icon: const Value(
              null,
            ), // Pas d'icône par défaut pour les nouveaux tiers
          ),
        );

    return newCounterpartyId;
  }

  /// Récupère une contrepartie par son ID
  Future<Counterparty?> getCounterpartyById(int id) async {
    return await (_database.select(
      _database.counterparties,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Récupère toutes les contreparties
  Future<List<Counterparty>> getAllCounterparties() async {
    return await _database.select(_database.counterparties).get();
  }

  /// Récupère les contreparties par ordre alphabétique
  Future<List<Counterparty>> getCounterpartiesOrderedByName() async {
    return await (_database.select(
      _database.counterparties,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).get();
  }

  /// Crée une nouvelle contrepartie
  Future<int> createCounterparty(String name, {String? icon}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Le nom du tiers ne peut pas être vide');
    }

    return await _database
        .into(_database.counterparties)
        .insert(
          CounterpartiesCompanion(
            name: Value(normalizedName),
            icon: Value(icon),
          ),
        );
  }

  /// Met à jour une contrepartie
  Future<bool> updateCounterparty(int id, {String? name, String? icon}) async {
    final companion = CounterpartiesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      icon: icon != null ? Value(icon) : const Value.absent(),
    );

    final updatedRows = await (_database.update(
      _database.counterparties,
    )..where((c) => c.id.equals(id))).write(companion);

    return updatedRows > 0;
  }

  /// Supprime une contrepartie
  Future<bool> deleteCounterparty(int id) async {
    final deletedRows = await (_database.delete(
      _database.counterparties,
    )..where((c) => c.id.equals(id))).go();

    return deletedRows > 0;
  }

  /// Recherche des contreparties par nom (recherche partielle)
  Future<List<Counterparty>> searchCounterpartiesByName(
    String searchTerm,
  ) async {
    final normalizedSearchTerm = searchTerm.trim().toLowerCase();
    if (normalizedSearchTerm.isEmpty) {
      return await getAllCounterparties();
    }

    return await (_database.select(_database.counterparties)
          ..where((c) => c.name.lower().contains(normalizedSearchTerm))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Vérifie si une contrepartie avec ce nom existe déjà
  Future<bool> counterpartyNameExists(String name) async {
    final normalizedName = name.trim().toLowerCase();
    final existingCounterparty = await (_database.select(
      _database.counterparties,
    )..where((c) => c.name.lower().equals(normalizedName))).getSingleOrNull();

    return existingCounterparty != null;
  }

  /// Récupère le nombre total de contreparties
  Future<int> getCounterpartyCount() async {
    final result = await _database.select(_database.counterparties).get();
    return result.length;
  }
}
