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

import 'search_results_view_model_simple_test.mocks.dart';

@GenerateMocks([TransactionRepository, CategoryRepository, CounterpartyRepository])
void main() {
  late MockTransactionRepository mockTransactionRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockCounterpartyRepository mockCounterpartyRepository;

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
  });

  group('SearchResultsViewModel - Basic Functionality', () {
    test('should initialize search for account', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      final viewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      // Act
      await viewModel.initializeSearch(testAccountId);

      // Assert
      expect(viewModel.state.allTransactions, equals(testTransactions));
      expect(viewModel.state.searchResults, equals(testTransactions));

      verify(mockTransactionRepository.getTransactionsWithBalance(testAccountId)).called(1);
      viewModel.dispose();
    });

    test('should search by keyword', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      final viewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      await viewModel.initializeSearch(testAccountId);

      // Act
      await viewModel.searchByKeyword('Supermarket');

      // Assert
      expect(viewModel.state.filters.keyword, 'Supermarket');
      expect(viewModel.state.filters.activeType, SearchType.keyword);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.title, contains('Supermarket'));
      
      viewModel.dispose();
    });

    test('should search by amount range', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      final viewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      await viewModel.initializeSearch(testAccountId);

      // Act
      await viewModel.searchByAmount(50.0, 200.0);

      // Assert
      expect(viewModel.state.filters.minAmount, 50.0);
      expect(viewModel.state.filters.maxAmount, 200.0);
      expect(viewModel.state.filters.activeType, SearchType.amount);
      expect(viewModel.state.searchResults.length, 1);
      expect(viewModel.state.searchResults.first.transaction.amount, 100.0);
      
      viewModel.dispose();
    });

    test('should search by category', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      final viewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      await viewModel.initializeSearch(testAccountId);

      // Act
      await viewModel.searchByCategory(1);

      // Assert
      expect(viewModel.state.filters.categoryId, 1);
      expect(viewModel.state.filters.activeType, SearchType.category);
      
      viewModel.dispose();
    });

    test('should handle empty search results', () async {
      // Arrange
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
      when(mockCounterpartyRepository.getAllCounterparties())
          .thenAnswer((_) async => testCounterparties);
      when(mockTransactionRepository.getTransactionsWithBalance(testAccountId))
          .thenAnswer((_) async => testTransactions);

      final viewModel = SearchResultsViewModel(
        mockTransactionRepository,
        mockCategoryRepository,
        mockCounterpartyRepository,
      );

      await viewModel.initializeSearch(testAccountId);

      // Act
      await viewModel.searchByKeyword('NonExistent');

      // Assert
      expect(viewModel.state.searchResults, isEmpty);
      expect(viewModel.state.hasResults, false);
      
      viewModel.dispose();
    });
  });

  group('SearchFilters - Unit Tests', () {
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

  group('SearchResultsViewState - Unit Tests', () {
    test('should return correct state properties', () {
      final state = SearchResultsViewState(
        allTransactions: testTransactions,
        searchResults: testTransactions,
        categories: testCategories,
        counterparties: testCounterparties,
      );

      expect(state.hasResults, true);
      expect(state.hasFilters, false);
      expect(state.hasError, false);
      expect(state.totalPages, 1); // 2 items / 20 per page = 1 page
      expect(state.hasNextPage, false);
      expect(state.hasPreviousPage, false);
    });

    test('should calculate pagination correctly with many items', () {
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

      final state = SearchResultsViewState(
        allTransactions: manyTransactions,
        searchResults: manyTransactions,
      );

      expect(state.totalPages, 3); // 50 items / 20 per page = 3 pages
      expect(state.hasNextPage, true);
      expect(state.hasPreviousPage, false);
      expect(state.paginatedResults.length, 20);
    });
  });
}