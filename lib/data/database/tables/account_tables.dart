import 'package:drift/drift.dart';

/// Table des comptes bancaires
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  RealColumn get initialBalance => real()();
  DateTimeColumn get creationDate => dateTime()();
  TextColumn get icon => text().nullable()();
}