import 'package:drift/drift.dart';

import '../app_database.dart';

/// Insère les données initiales dans la base de données
///
/// Cette fonction est appelée lors de la première création de la base de données
/// pour peupler les tables avec des données de test et de démonstration.
Future<void> insertInitialData(AppDatabase database) async {
  // Insert default user
  await database
      .into(database.users)
      .insert(
        UsersCompanion(
          name: const Value('Nicolas'),
          creationDate: Value(DateTime.now()),
        ),
      );

  // Insert test accounts
  await database
      .into(database.accounts)
      .insert(
        AccountsCompanion(
          name: const Value('CIC Compte courant'),
          currency: const Value('EUR'),
          initialBalance: const Value(500.0),
          creationDate: Value(
            DateTime.now().subtract(const Duration(days: 10)),
          ),
        ),
      );

  await database
      .into(database.accounts)
      .insert(
        AccountsCompanion(
          name: const Value('CIC Livret A'),
          currency: const Value('EUR'),
          initialBalance: const Value(25000.0),
          creationDate: Value(DateTime.now().subtract(const Duration(days: 9))),
        ),
      );

  await database
      .into(database.accounts)
      .insert(
        AccountsCompanion(
          name: const Value('Revolut'),
          currency: const Value('USD'),
          initialBalance: const Value(300.0),
          creationDate: Value(DateTime.now().subtract(const Duration(days: 8))),
        ),
      );

  await database
      .into(database.accounts)
      .insert(
        AccountsCompanion(
          name: const Value('Liquides'),
          currency: const Value('EUR'),
          initialBalance: const Value(120.0),
          creationDate: Value(DateTime.now().subtract(const Duration(days: 7))),
        ),
      );

  // Insert initial counterparties
  await database
      .into(database.counterparties)
      .insert(
        CounterpartiesCompanion(
          name: const Value('Netflix'),
          icon: const Value('tv'),
        ),
      );

  await database
      .into(database.counterparties)
      .insert(
        CounterpartiesCompanion(
          name: const Value('Apple'),
          icon: const Value('phone_iphone'),
        ),
      );

  await database
      .into(database.counterparties)
      .insert(
        CounterpartiesCompanion(
          name: const Value('Intermarché'),
          icon: const Value('shopping_cart'),
        ),
      );

  await database
      .into(database.counterparties)
      .insert(
        CounterpartiesCompanion(
          name: const Value('Total Énergies'),
          icon: const Value('local_gas_station'),
        ),
      );

  await database
      .into(database.counterparties)
      .insert(
        CounterpartiesCompanion(
          name: const Value('Spotify'),
          icon: const Value('music_note'),
        ),
      );

  // Insert test transactions
  // Transaction 1: Netflix (with counterparty)
  final netflixTransactionId = await database
      .into(database.transactions)
      .insert(
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
  final spotifyTransactionId = await database
      .into(database.transactions)
      .insert(
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
  final refundTransactionId = await database
      .into(database.transactions)
      .insert(
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
  await database
      .into(database.transactions)
      .insert(
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
  await database
      .into(database.transactions)
      .insert(
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

  // Transaction 6: Airbnb
  await database
      .into(database.transactions)
      .insert(
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
  await database
      .into(database.followedTransactions)
      .insert(
        FollowedTransactionsCompanion(
          transactionId: Value(netflixTransactionId),
          followedDate: Value(DateTime.now()),
        ),
      );

  await database
      .into(database.followedTransactions)
      .insert(
        FollowedTransactionsCompanion(
          transactionId: Value(spotifyTransactionId),
          followedDate: Value(DateTime.now().add(const Duration(days: 1))),
        ),
      );

  await database
      .into(database.followedTransactions)
      .insert(
        FollowedTransactionsCompanion(
          transactionId: Value(refundTransactionId),
          followedDate: Value(DateTime.now().add(const Duration(days: 3))),
        ),
      );
}
