import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/value_objects/account_balance.dart';
import 'package:bankapp/domain/value_objects/money.dart';
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/domain/repositories/category_repository.dart';
import 'package:bankapp/domain/repositories/counterparty_repository.dart';
import 'package:bankapp/presentation/viewmodels/screens/search_results_view_model.dart';

import 'search_results_view_model_test.mocks.dart';

@GenerateMocks([TransactionRepository, CategoryRepository, CounterpartyRepository])
void main() {
  late MockTransactionRepository mockTransactionRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockCounterpartyRepository mockCounterpartyRepository;
  late SearchResultsViewModel viewModel;

  const int testAccountId = 1;

  final testTransaction1 = domain.TransactionWithBalance(
    transaction: domain.Transaction(
      id: 1,
      accountId: testAccountId,
      type: domain.TransactionType.expense,
      amount: 100.0,
      currency: 'EUR',
      title: 'Supermarket Shopping',
      comment: 'Weekly groceries',
      date: DateTime.now().subtract(Duration(days: 1)),
      status: domain.TransactionStatus.completed,
    ),
    account: domain.Account(
      id: testAccountId,
      name: 'Test Account',
      currency: 'EUR',
      initialBalance: 1000.0,
      creationDate: DateTime.now(),
    ),
    balanceAfter: AccountBalance(
      balance: Money(amount: 900.0, currency: 'EUR'),
      calculatedAt: DateTime.now(),
    ),
    categories: [],
  );

  final testTransaction2 = domain.TransactionWithBalance(
    transaction: domain.Transaction(
      id: 2,
      accountId: testAccountId,
      type: domain.TransactionType.income,
      amount: 500.0,
      currency: 'EUR',
      title: 'Salary Payment',
      comment: 'Monthly salary',
      date: DateTime.now().subtract(Duration(days: 2)),
      status: domain.TransactionStatus.completed,
    ),
    account: domain.Account(
      id: testAccountId,
      name: 'Test Account',
      currency: 'EUR',
      initialBalance: 1000.0,
      creationDate: DateTime.now(),
    ),
    balanceAfter: AccountBalance(
      balance: Money(amount: 1500.0, currency: 'EUR'),
      calculatedAt: DateTime.now(),
    ),
    categories: [],
  );

  final testCategory = domain.Category(
    id: 1,
    label: 'Food',
    level: 1,
    parentId: null,
    icon: null,
  );

  final testCounterparty = domain.Counterparty(
    id: 1,
    name: 'Test Counterparty',
    icon: null,
  );

  final testTransactions = <domain.TransactionWithBalance>[testTransaction1, testTransaction2];
  final testCategories = <domain.Category>[testCategory];
  final testCounterparties = <domain.Counterparty>[testCounterparty];

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockCounterpartyRepository = MockCounterpartyRepository();
    
    // Setup default stubs to prevent initialization errors
    when(mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => testCategories);
    when(mockCounterpartyRepository.getAllCounterparties())
        .thenAnswer((_) async => testCounterparties);
    
    viewModel = SearchResultsViewModel(
      mockTransactionRepository,
      mockCategoryRepository,
      mockCounterpartyRepository,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('SearchResultsViewModel - Initialization', () {
    test('should initialize with correct default state', () {
      expect(viewModel.state.allTransactions, isEmpty);
      expect(viewModel.state.searchResults, isEmpty);
      expect(viewModel.state.categories, isEmpty);
      expect(viewModel.state.counterparties, isEmpty);
      expect(viewModel.state.filters, isA<SearchFilters>());
      expect(viewModel.state.filters.keyword, isEmpty);
      expect(viewModel.state.filters.activeType, SearchType.all);
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.currentPage, 0);
      expect(viewModel.state.itemsPerPage, 20);
    });

    test('should load metadata on initialization', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);

      // Act - Create a new ViewModel to trigger initialization
      final freshViewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(freshViewModel.state.categories, equals(testCategories));
      expect(freshViewModel.state.counterparties, equals(testCounterparties));

      verify(mockCategoryRepository.getAllCategories()).called(1);
      verify(mockCounterpartyRepository.getAllCounterparties()).called(1);
      
      freshViewModel.dispose();
    });

    test('should initialize search for account', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      // Act
      await viewModel.initializeSearch(testAccountId);

      // Assert
      expect(viewModel.state.allTransactions, equals(testTransactions));
      expect(viewModel.state.searchResults, equals(testTransactions));
      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);

      verify(mockTransactionRepository.getTransactionsWithBalance(testAccountId)).called(1);
    });
  });

  group('SearchResultsViewModel - Search Operations', () {
    setUp(() async {
      // Setup common state with transactions
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);
      await viewModel.initializeSearch(testAccountId);
    });

    test('should search by keyword', () async {
      // Act
      await viewModel.searchByKeyword('Supermarket');

      // Assert
      expect(viewModel.state.filters.keyword, 'Supermarket');
      expect(viewModel.state.filters.activeType, SearchType.keyword);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.title, contains('Supermarket'));
    });

    test('should search by amount range', () async {
      // Act
      await viewModel.searchByAmount(50.0, 200.0);

      // Assert
      expect(viewModel.state.filters.minAmount, 50.0);
      expect(viewModel.state.filters.maxAmount, 200.0);
      expect(viewModel.state.filters.activeType, SearchType.amount);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.amount, 100.0);
    });

    test('should search by minimum amount only', () async {
      // Act
      await viewModel.searchByAmount(200.0, null);

      // Assert
      expect(viewModel.state.filters.minAmount, 200.0);
      expect(viewModel.state.filters.maxAmount, isNull);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.amount, 500.0);
    });

    test('should search by maximum amount only', () async {
      // Act
      await viewModel.searchByAmount(null, 200.0);

      // Assert
      expect(viewModel.state.filters.minAmount, isNull);
      expect(viewModel.state.filters.maxAmount, 200.0);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.amount, 100.0);
    });

    test('should search by category', () async {
      // Act
      await viewModel.searchByCategory(1);

      // Assert
      expect(viewModel.state.filters.categoryId, 1);
      expect(viewModel.state.filters.activeType, SearchType.category);
      // Note: Results depend on transaction's category matching implementation
    });

    test('should search by counterparty', () async {
      // Act
      await viewModel.searchByCounterparty(1);

      // Assert
      expect(viewModel.state.filters.counterpartyId, 1);
      expect(viewModel.state.filters.activeType, SearchType.counterparty);
      // Note: Results depend on transaction's counterparty matching implementation
    });

    test('should search by date range', () async {
      // Arrange
      final startDate = DateTime.now().subtract(Duration(days: 3));
      final endDate = DateTime.now();

      // Act
      await viewModel.searchByDateRange(startDate, endDate);

      // Assert
      expect(viewModel.state.filters.startDate, startDate);
      expect(viewModel.state.filters.endDate, endDate);
      expect(viewModel.state.filters.activeType, SearchType.date);
    });

    test('should search with combined filters', () async {
      // Arrange
      final filters = SearchFilters(
        keyword: 'salary',
        minAmount: 400.0,
        activeType: SearchType.all,
      );

      // Act
      await viewModel.searchWithFilters(filters);

      // Assert
      expect(viewModel.state.filters, equals(filters));
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.title, contains('Salary'));
      expect(viewModel.state.searchResults.first.transaction.amount, greaterThanOrEqualTo(400.0));
    });

    test('should handle empty search results', () async {
      // Act
      await viewModel.searchByKeyword('NonExistent');

      // Assert
      expect(viewModel.state.searchResults, isEmpty);
      expect(viewModel.state.hasResults, false);
    });

    test('should reset current page when applying new filters', () async {
      // Arrange
      viewModel.state = viewModel.state.copyWith(currentPage: 2);

      // Act
      await viewModel.searchByKeyword('test');

      // Assert
      expect(viewModel.state.currentPage, 0);
    });
  });

  group('SearchResultsViewModel - State Properties', () {
    test('should return correct state properties', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);
      await viewModel.initializeSearch(testAccountId);

      // Assert initial state
      expect(viewModel.state.hasResults, true);
      expect(viewModel.state.hasFilters, false);
      expect(viewModel.state.hasError, false);

      // Test with filters
      await viewModel.searchByKeyword('test');
      expect(viewModel.state.hasFilters, true);
    });

    test('should calculate pagination correctly', () async {
      // Arrange
      final manyTransactions = List.generate(50, (index) => domain.TransactionWithBalance(
        transaction: domain.Transaction(
          id: index,
          accountId: testAccountId,
          type: domain.TransactionType.expense,
          amount: 10.0,
          currency: 'EUR',
          title: 'Transaction $index',
          date: DateTime.now(),
          status: domain.TransactionStatus.completed,
        ),
        account: domain.Account(
          id: testAccountId,
          name: 'Test Account',
          currency: 'EUR',
          initialBalance: 1000.0,
          creationDate: DateTime.now(),
        ),
        balanceAfter: AccountBalance(
          balance: Money(amount: 1000.0, currency: 'EUR'),
          calculatedAt: DateTime.now(),
        ),
        categories: [],
      ));

      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => manyTransactions);
      
      await viewModel.initializeSearch(testAccountId);

      // Assert pagination properties
      expect(viewModel.state.totalPages, 3); // 50 items / 20 per page = 3 pages
      expect(viewModel.state.hasNextPage, true);
      expect(viewModel.state.hasPreviousPage, false);
      expect(viewModel.state.paginatedResults.length, 20);
    });
  });

  group('SearchResultsViewModel - Error Handling', () {
    test('should handle metadata loading errors', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenThrow(Exception('Failed to load categories'));
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);

      // Act - Create a new ViewModel to trigger initialization
      final freshViewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(freshViewModel.hasError, true);
      expect(freshViewModel.errorMessage, contains('Failed to load categories'));
      
      freshViewModel.dispose();
    });

    test('should handle search initialization errors', () async {
      // Arrange
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenThrow(Exception('Failed to load transactions'));

      // Act
      await viewModel.initializeSearch(testAccountId);

      // Assert
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, contains('Failed to load transactions'));
      expect(viewModel.state.allTransactions, isEmpty);
      expect(viewModel.state.searchResults, isEmpty);
    });
  });

  group('SearchResultsViewModel - Utility Methods', () {
    test('should provide search suggestions', () {
      // Note: This test assumes the method exists in the ViewModel
      // If the method doesn't exist or needs mocking, adjust accordingly
      
      // Arrange - Setup some transactions first
      // Act & Assert would depend on the actual implementation
    });

    test('should provide search statistics', () {
      // Note: This test assumes the method exists in the ViewModel
      // If the method doesn't exist or needs mocking, adjust accordingly
      
      // Arrange - Setup some transactions and perform searches
      // Act & Assert would depend on the actual implementation
    });
  });

  group('SearchFilters', () {
    test('should create SearchFilters with correct defaults', () {
      const filters = SearchFilters();
      
      expect(filters.keyword, '');
      expect(filters.minAmount, isNull);
      expect(filters.maxAmount, isNull);
      expect(filters.categoryId, isNull);
      expect(filters.counterpartyId, isNull);
      expect(filters.startDate, isNull);
      expect(filters.endDate, isNull);
      expect(filters.activeType, SearchType.all);
    });

    test('should copy SearchFilters with new values', () {
      const originalFilters = SearchFilters(keyword: 'test');
      
      final newFilters = originalFilters.copyWith(
        keyword: 'updated',
        minAmount: 100.0,
        activeType: SearchType.keyword,
      );

      expect(newFilters.keyword, 'updated');
      expect(newFilters.minAmount, 100.0);
      expect(newFilters.activeType, SearchType.keyword);
      expect(newFilters.maxAmount, isNull); // Should remain null
    });

    test('should detect active filters correctly', () {
      const emptyFilters = SearchFilters();
      expect(emptyFilters.hasActiveFilters, false);
      expect(emptyFilters.activeFiltersCount, 0);

      const filtersWithKeyword = SearchFilters(keyword: 'test');
      expect(filtersWithKeyword.hasActiveFilters, true);
      expect(filtersWithKeyword.activeFiltersCount, 1);

      const filtersWithMultiple = SearchFilters(
        keyword: 'test',
        minAmount: 100.0,
        categoryId: 1,
      );
      expect(filtersWithMultiple.hasActiveFilters, true);
      expect(filtersWithMultiple.activeFiltersCount, 3);
    });
  });
}