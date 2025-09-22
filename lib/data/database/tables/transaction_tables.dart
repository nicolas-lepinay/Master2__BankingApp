import 'package:drift/drift.dart';

import 'account_tables.dart';
import 'category_tables.dart';
import 'counterparty_tables.dart';

/// Table principale des transactions
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get counterpartyId =>
      integer().nullable().references(Counterparties, #id)();
  IntColumn get deepestCategoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get transactionType => text()(); // 'DEBIT' or 'CREDIT'
  RealColumn get amount => real()(); // Montant toujours dans la devise du compte
  TextColumn get currency => text()(); // Devise du compte (identique à account.currency)
  RealColumn get amountBeforeConversion => real().nullable()(); // Montant original avant conversion (optionnel)
  TextColumn get currencyBeforeConversion => text().nullable()(); // Devise originale avant conversion (optionnel)
  TextColumn get title => text().nullable()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get status => integer()(); // 0 = pending, 1 = confirmed
}

/// Table pour les transactions suivies
class FollowedTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  DateTimeColumn get followedDate => dateTime()();
}
