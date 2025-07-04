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
  TextColumn get icon => text().nullable()(); // Nouvelle colonne icon
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
  TextColumn get icon => text().nullable()(); // Nouvelle colonne icon
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
  int get schemaVersion => 1; // Incrémenter pour forcer une migration

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
      print('🔧 Creating database from scratch');
      await m.createAll();
      await _insertInitialData(); // Maintenant ça inclut TOUT
    },
    onUpgrade: (Migrator m, int from, int to) async {
      print('🔧 Migrating database from version $from to $to');
      // Si on passe de la version 1 à 2, on ajoute les nouvelles transactions
      if (from == 1 && to == 2) {
        await _addNewTestTransactions();
      }
      // Si on passe de la version 2 à 3, on ajoute les transactions futures
      if (from == 2 && to == 3) {
        await _addFutureTestTransactions();
      }
      // Si on passe de la version 3 à 4, on ajoute les colonnes icon et les tiers
      if (from <= 3 && to >= 4) {
        await m.addColumn(accounts, accounts.icon);
        await m.addColumn(counterparties, counterparties.icon);
        await _addInitialCounterparties();
      }
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

    // Insert initial counterparties first
    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Netflix'),
        icon: const Value('tv'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Apple'),
        icon: const Value('phone_iphone'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Intermarché'),
        icon: const Value('shopping_cart'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Total Énergies'),
        icon: const Value('local_gas_station'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Spotify'),
        icon: const Value('music_note'),
      ),
    );

    // Insert all test transactions
    // Transaction 1: Netflix (with counterparty)
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(1), // Netflix
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(20.0),
        title: const Value('Abonnement Netflix'),
        date: Value(DateTime.now().subtract(const Duration(days: 1))),
        status: const Value(1),
      ),
    );

    // Transaction 2: Spotify (with counterparty)
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(5), // Spotify
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(30.0),
        title: const Value('Abonnement Spotify'),
        date: Value(DateTime.now().subtract(const Duration(days: 1))),
        status: const Value(1),
      ),
    );

    // Transaction 3: Remboursement (no counterparty)
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(10.0),
        title: const Value('Remboursement'),
        date: Value(DateTime.now().subtract(const Duration(days: 3))),
        status: const Value(1),
      ),
    );

    // Transaction 4: Future electricity bill
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(4), // Total Énergies
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(50.0),
        title: const Value('Facture électricité (programmée)'),
        date: Value(DateTime.now().add(const Duration(days: 5))),
        status: const Value(0), // En attente
      ),
    );

    // Transaction 5: Future salary
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(2500.0),
        title: const Value('Salaire (programmé)'),
        date: Value(DateTime.now().add(const Duration(days: 10))),
        status: const Value(0), // En attente
      ),
    );
  }

  Future<void> _addNewTestTransactions() async {
    // Ajouter les nouvelles transactions de test
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(30.0),
        title: const Value('Abonnement Spotify'),
        date: Value(DateTime.now().subtract(const Duration(days: 1))),
        status: const Value(1),
      ),
    );

    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(10.0),
        title: const Value('Remboursement'),
        date: Value(DateTime.now().subtract(const Duration(days: 3))),
        status: const Value(1),
      ),
    );
  }

  Future<void> _addFutureTestTransactions() async {
    // Ajouter quelques transactions futures pour tester le scroll
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(50.0),
        title: const Value('Facture électricité (programmée)'),
        date: Value(DateTime.now().add(const Duration(days: 5))),
        status: const Value(0), // En attente
      ),
    );

    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(2500.0),
        title: const Value('Salaire (programmé)'),
        date: Value(DateTime.now().add(const Duration(days: 10))),
        status: const Value(0), // En attente
      ),
    );
  }

  Future<void> _addInitialCounterparties() async {
    // Ajouter quelques tiers initiaux
    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Netflix'),
        icon: const Value(
          'tv',
        ), // Nom d'icône (à adapter selon le système d'icônes choisi)
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Apple'),
        icon: const Value('phone_iphone'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Intermarché'),
        icon: const Value('shopping_cart'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Total Énergies'),
        icon: const Value('local_gas_station'),
      ),
    );

    await into(counterparties).insert(
      CounterpartiesCompanion(
        name: const Value('Spotify'),
        icon: const Value('music_note'),
      ),
    );
  }

  // Méthode pour trouver ou créer un tiers
  Future<int> findOrCreateCounterparty(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Le nom du tiers ne peut pas être vide');
    }

    // Chercher un tiers existant (insensible à la casse)
    final existingCounterparty =
        await (select(counterparties)..where(
              (c) => c.name.lower().equals(normalizedName.toLowerCase()),
            ))
            .getSingleOrNull();

    if (existingCounterparty != null) {
      return existingCounterparty.id;
    }

    // Créer un nouveau tiers s'il n'existe pas
    final newCounterpartyId = await into(counterparties).insert(
      CounterpartiesCompanion(
        name: Value(normalizedName),
        icon: const Value(
          null,
        ), // Pas d'icône par défaut pour les nouveaux tiers
      ),
    );

    return newCounterpartyId;
  }

  // Méthode pour récupérer un tiers par ID
  Future<Counterparty?> getCounterpartyById(int id) async {
    return await (select(
      counterparties,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  // Méthode pour récupérer toutes les transactions avec leurs tiers
  Future<List<TransactionWithCounterparty>> getTransactionsWithCounterparty(
    int accountId,
  ) async {
    final query =
        select(transactions).join([
            leftOuterJoin(
              counterparties,
              counterparties.id.equalsExp(transactions.counterpartyId),
            ),
          ])
          ..where(transactions.accountId.equals(accountId))
          ..orderBy([
            OrderingTerm.desc(transactions.date),
            OrderingTerm.desc(transactions.id),
          ]);

    final result = await query.get();

    return result.map((row) {
      final transaction = row.readTable(transactions);
      final counterparty = row.readTableOrNull(counterparties);
      return TransactionWithCounterparty(
        transaction: transaction,
        counterparty: counterparty,
      );
    }).toList();
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

class TransactionWithCounterparty {
  final Transaction transaction;
  final Counterparty? counterparty;

  TransactionWithCounterparty({required this.transaction, this.counterparty});
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
