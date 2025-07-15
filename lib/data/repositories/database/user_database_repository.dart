import 'package:drift/drift.dart';
import '../../database/app_database.dart';

/// Repository pour les opérations sur les utilisateurs
/// 
/// Contient toutes les opérations CRUD et logiques métier
/// liées à la gestion des utilisateurs dans la base de données.
class UserDatabaseRepository {
  final AppDatabase _database;

  UserDatabaseRepository(this._database);

  /// Récupère l'utilisateur actuel ou en crée un par défaut
  /// 
  /// Cette méthode garantit qu'il y a toujours un utilisateur
  /// dans la base de données. Si aucun utilisateur n'existe,
  /// elle crée un utilisateur par défaut nommé 'Nicolas'.
  Future<User> getCurrentUser() async {
    final userList = await _database.select(_database.users).get();
    if (userList.isNotEmpty) {
      return userList.first;
    }

    // Créer un utilisateur par défaut si aucun n'existe
    final userId = await _database.into(_database.users).insert(
      UsersCompanion(
        name: const Value('Nicolas'),
        creationDate: Value(DateTime.now()),
      ),
    );

    return await (_database.select(_database.users)
          ..where((u) => u.id.equals(userId)))
        .getSingle();
  }

  /// Récupère un utilisateur par son ID
  Future<User?> getUserById(int id) async {
    return await (_database.select(_database.users)
          ..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  /// Met à jour le nom d'un utilisateur
  Future<bool> updateUserName(int id, String newName) async {
    final updatedRows = await (_database.update(_database.users)
          ..where((u) => u.id.equals(id)))
        .write(UsersCompanion(name: Value(newName)));
    
    return updatedRows > 0;
  }

  /// Récupère tous les utilisateurs
  Future<List<User>> getAllUsers() async {
    return await _database.select(_database.users).get();
  }

  /// Crée un nouveau utilisateur
  Future<int> createUser(String name) async {
    return await _database.into(_database.users).insert(
      UsersCompanion(
        name: Value(name),
        creationDate: Value(DateTime.now()),
      ),
    );
  }

  /// Supprime un utilisateur par son ID
  Future<bool> deleteUser(int id) async {
    final deletedRows = await (_database.delete(_database.users)
          ..where((u) => u.id.equals(id)))
        .go();
    
    return deletedRows > 0;
  }
}