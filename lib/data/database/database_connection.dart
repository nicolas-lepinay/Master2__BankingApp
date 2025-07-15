import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Configuration et ouverture de la connexion à la base de données
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bank_app_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// Factory pour créer une connexion à la base de données
LazyDatabase createDatabaseConnection() => _openConnection();