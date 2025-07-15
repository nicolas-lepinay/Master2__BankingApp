import 'package:drift/drift.dart';

/// Table des utilisateurs de l'application
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get creationDate => dateTime()();
}