import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Tables
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  RealColumn get initialBalance => real()();
  DateTimeColumn get creationDate => dateTime()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get level => integer()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get icon => text().nullable()();
}

class Counterparties extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get counterpartyId =>
      integer().nullable().references(Counterparties, #id)();
  IntColumn get category1Id =>
      integer().nullable().references(Categories, #id)();
  IntColumn get category2Id =>
      integer().nullable().references(Categories, #id)();
  IntColumn get category3Id =>
      integer().nullable().references(Categories, #id)();
  IntColumn get category4Id =>
      integer().nullable().references(Categories, #id)();
  TextColumn get transactionType => text()(); // 'DEBIT' or 'CREDIT'
  TextColumn get currency => text()();
  RealColumn get amount => real()();
  RealColumn get amountConverted => real().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get status => integer()(); // 0 = pending, 1 = confirmed
}

@DriftDatabase(tables: [Accounts, Categories, Counterparties, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // Increment for migrations

  // Helper method to get account balance at a specific date
  Future<double> getAccountBalanceAtDate(int accountId, DateTime date) async {
    final account = await (select(
      accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final transactionsQuery = select(transactions)
      ..where(
        (t) =>
            t.accountId.equals(accountId) & t.date.isSmallerOrEqualValue(date),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    final transactionsList = await transactionsQuery.get();

    double balance = account.initialBalance;
    for (final transaction in transactionsList) {
      final amount = transaction.amountConverted ?? transaction.amount;
      if (transaction.transactionType == 'DEBIT') {
        balance -= amount;
      } else {
        balance += amount;
      }
    }

    return balance;
  }

  // Get transactions with running balance
  Future<List<TransactionWithBalance>> getTransactionsWithBalance(
    int accountId,
  ) async {
    final account = await (select(
      accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final transactionsQuery = select(transactions)
      ..where((t) => t.accountId.equals(accountId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);

    final transactionsList = await transactionsQuery.get();

    // Calculate running balance for each transaction
    final result = <TransactionWithBalance>[];

    for (int i = transactionsList.length - 1; i >= 0; i--) {
      final transaction = transactionsList[i];
      final balance = await getAccountBalanceAtDate(
        accountId,
        transaction.date,
      );

      result.insert(
        0,
        TransactionWithBalance(transaction: transaction, balanceAfter: balance),
      );
    }

    return result;
  }

  // Get total expenses and revenues for an account
  Future<AccountSummary> getAccountSummary(int accountId) async {
    final account = await (select(
      accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final expensesQuery = customSelect(
      'SELECT SUM(COALESCE(amount_converted, amount)) as total FROM transactions WHERE account_id = ? AND transaction_type = \'DEBIT\'',
      variables: [Variable.withInt(accountId)],
      readsFrom: {transactions},
    );

    final revenuesQuery = customSelect(
      'SELECT SUM(COALESCE(amount_converted, amount)) as total FROM transactions WHERE account_id = ? AND transaction_type = \'CREDIT\'',
      variables: [Variable.withInt(accountId)],
      readsFrom: {transactions},
    );

    final expensesResult = await expensesQuery.getSingle();
    final revenuesResult = await revenuesQuery.getSingle();

    final totalExpenses = expensesResult.data['total'] as double? ?? 0.0;
    final totalRevenues = revenuesResult.data['total'] as double? ?? 0.0;

    final currentBalance =
        account.initialBalance + totalRevenues - totalExpenses;

    return AccountSummary(
      account: account,
      currentBalance: currentBalance,
      totalExpenses: totalExpenses,
      totalRevenues: totalRevenues,
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertInitialData();
    },
  );

  Future<void> _insertInitialData() async {
    // Insert test accounts
    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('CIC Compte courant'),
        currency: const Value('EUR'),
        initialBalance: const Value(500.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 30))),
      ),
    );

    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('CIC Livret A'),
        currency: const Value('EUR'),
        initialBalance: const Value(25000.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 5))),
      ),
    );

    // Insert test transactions
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(20.0),
        title: const Value('Abonnement Netflix'),
        date: Value(DateTime.now().subtract(const Duration(days: 1))),
        status: const Value(1),
      ),
    );

    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(30.0),
        title: const Value('Abonnement Spotify'),
        date: Value(
          DateTime.now()
              .subtract(const Duration(days: 1))
              .subtract(const Duration(minutes: 1)),
        ),
        status: const Value(1),
      ),
    );

    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(10.0),
        title: const Value('Shopping au supermarché'),
        date: Value(DateTime.now().subtract(const Duration(days: 3))),
        status: const Value(1),
      ),
    );
  }
}

// Helper classes
class TransactionWithBalance {
  final Transaction transaction;
  final double balanceAfter;

  TransactionWithBalance({
    required this.transaction,
    required this.balanceAfter,
  });
}

class AccountSummary {
  final Account account;
  final double currentBalance;
  final double totalExpenses;
  final double totalRevenues;

  AccountSummary({
    required this.account,
    required this.currentBalance,
    required this.totalExpenses,
    required this.totalRevenues,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bankapp.db'));
    return NativeDatabase(file);
  });
}
