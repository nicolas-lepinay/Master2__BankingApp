import 'package:drift/drift.dart';

/// Table des tiers/contreparties
class Counterparties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get icon => text().nullable()();
}