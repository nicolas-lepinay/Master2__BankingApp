import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Tables
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get creationDate => dateTime()();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get currency => text()();
  RealColumn get initialBalance => real()();
  DateTimeColumn get creationDate => dateTime()();
  TextColumn get icon => text().nullable()();
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
  TextColumn get icon => text().nullable()();
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

// Table pour les transactions suivies
class FollowedTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  DateTimeColumn get followedDate => dateTime()();
}

@DriftDatabase(
  tables: [
    Users,
    Accounts,
    Categories,
    Counterparties,
    Transactions,
    FollowedTransactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Helper method to get the current user
  Future<User> getCurrentUser() async {
    final userList = await select(users).get();
    if (userList.isNotEmpty) {
      return userList.first;
    }

    // Create default user if none exists
    final userId = await into(users).insert(
      UsersCompanion(
        name: const Value('Nicolas'),
        creationDate: Value(DateTime.now()),
      ),
    );

    return await (select(users)..where((u) => u.id.equals(userId))).getSingle();
  }

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

  // Get confirmed balance (status = 1 only)
  Future<double> getAccountConfirmedBalance(int accountId) async {
    final account = await (select(
      accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();

    final transactionsQuery = select(transactions)
      ..where((t) => t.accountId.equals(accountId) & t.status.equals(1))
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

    // Get confirmed balance
    final confirmedBalance = await getAccountConfirmedBalance(accountId);

    return AccountSummary(
      account: account,
      currentBalance: currentBalance,
      confirmedBalance: confirmedBalance,
      totalExpenses: totalExpenses,
      totalRevenues: totalRevenues,
    );
  }

  // =====================================================
  // MÉTHODES POUR LES TRANSACTIONS SUIVIES
  // =====================================================

  /// Ajouter une transaction aux transactions suivies
  Future<void> addFollowedTransaction(int transactionId) async {
    // Vérifier que la transaction existe
    final transaction = await (select(
      transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();

    if (transaction == null) {
      throw ArgumentError('Transaction avec ID $transactionId non trouvée');
    }

    // Vérifier si elle n'est pas déjà suivie
    final existingFollow = await (select(
      followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).getSingleOrNull();

    if (existingFollow != null) {
      throw StateError('Transaction déjà suivie');
    }

    // Ajouter aux transactions suivies
    await into(followedTransactions).insert(
      FollowedTransactionsCompanion(
        transactionId: Value(transactionId),
        followedDate: Value(DateTime.now()),
      ),
    );
  }

  /// Retirer une transaction des transactions suivies
  Future<void> removeFollowedTransaction(int transactionId) async {
    final deletedCount = await (delete(
      followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).go();

    if (deletedCount == 0) {
      throw StateError('Transaction non trouvée dans les suivies');
    }
  }

  /// Basculer le statut de suivi d'une transaction
  Future<bool> toggleFollowedTransaction(int transactionId) async {
    final existingFollow = await (select(
      followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).getSingleOrNull();

    if (existingFollow != null) {
      // Retirer du suivi
      await removeFollowedTransaction(transactionId);
      return false; // Plus suivie
    } else {
      // Ajouter au suivi
      await addFollowedTransaction(transactionId);
      return true; // Maintenant suivie
    }
  }

  /// Vérifier si une transaction est suivie
  Future<bool> isTransactionFollowed(int transactionId) async {
    final existingFollow = await (select(
      followedTransactions,
    )..where((ft) => ft.transactionId.equals(transactionId))).getSingleOrNull();

    return existingFollow != null;
  }

  /// Récupérer les transactions suivies avec leurs détails
  Future<List<TransactionWithCounterparty>>
  getFollowedTransactionsWithDetails() async {
    final query = select(transactions).join([
      innerJoin(
        followedTransactions,
        followedTransactions.transactionId.equalsExp(transactions.id),
      ),
      leftOuterJoin(
        counterparties,
        counterparties.id.equalsExp(transactions.counterpartyId),
      ),
    ])..orderBy([OrderingTerm.desc(followedTransactions.followedDate)]);

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

  /// Récupérer seulement les IDs des transactions suivies
  Future<List<int>> getFollowedTransactionIds() async {
    final query = select(followedTransactions)
      ..orderBy([(ft) => OrderingTerm.desc(ft.followedDate)]);

    final result = await query.get();
    return result.map((ft) => ft.transactionId).toList();
  }

  /// Récupérer les transactions suivies (entités Transaction simples)
  Future<List<Transaction>> getFollowedTransactions() async {
    final query = select(transactions).join([
      innerJoin(
        followedTransactions,
        followedTransactions.transactionId.equalsExp(transactions.id),
      ),
    ])..orderBy([OrderingTerm.desc(followedTransactions.followedDate)]);

    final result = await query.get();
    return result.map((row) => row.readTable(transactions)).toList();
  }

  // =====================================================
  // MÉTHODES EXISTANTES MAINTENUES
  // =====================================================

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _insertInitialData();
    },
    onUpgrade: (Migrator m, int from, int to) async {},
  );

  Future<void> _insertInitialData() async {
    // Insert default user
    await into(users).insert(
      UsersCompanion(
        name: const Value('Nicolas'),
        creationDate: Value(DateTime.now()),
      ),
    );

    // Insert test accounts
    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('CIC Compte courant'),
        currency: const Value('EUR'),
        initialBalance: const Value(500.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 10))),
      ),
    );

    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('CIC Livret A'),
        currency: const Value('EUR'),
        initialBalance: const Value(25000.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 9))),
      ),
    );

    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('Revolut'),
        currency: const Value('USD'),
        initialBalance: const Value(300.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 8))),
      ),
    );

    await into(accounts).insert(
      AccountsCompanion(
        name: const Value('Liquides'),
        currency: const Value('EUR'),
        initialBalance: const Value(120.0),
        creationDate: Value(DateTime.now().subtract(const Duration(days: 7))),
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
    final netflixTransactionId = await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(1), // Netflix
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(20.0),
        title: const Value('Abonnement Netflix'),
        date: Value(DateTime.now().subtract(const Duration(days: 2))),
        status: const Value(1),
      ),
    );

    // Transaction 2: Spotify (with counterparty)
    final spotifyTransactionId = await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(5), // Spotify
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(30.0),
        title: const Value('Abonnement Spotify'),
        date: Value(
          DateTime.now()
              .subtract(const Duration(days: 1))
              .subtract(const Duration(seconds: 10)),
        ),
        status: const Value(1),
      ),
    );

    // Transaction 3: Remboursement (no counterparty)
    final refundTransactionId = await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('CREDIT'),
        currency: const Value('EUR'),
        amount: const Value(10.0),
        title: const Value('Remboursement'),
        date: Value(
          DateTime.now()
              .subtract(const Duration(days: 1))
              .subtract(const Duration(seconds: 20)),
        ),
        status: const Value(1),
      ),
    );

    // Transaction 4: Future electricity bill
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        counterpartyId: const Value(4),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(50.0),
        title: const Value('Facture électricité (programmée)'),
        date: Value(DateTime.now().add(const Duration(days: 3))),
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
        title: const Value('Salaire programmé'),
        date: Value(
          DateTime.now()
              .add(const Duration(days: 3))
              .add(const Duration(seconds: 10)),
        ),
        status: const Value(0),
      ),
    );

    // Transaction 6:
    await into(transactions).insert(
      TransactionsCompanion(
        accountId: const Value(1),
        transactionType: const Value('DEBIT'),
        currency: const Value('EUR'),
        amount: const Value(800.55),
        title: const Value('Airbnb'),
        date: Value(DateTime.now()),
        status: const Value(0),
      ),
    );

    // Add transactions to followed transactions
    await into(followedTransactions).insert(
      FollowedTransactionsCompanion(
        transactionId: Value(netflixTransactionId),
        followedDate: Value(DateTime.now()),
      ),
    );

    await into(followedTransactions).insert(
      FollowedTransactionsCompanion(
        transactionId: Value(spotifyTransactionId),
        followedDate: Value(DateTime.now().add(const Duration(days: 1))),
      ),
    );

    await into(followedTransactions).insert(
      FollowedTransactionsCompanion(
        transactionId: Value(refundTransactionId),
        followedDate: Value(DateTime.now().add(const Duration(days: 3))),
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

  /// Récupérer les transactions centrées autour d'aujourd'hui pour la liste perspective
  /// Récupère jusqu'à 25 transactions passées et 25 transactions futures/présentes
  Future<List<TransactionWithCounterparty>> getTransactionsAroundToday(
    int accountId, {
    int pastLimit = 25,
    int futureLimit = 25,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Requête pour les transactions passées (date < aujourd'hui)
    final pastTransactionsQuery =
        select(transactions).join([
            leftOuterJoin(
              counterparties,
              counterparties.id.equalsExp(transactions.counterpartyId),
            ),
          ])
          ..where(
            transactions.accountId.equals(accountId) &
                transactions.date.isSmallerThanValue(today),
          )
          ..orderBy([
            OrderingTerm.desc(transactions.date),
            OrderingTerm.desc(transactions.id),
          ])
          ..limit(pastLimit);

    // Requête pour les transactions présentes/futures (date >= aujourd'hui)
    final futurePresentTransactionsQuery =
        select(transactions).join([
            leftOuterJoin(
              counterparties,
              counterparties.id.equalsExp(transactions.counterpartyId),
            ),
          ])
          ..where(
            transactions.accountId.equals(accountId) &
                transactions.date.isBiggerOrEqualValue(today),
          )
          ..orderBy([
            OrderingTerm.asc(transactions.date),
            OrderingTerm.asc(transactions.id),
          ])
          ..limit(futureLimit);

    // Exécuter les deux requêtes
    final pastResults = await pastTransactionsQuery.get();
    final futurePresentResults = await futurePresentTransactionsQuery.get();

    // Convertir en TransactionWithCounterparty
    final pastTransactions = pastResults.map((row) {
      final transaction = row.readTable(transactions);
      final counterparty = row.readTableOrNull(counterparties);
      return TransactionWithCounterparty(
        transaction: transaction,
        counterparty: counterparty,
      );
    }).toList();

    final futurePresentTransactions = futurePresentResults.map((row) {
      final transaction = row.readTable(transactions);
      final counterparty = row.readTableOrNull(counterparties);
      return TransactionWithCounterparty(
        transaction: transaction,
        counterparty: counterparty,
      );
    }).toList();

    // Combiner et trier par date (plus récent en premier)
    final allTransactions = [...pastTransactions, ...futurePresentTransactions];

    // Trier par date décroissante
    allTransactions.sort(
      (a, b) => b.transaction.date.compareTo(a.transaction.date),
    );

    return allTransactions;
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
  final double
  confirmedBalance; // Nouveau: solde des transactions confirmées uniquement
  final double totalExpenses;
  final double totalRevenues;

  AccountSummary({
    required this.account,
    required this.currentBalance,
    required this.confirmedBalance,
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
