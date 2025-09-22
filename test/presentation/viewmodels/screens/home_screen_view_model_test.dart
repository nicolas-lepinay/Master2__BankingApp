import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/core/events/transaction_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/value_objects/money.dart';
import 'package:bankapp/domain/value_objects/account_balance.dart';
import 'package:bankapp/domain/repositories/account_repository.dart';
import 'package:bankapp/presentation/viewmodels/screens/home_screen_view_model.dart';

import 'home_screen_view_model_test.mocks.dart';

@GenerateMocks([AccountRepository])
void main() {
  late MockAccountRepository mockAccountRepository;
  late HomeScreenViewModel viewModel;
  late AppEventBus eventBus;

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    eventBus = AppEventBus.instance;
    eventBus.reset();
    viewModel = HomeScreenViewModel(mockAccountRepository);
  });

  tearDown(() {
    viewModel.dispose();
    eventBus.reset();
  });

  group('HomeScreenViewModel - Initialization', () {
    test('should initialize with correct default state', () {
      expect(viewModel.state.accounts, isEmpty);
      expect(viewModel.state.selectedAccount, isNull);
      expect(viewModel.state.selectedAccountSummary, isNull);
      expect(viewModel.state.welcomeMessage, isEmpty);
      expect(viewModel.state.isCardsExpanded, false);
      expect(viewModel.state.selectedCardIndex, 0);
      expect(viewModel.state.shouldPlayCardAnimation, false);
      expect(viewModel.state.hasAccounts, false);
      expect(viewModel.state.hasSelectedAccount, false);
      expect(viewModel.state.hasSelectedAccountSummary, false);
      expect(viewModel.state.recentTransactions, isEmpty);
      expect(viewModel.state.currentBalance, 0.0);
      expect(viewModel.state.currentCurrency, 'EUR');
    });

    test('should not initialize twice if accounts already loaded', () async {
      // Arrange
      final accounts = [
        domain.Account(
          id: 1,
          name: 'Test Account',
          currency: 'EUR',
          initialBalance: 1000.0,
          creationDate: DateTime.now(),
        ),
      ];
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);
      
      // Act
      await viewModel.initialize();
      
      // Assert
      verifyNever(mockAccountRepository.getAllAccounts());
    });
  });

  group('HomeScreenViewModel - Data Loading', () {
    test('should load accounts and generate welcome message on initialize', () async {
      // Arrange
      final accounts = [
        domain.Account(
          id: 1,
          name: 'Main Account',
          currency: 'EUR',
          initialBalance: 1000.0,
          creationDate: DateTime.now(),
        ),
        domain.Account(
          id: 2,
          name: 'Savings',
          currency: 'USD',
          initialBalance: 500.0,
          creationDate: DateTime.now(),
        ),
      ];

      final accountSummary = domain.AccountSummary(
        account: accounts[0],
        currentBalance: AccountBalance(
          balance: Money(amount: 1200.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 1200.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 0.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => accounts);
      when(mockAccountRepository.getAccountSummary(1)).thenAnswer((_) async => accountSummary);

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.state.accounts, accounts);
      expect(viewModel.state.welcomeMessage, isNotEmpty);
      expect(viewModel.state.selectedAccount, accounts[0]);
      expect(viewModel.state.selectedAccountSummary, accountSummary);
      expect(viewModel.state.hasAccounts, true);
      expect(viewModel.isLoading, false);
      expect(viewModel.hasError, false);
    });

    test('should generate correct welcome message based on time', () async {
      // This test is time-dependent, so we'll test the logic indirectly
      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => []);

      await viewModel.initialize();

      final welcomeMessage = viewModel.state.welcomeMessage;
      expect(['Bonjour !', 'Bon après-midi !', 'Bonsoir !'].contains(welcomeMessage), true);
    });

    test('should handle errors during initialization gracefully', () async {
      // Arrange
      when(mockAccountRepository.getAllAccounts()).thenThrow(Exception('Database error'));

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains('Database error'));
    });

    test('should refresh data and update state', () async {
      // Arrange
      final initialAccounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      final updatedAccounts = [
        domain.Account(id: 1, name: 'Updated Account', currency: 'EUR', initialBalance: 1500.0, creationDate: DateTime.now()),
        domain.Account(id: 2, name: 'New Account', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
      ];

      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => updatedAccounts);

      viewModel.state = viewModel.state.copyWith(
        accounts: initialAccounts,
        selectedAccount: initialAccounts[0],
      );

      // Act
      await viewModel.refresh();

      // Assert
      expect(viewModel.state.accounts, updatedAccounts);
      expect(viewModel.state.welcomeMessage, isNotEmpty);
    });
  });

  group('HomeScreenViewModel - Account Selection', () {
    test('should select account by ID correctly', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
        domain.Account(id: 2, name: 'Account 2', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
      ];
      
      final accountSummary = domain.AccountSummary(
        account: accounts[1],
        currentBalance: AccountBalance(
          balance: Money(amount: 600.0, currency: 'USD'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 600.0, currency: 'USD'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'USD'),
        totalExpenses: Money(amount: 0.0, currency: 'USD'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAccountSummary(2)).thenAnswer((_) async => accountSummary);
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act
      await viewModel.selectAccount(2);

      // Assert
      expect(viewModel.state.selectedAccount, accounts[1]);
      expect(viewModel.state.selectedAccountSummary, accountSummary);
    });

    test('should select account by index correctly', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
        domain.Account(id: 2, name: 'Account 2', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
      ];
      
      final accountSummary = domain.AccountSummary(
        account: accounts[1],
        currentBalance: AccountBalance(
          balance: Money(amount: 600.0, currency: 'USD'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 600.0, currency: 'USD'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'USD'),
        totalExpenses: Money(amount: 0.0, currency: 'USD'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAccountSummary(2)).thenAnswer((_) async => accountSummary);
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act
      await viewModel.selectAccountByIndex(1);

      // Assert
      expect(viewModel.state.selectedAccount, accounts[1]);
      expect(viewModel.state.selectedAccountSummary, accountSummary);
      expect(viewModel.state.selectedCardIndex, 1);
    });

    test('should throw error when selecting non-existent account', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act & Assert
      expect(() => viewModel.selectAccount(999), throwsStateError);
    });

    test('should handle index out of bounds for selectAccountByIndex', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act
      await viewModel.selectAccountByIndex(5); // Out of bounds

      // Assert - Should not change state
      expect(viewModel.state.selectedCardIndex, 0); // Original value
    });

    test('should fire Event Bus when selecting account with notifyEventBus=true', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      
      final accountSummary = domain.AccountSummary(
        account: accounts[0],
        currentBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 0.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAccountSummary(1)).thenAnswer((_) async => accountSummary);
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      AccountSelectedEvent? firedEvent;
      eventBus.accountEvents.listen((event) {
        if (event is AccountSelectedEvent) {
          firedEvent = event;
        }
      });

      // Act
      await viewModel.selectAccount(1, notifyEventBus: true);

      // Assert
      await Future.delayed(const Duration(milliseconds: 10)); // Allow event to propagate
      expect(firedEvent, isNotNull);
      expect(firedEvent!.accountId, 1);
    });

    test('should not fire Event Bus when selecting account with notifyEventBus=false', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      
      final accountSummary = domain.AccountSummary(
        account: accounts[0],
        currentBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 0.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAccountSummary(1)).thenAnswer((_) async => accountSummary);
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      AccountSelectedEvent? firedEvent;
      eventBus.accountEvents.listen((event) {
        if (event is AccountSelectedEvent) {
          firedEvent = event;
        }
      });

      // Act
      await viewModel.selectAccount(1, notifyEventBus: false);

      // Assert
      await Future.delayed(const Duration(milliseconds: 10)); // Allow event to propagate
      expect(firedEvent, isNull);
    });
  });

  group('HomeScreenViewModel - Animation State', () {
    test('should update cards expanded state', () {
      // Act
      viewModel.setCardsExpanded(true);

      // Assert
      expect(viewModel.state.isCardsExpanded, true);

      // Act
      viewModel.setCardsExpanded(false);

      // Assert
      expect(viewModel.state.isCardsExpanded, false);
    });

    test('should update card animation state', () {
      // Act
      viewModel.setShouldPlayCardAnimation(true);

      // Assert
      expect(viewModel.state.shouldPlayCardAnimation, true);

      // Act
      viewModel.setShouldPlayCardAnimation(false);

      // Assert
      expect(viewModel.state.shouldPlayCardAnimation, false);
    });

    test('should update selected card index', () {
      // Act
      viewModel.setSelectedCardIndex(3);

      // Assert
      expect(viewModel.state.selectedCardIndex, 3);

      // Act
      viewModel.setSelectedCardIndex(0);

      // Assert
      expect(viewModel.state.selectedCardIndex, 0);
    });
  });

  group('HomeScreenViewModel - Event Bus Integration', () {
    test('should listen to account events and handle them correctly', () async {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ];
      
      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => accounts);
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act - Fire account created event
      eventBus.fire(AccountCreatedEvent(
        account: domain.Account(id: 2, name: 'New Account', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
        timestamp: DateTime.now(),
        eventId: 'test_event',
      ));

      // Allow event to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Should trigger refresh
      verify(mockAccountRepository.getAllAccounts()).called(greaterThan(0));
    });

    test('should handle transaction events for selected account', () async {
      // Arrange
      final account = domain.Account(
        id: 1,
        name: 'Test Account',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );
      
      final accountSummary = domain.AccountSummary(
        account: account,
        currentBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 0.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      when(mockAccountRepository.getAccountSummary(1)).thenAnswer((_) async => accountSummary);
      
      viewModel.state = viewModel.state.copyWith(
        accounts: [account],
        selectedAccount: account,
      );

      // Act - Fire transaction event for selected account
      eventBus.fire(TransactionCreatedEvent(
        transaction: domain.Transaction(
          id: 1,
          accountId: 1,
          amount: 100.0,
          currency: 'EUR',
          date: DateTime.now(),
          status: domain.TransactionStatus.completed,
          type: domain.TransactionType.expense,
          title: 'Test transaction',
          counterpartyId: null,
        ),
        timestamp: DateTime.now(),
        eventId: 'test_event',
        accountId: 1,
      ));

      // Allow event to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Should refresh selected account summary
      verify(mockAccountRepository.getAccountSummary(1)).called(greaterThan(0));
    });

    test('should clear selected account when account deleted', () async {
      // Arrange
      final account = domain.Account(
        id: 1,
        name: 'Test Account',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );
      
      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => []);
      
      viewModel.state = viewModel.state.copyWith(
        accounts: [account],
        selectedAccount: account,
      );

      // Act - Fire account deleted event
      eventBus.fire(AccountDeletedEvent(
        accountId: 1,
        deletedAccount: account,
        timestamp: DateTime.now(),
        eventId: 'test_event',
      ));

      // Allow event to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Should clear selected account
      expect(viewModel.state.selectedAccount, isNull);
      expect(viewModel.state.selectedAccountSummary, isNull);
    });
  });

  group('HomeScreenViewModel - Account CRUD Operations', () {
    test('should create account and fire event', () async {
      // Arrange
      final newAccount = domain.Account(
        id: 1,
        name: 'New Account',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );

      when(mockAccountRepository.createAccount(any)).thenAnswer((_) async => newAccount);
      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => [newAccount]);

      AccountCreatedEvent? firedEvent;
      eventBus.accountEvents.listen((event) {
        if (event is AccountCreatedEvent) {
          firedEvent = event;
        }
      });

      // Act
      await viewModel.createAccount('New Account', 'EUR', 1000.0);

      // Assert
      verify(mockAccountRepository.createAccount(any)).called(1);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(firedEvent, isNotNull);
      expect(firedEvent!.account.name, 'New Account');
    });

    test('should delete account and fire event', () async {
      // Arrange
      final accountToDelete = domain.Account(
        id: 1,
        name: 'Account to Delete',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );

      when(mockAccountRepository.deleteAccount(1)).thenAnswer((_) async {});
      when(mockAccountRepository.getAllAccounts()).thenAnswer((_) async => []);
      
      viewModel.state = viewModel.state.copyWith(accounts: [accountToDelete]);

      AccountDeletedEvent? firedEvent;
      eventBus.accountEvents.listen((event) {
        if (event is AccountDeletedEvent) {
          firedEvent = event;
        }
      });

      // Act
      await viewModel.deleteAccount(1);

      // Assert
      verify(mockAccountRepository.deleteAccount(1)).called(1);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(firedEvent, isNotNull);
      expect(firedEvent!.accountId, 1);
    });

    test('should handle error during account creation', () async {
      // Arrange
      when(mockAccountRepository.createAccount(any)).thenThrow(Exception('Creation failed'));

      // Act
      await viewModel.createAccount('Failed Account', 'EUR', 1000.0);

      // Assert
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains('Creation failed'));
    });
  });

  group('HomeScreenViewModel - Utility Methods', () {
    test('should get account by ID correctly', () {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
        domain.Account(id: 2, name: 'Account 2', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
      ];
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act & Assert
      expect(viewModel.getAccountById(1), accounts[0]);
      expect(viewModel.getAccountById(2), accounts[1]);
      expect(viewModel.getAccountById(999), isNull);
    });

    test('should get account index correctly', () {
      // Arrange
      final accounts = [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
        domain.Account(id: 2, name: 'Account 2', currency: 'USD', initialBalance: 500.0, creationDate: DateTime.now()),
      ];
      
      viewModel.state = viewModel.state.copyWith(accounts: accounts);

      // Act & Assert
      expect(viewModel.getAccountIndex(1), 0);
      expect(viewModel.getAccountIndex(2), 1);
      expect(viewModel.getAccountIndex(999), -1);
    });

    test('should determine app ready state correctly', () {
      // Act & Assert
      // No accounts and not loading/error = ready (empty state)
      expect(viewModel.isAppReady, true);

      // With accounts = ready
      viewModel.state = viewModel.state.copyWith(accounts: [
        domain.Account(id: 1, name: 'Account 1', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
      ]);
      expect(viewModel.isAppReady, true);
    });
  });

  group('HomeScreenViewModel - State Management', () {
    test('should reset to initial state correctly', () {
      // Arrange - Set some state
      viewModel.state = viewModel.state.copyWith(
        accounts: [
          domain.Account(id: 1, name: 'Test', currency: 'EUR', initialBalance: 1000.0, creationDate: DateTime.now()),
        ],
        welcomeMessage: 'Hello',
        isCardsExpanded: true,
        selectedCardIndex: 2,
      );

      // Act
      viewModel.resetToInitialState();

      // Assert
      expect(viewModel.state.accounts, isEmpty);
      expect(viewModel.state.welcomeMessage, isEmpty);
      expect(viewModel.state.isCardsExpanded, false);
      expect(viewModel.state.selectedCardIndex, 0);
    });

    test('should dispose properly and cancel subscriptions', () {
      // This test ensures dispose() doesn't throw
      // Act
      expect(() => viewModel.dispose(), returnsNormally);
    });
  });

  group('HomeScreenViewModel - State Properties', () {
    test('should calculate current balance from selected account summary', () {
      // Arrange
      final account = domain.Account(
        id: 1,
        name: 'Test Account',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );

      final accountSummary = domain.AccountSummary(
        account: account,
        currentBalance: AccountBalance(
          balance: Money(amount: 1234.56, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 1234.56, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: [],
        totalTransactionsCount: 0,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 0.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      viewModel.state = viewModel.state.copyWith(
        selectedAccount: account,
        selectedAccountSummary: accountSummary,
      );

      // Act & Assert
      expect(viewModel.state.currentBalance, 1234.56);
    });

    test('should get current currency from selected account', () {
      // Arrange
      final account = domain.Account(
        id: 1,
        name: 'Test Account',
        currency: 'USD',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );

      viewModel.state = viewModel.state.copyWith(selectedAccount: account);

      // Act & Assert
      expect(viewModel.state.currentCurrency, 'USD');
    });

    test('should get recent transactions from selected account summary', () {
      // Arrange
      final account = domain.Account(
        id: 1,
        name: 'Test Account',
        currency: 'EUR',
        initialBalance: 1000.0,
        creationDate: DateTime.now(),
      );

      final transactions = [
        domain.TransactionWithBalance(
          transaction: domain.Transaction(
            id: 1,
            accountId: 1,
            amount: 100.0,
            currency: 'EUR',
            date: DateTime.now(),
            status: domain.TransactionStatus.completed,
            type: domain.TransactionType.expense,
            title: 'Test',
            counterpartyId: null,
          ),
          account: account,
          balanceAfter: AccountBalance(
            balance: Money(amount: 900.0, currency: 'EUR'),
            calculatedAt: DateTime.now(),
          ),
          counterparty: null,
          categories: [],
        ),
      ];

      final accountSummary = domain.AccountSummary(
        account: account,
        currentBalance: AccountBalance(
          balance: Money(amount: 900.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        confirmedBalance: AccountBalance(
          balance: Money(amount: 900.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        recentTransactions: transactions,
        totalTransactionsCount: 1,
        totalIncome: Money(amount: 0.0, currency: 'EUR'),
        totalExpenses: Money(amount: 100.0, currency: 'EUR'),
        lastTransactionDate: DateTime.now(),
      );

      viewModel.state = viewModel.state.copyWith(
        selectedAccount: account,
        selectedAccountSummary: accountSummary,
      );

      // Act & Assert
      expect(viewModel.state.recentTransactions, transactions);
      expect(viewModel.state.recentTransactions.length, 1);
    });
  });
}