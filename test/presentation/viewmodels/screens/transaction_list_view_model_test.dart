import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:bankapp/core/events/app_event_bus.dart';
import 'package:bankapp/core/events/account_events.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/domain/value_objects/date_range.dart';
import 'package:bankapp/domain/value_objects/money.dart';
import 'package:bankapp/domain/value_objects/account_balance.dart';
import 'package:bankapp/presentation/viewmodels/screens/transaction_list_view_model.dart';

import 'transaction_list_view_model_test.mocks.dart';

@GenerateMocks([TransactionRepository])
void main() {
  late TransactionListViewModel viewModel;
  late MockTransactionRepository mockRepository;
  late AppEventBus eventBus;

  // Test data
  final testAccount1 = domain.Account(
    id: 1,
    name: 'Test Account 1',
    currency: 'EUR',
    initialBalance: 1000.0,
    creationDate: DateTime(2023, 1, 1),
  );

  final testCounterparty = domain.Counterparty(
    id: 1,
    name: 'Test Merchant',
    icon: null,
  );

  final testCategory = domain.Category(
    id: 1,
    label: 'Groceries',
    level: 1,
  );

  final testTransactionWithBalance1 = domain.TransactionWithBalance(
    transaction: domain.Transaction(
      id: 1,
      accountId: 1,
      counterpartyId: 1,
      amount: -50.0,
      currency: 'EUR',
      date: DateTime(2023, 8, 15),
      title: 'Grocery Shopping',
      comment: 'Weekly shopping',
      type: domain.TransactionType.expense,
      status: domain.TransactionStatus.completed,
      category1Id: 1,
      category2Id: null,
      category3Id: null,
      category4Id: null,
    ),
    account: testAccount1,
    counterparty: testCounterparty,
    categories: [testCategory],
    balanceAfter: AccountBalance(
      balance: Money(amount: 950.0, currency: 'EUR'),
      calculatedAt: DateTime(2023, 8, 15),
    ),
  );

  final testTransactionWithBalance2 = domain.TransactionWithBalance(
    transaction: domain.Transaction(
      id: 2,
      accountId: 1,
      counterpartyId: 1,
      amount: 200.0,
      currency: 'EUR',
      date: DateTime(2023, 8, 10),
      title: 'Salary',
      comment: 'Monthly salary',
      type: domain.TransactionType.income,
      status: domain.TransactionStatus.completed,
      category1Id: null,
      category2Id: null,
      category3Id: null,
      category4Id: null,
    ),
    account: testAccount1,
    counterparty: testCounterparty,
    categories: [],
    balanceAfter: AccountBalance(
      balance: Money(amount: 1200.0, currency: 'EUR'),
      calculatedAt: DateTime(2023, 8, 10),
    ),
  );

  final testTransactions = [testTransactionWithBalance1, testTransactionWithBalance2];

  setUp(() async {
    // Reset Event Bus for each test
    await AppEventBus.instance.reset();
    eventBus = AppEventBus.instance;
    
    mockRepository = MockTransactionRepository();
    viewModel = TransactionListViewModel(mockRepository);

    // Setup default mock responses
    when(mockRepository.getTransactionsWithBalance(any))
        .thenAnswer((_) async => testTransactions);
  });

  tearDown(() async {
    viewModel.dispose();
    await AppEventBus.instance.reset();
  });

  group('TransactionListViewModel - Initialization', () {
    test('should initialize with default state', () {
      expect(viewModel.state.items, isEmpty);
      expect(viewModel.state.filteredItems, isEmpty);
      expect(viewModel.state.searchQuery, isEmpty);
      expect(viewModel.state.currentPage, 0);
      expect(viewModel.state.itemsPerPage, 20);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.selectedAccountId, isNull);
      expect(viewModel.state.minAmount, isNull);
      expect(viewModel.state.maxAmount, isNull);
      expect(viewModel.state.selectedCategoryId, isNull);
      expect(viewModel.state.selectedCounterpartyId, isNull);
    });

    test('should return empty list when no account selected', () async {
      final items = await viewModel.loadAllItems();
      expect(items, isEmpty);
      verifyNever(mockRepository.getTransactionsWithBalance(any));
    });
  });

  group('TransactionListViewModel - Data Loading', () {
    test('should load transactions for specific account', () async {
      await viewModel.loadTransactionsForAccount(1);

      expect(viewModel.state.selectedAccountId, 1);
      expect(viewModel.state.items, testTransactions);
      expect(viewModel.state.filteredItems, testTransactions);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);

      verify(mockRepository.getTransactionsWithBalance(1)).called(1);
    });

    test('should handle loading errors gracefully', () async {
      when(mockRepository.getTransactionsWithBalance(1))
          .thenThrow(Exception('Database error'));

      await viewModel.loadTransactionsForAccount(1);

      expect(viewModel.state.selectedAccountId, 1);
      expect(viewModel.state.items, isEmpty);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, 'Exception: Database error');
    });

    test('should sort transactions by date descending', () async {
      await viewModel.loadTransactionsForAccount(1);

      final sortedItems = viewModel.state.filteredItems;
      expect(sortedItems.length, 2);
      // testTransactionWithBalance1 (Aug 15) should come before testTransactionWithBalance2 (Aug 10)
      expect(sortedItems[0].transaction.date, DateTime(2023, 8, 15));
      expect(sortedItems[1].transaction.date, DateTime(2023, 8, 10));
    });
  });

  group('TransactionListViewModel - Search and Filtering', () {
    setUp(() async {
      await viewModel.loadTransactionsForAccount(1);
    });

    test('should filter transactions by search query in title', () async {
      await viewModel.updateSearchQuery('Grocery');

      expect(viewModel.state.searchQuery, 'Grocery');
      expect(viewModel.state.filteredItems.length, 1);
      expect(viewModel.state.filteredItems[0].transaction.title, 'Grocery Shopping');
    });

    test('should filter transactions by search query in comment', () async {
      await viewModel.updateSearchQuery('Weekly');

      expect(viewModel.state.searchQuery, 'Weekly');
      expect(viewModel.state.filteredItems.length, 1);
      expect(viewModel.state.filteredItems[0].transaction.comment, 'Weekly shopping');
    });

    test('should filter transactions by search query in counterparty name', () async {
      await viewModel.updateSearchQuery('Test Merchant');

      expect(viewModel.state.searchQuery, 'Test Merchant');
      expect(viewModel.state.filteredItems.length, 2); // Both transactions have same counterparty
    });

    test('should filter transactions by amount range', () async {
      await viewModel.filterByAmount(100.0, 300.0);

      expect(viewModel.state.minAmount, 100.0);
      expect(viewModel.state.maxAmount, 300.0);
      expect(viewModel.state.filteredItems.length, 1); // Only salary (200.0) is in range
      expect(viewModel.state.filteredItems[0].transaction.title, 'Salary');
    });

    test('should filter transactions by minimum amount only', () async {
      await viewModel.filterByAmount(100.0, null);

      expect(viewModel.state.minAmount, 100.0);
      expect(viewModel.state.maxAmount, isNull);
      expect(viewModel.state.filteredItems.length, 1); // Only salary (200.0) >= 100
      expect(viewModel.state.filteredItems[0].transaction.title, 'Salary');
    });

    test('should filter transactions by maximum amount only', () async {
      await viewModel.filterByAmount(null, 100.0);

      expect(viewModel.state.minAmount, isNull);
      expect(viewModel.state.maxAmount, 100.0);
      expect(viewModel.state.filteredItems.length, 1); // Only grocery (50.0) <= 100
      expect(viewModel.state.filteredItems[0].transaction.title, 'Grocery Shopping');
    });

    test('should filter transactions by category', () async {
      await viewModel.filterByCategory(1);

      expect(viewModel.state.selectedCategoryId, 1);
      expect(viewModel.state.filteredItems.length, 1); // Only grocery has category 1
      expect(viewModel.state.filteredItems[0].transaction.title, 'Grocery Shopping');
    });

    test('should filter transactions by counterparty', () async {
      await viewModel.filterByCounterparty(1);

      expect(viewModel.state.selectedCounterpartyId, 1);
      expect(viewModel.state.filteredItems.length, 2); // Both have counterparty 1
    });

    test('should combine multiple filters', () async {
      await viewModel.updateSearchQuery('Grocery');
      await viewModel.filterByAmount(40.0, 60.0);
      await viewModel.filterByCategory(1);

      expect(viewModel.state.filteredItems.length, 1);
      expect(viewModel.state.filteredItems[0].transaction.title, 'Grocery Shopping');
    });

    test('should clear search query', () async {
      await viewModel.updateSearchQuery('test');
      expect(viewModel.state.searchQuery, 'test');

      await viewModel.clearSearch();
      expect(viewModel.state.searchQuery, isEmpty);
      expect(viewModel.state.filteredItems.length, 2); // Back to all transactions
    });
  });

  group('TransactionListViewModel - Date Filtering', () {
    setUp(() async {
      await viewModel.loadTransactionsForAccount(1);
    });

    test('should filter transactions by date range', () async {
      final dateRange = DateRange(
        start: DateTime(2023, 8, 12),
        end: DateTime(2023, 8, 16),
      );

      await viewModel.updateDateFilter(dateRange);

      expect(viewModel.state.dateFilter, dateRange);
      expect(viewModel.state.filteredItems.length, 1); // Only Aug 15 transaction
      expect(viewModel.state.filteredItems[0].transaction.title, 'Grocery Shopping');
    });

    test('should clear date filter', () async {
      final dateRange = DateRange(
        start: DateTime(2023, 8, 12),
        end: DateTime(2023, 8, 16),
      );

      await viewModel.updateDateFilter(dateRange);
      expect(viewModel.state.filteredItems.length, 1);

      await viewModel.updateDateFilter(null);
      expect(viewModel.state.dateFilter, isNull);
      expect(viewModel.state.filteredItems.length, 2); // Back to all transactions
    });
  });

  group('TransactionListViewModel - Pagination', () {
    setUp(() async {
      await viewModel.loadTransactionsForAccount(1);
    });

    test('should paginate items correctly', () {
      viewModel.updateItemsPerPage(1); // Show 1 item per page
      
      expect(viewModel.state.paginatedItems.length, 1);
      expect(viewModel.state.totalPages, 2);
      expect(viewModel.state.hasNextPage, true);
      expect(viewModel.state.hasPreviousPage, false);
    });

    test('should navigate to next page', () {
      viewModel.updateItemsPerPage(1);
      viewModel.nextPage();

      expect(viewModel.state.currentPage, 1);
      expect(viewModel.state.hasNextPage, false);
      expect(viewModel.state.hasPreviousPage, true);
    });

    test('should navigate to specific page', () {
      viewModel.updateItemsPerPage(1);
      viewModel.goToPage(1);

      expect(viewModel.state.currentPage, 1);
    });
  });

  group('TransactionListViewModel - State Properties', () {
    test('should calculate active filters count correctly', () {
      expect(viewModel.state.activeFiltersCount, 0);

      viewModel.state = viewModel.state.copyWith(searchQuery: 'test');
      expect(viewModel.state.activeFiltersCount, 1);

      viewModel.state = viewModel.state.copyWith(
        minAmount: 10.0,
        selectedCategoryId: 1,
      );
      expect(viewModel.state.activeFiltersCount, 3); // search + amount + category
    });

    test('should identify filtered state correctly', () {
      expect(viewModel.state.isFiltered, false);

      viewModel.state = viewModel.state.copyWith(searchQuery: 'test');
      expect(viewModel.state.isFiltered, true);

      viewModel.state = viewModel.state.copyWith(
        searchQuery: '',
        minAmount: 10.0,
      );
      expect(viewModel.state.isFiltered, true);
    });

    test('should identify amount filter correctly', () {
      expect(viewModel.state.hasAmountFilter, false);

      viewModel.state = viewModel.state.copyWith(minAmount: 10.0);
      expect(viewModel.state.hasAmountFilter, true);

      viewModel.state = viewModel.state.copyWith(
        clearMinAmount: true,
        maxAmount: 100.0,
      );
      expect(viewModel.state.hasAmountFilter, true);
    });
  });

  group('TransactionListViewModel - Event Bus Integration', () {
    test('should have event subscriptions active', () async {
      // Simply test that the ViewModel subscribed to events
      expect(eventBus.isActive, isTrue);
      
      // Load transactions to set up the state
      await viewModel.loadTransactionsForAccount(1);
      expect(viewModel.state.selectedAccountId, 1);
      
      // For now, just verify the basic functionality works
      // Event testing will be added in a future iteration
    });

    test('should refresh transactions when CounterpartyLogoDownloadedEvent is fired for current account', () async {
      // Set up: Load transactions for account 1
      await viewModel.loadTransactionsForAccount(1);
      expect(viewModel.state.selectedAccountId, 1);
      expect(viewModel.state.items.length, 2);
      
      // Verify initial repository call
      verify(mockRepository.getTransactionsWithBalance(1)).called(1);
      
      // Reset mock to track new calls
      clearInteractions(mockRepository);
      when(mockRepository.getTransactionsWithBalance(1))
          .thenAnswer((_) async => testTransactions);
      
      // Create and fire CounterpartyLogoDownloadedEvent for the current account
      final logoDownloadedEvent = CounterpartyLogoDownloadedEvent(
        counterpartyId: 1,
        counterpartyName: 'Test Merchant',
        logoPath: '/path/to/logo.png',
        accountId: 1, // Same as current account
        timestamp: DateTime.now(),
        eventId: 'test_logo_downloaded_event',
      );
      
      // Fire the event through the Event Bus
      eventBus.fire(logoDownloadedEvent);
      
      // Wait a short time for the event to be processed
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Verify that the repository was called again to refresh transactions
      verify(mockRepository.getTransactionsWithBalance(1)).called(1);
      
      // Verify state is still correct
      expect(viewModel.state.selectedAccountId, 1);
      expect(viewModel.state.items.length, 2);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);
    });

    test('should NOT refresh when CounterpartyLogoDownloadedEvent is fired for different account', () async {
      // Set up: Load transactions for account 1
      await viewModel.loadTransactionsForAccount(1);
      expect(viewModel.state.selectedAccountId, 1);
      
      // Verify initial repository call
      verify(mockRepository.getTransactionsWithBalance(1)).called(1);
      
      // Reset mock to track new calls
      clearInteractions(mockRepository);
      
      // Create and fire CounterpartyLogoDownloadedEvent for a DIFFERENT account
      final logoDownloadedEvent = CounterpartyLogoDownloadedEvent(
        counterpartyId: 1,
        counterpartyName: 'Test Merchant',
        logoPath: '/path/to/logo.png',
        accountId: 2, // Different account
        timestamp: DateTime.now(),
        eventId: 'test_logo_downloaded_event_diff_account',
      );
      
      // Fire the event through the Event Bus
      eventBus.fire(logoDownloadedEvent);
      
      // Wait a short time for the event to be processed
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Verify that the repository was NOT called again (no refresh)
      verifyNever(mockRepository.getTransactionsWithBalance(any));
    });
  });

  group('TransactionListViewModel - Clear Filters', () {
    test('should clear all filters', () async {
      await viewModel.loadTransactionsForAccount(1);
      
      // Apply various filters
      await viewModel.updateSearchQuery('test');
      await viewModel.filterByAmount(10.0, 100.0);
      await viewModel.filterByCategory(1);
      await viewModel.filterByCounterparty(1);

      // Verify filters are applied
      expect(viewModel.state.searchQuery, 'test');
      expect(viewModel.state.minAmount, 10.0);
      expect(viewModel.state.maxAmount, 100.0);
      expect(viewModel.state.selectedCategoryId, 1);
      expect(viewModel.state.selectedCounterpartyId, 1);

      // Clear all filters
      await viewModel.clearFilters();

      // Verify all filters are cleared
      expect(viewModel.state.searchQuery, isEmpty);
      expect(viewModel.state.minAmount, isNull);
      expect(viewModel.state.maxAmount, isNull);
      expect(viewModel.state.selectedCategoryId, isNull);
      expect(viewModel.state.selectedCounterpartyId, isNull);
      expect(viewModel.state.filteredItems.length, 2); // Back to all items
    });
  });

  group('TransactionListViewModel - Load Around Today', () {
    test('should load transactions and attempt to scroll to today', () async {
      // Create transaction for today
      final todayTransaction = domain.TransactionWithBalance(
        transaction: domain.Transaction(
          id: 3,
          accountId: 1,
          counterpartyId: 1,
          amount: -30.0,
          currency: 'EUR',
          date: DateTime.now(),
          title: 'Today Transaction',
          comment: 'Today comment',
          type: domain.TransactionType.expense,
          status: domain.TransactionStatus.completed,
          category1Id: null,
          category2Id: null,
          category3Id: null,
          category4Id: null,
        ),
        account: testAccount1,
        counterparty: testCounterparty,
        categories: [],
        balanceAfter: AccountBalance(
          balance: Money(amount: 970.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
      );

      final transactionsWithToday = [
        todayTransaction,
        ...testTransactions,
      ];

      when(mockRepository.getTransactionsWithBalance(1))
          .thenAnswer((_) async => transactionsWithToday);

      await viewModel.loadTransactionsAroundToday(1);

      expect(viewModel.state.selectedAccountId, 1);
      expect(viewModel.state.items.length, 3);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);

      // Since today's transaction will be sorted first (newest), current page should stay at 0
      expect(viewModel.state.currentPage, 0);
    });
  });
}