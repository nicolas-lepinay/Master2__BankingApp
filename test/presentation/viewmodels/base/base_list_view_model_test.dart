import 'package:flutter_test/flutter_test.dart';
import 'package:bankapp/presentation/viewmodels/base/base_list_view_model.dart';
import 'package:bankapp/domain/value_objects/date_range.dart';

/// Entité simple pour les tests
class TestItem {
  final int id;
  final String name;
  final DateTime date;
  
  const TestItem({
    required this.id,
    required this.name,
    required this.date,
  });
}

/// État de test qui implémente BaseListViewState
class TestListViewState extends BaseListViewState<TestItem> {
  const TestListViewState({
    super.items,
    super.filteredItems,
    super.searchQuery,
    super.currentPage,
    super.itemsPerPage,
    super.isLoading,
    super.error,
    super.dateFilter,
  });

  TestListViewState copyWith({
    List<TestItem>? items,
    List<TestItem>? filteredItems,
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
    bool? isLoading,
    String? error,
    DateRange? dateFilter,
  }) {
    return TestListViewState(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

/// ViewModel de test qui implémente BaseListViewModel
class TestListViewModel extends BaseListViewModel<TestListViewState, TestItem> {
  final List<TestItem> _mockData;

  TestListViewModel(this._mockData) : super(const TestListViewState());

  @override
  Future<List<TestItem>> loadAllItems() async {
    // Simule un délai de chargement
    await Future.delayed(const Duration(milliseconds: 10));
    return _mockData;
  }

  @override
  List<TestItem> applySearchFilter(List<TestItem> items, String query) {
    final lowerQuery = query.toLowerCase();
    return items.where((item) => 
        item.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  @override
  List<TestItem> applyDateFilter(List<TestItem> items, DateRange dateRange) {
    return items.where((item) =>
        item.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
        item.date.isBefore(dateRange.end.add(const Duration(days: 1)))
    ).toList();
  }

  @override
  List<TestItem> sortItems(List<TestItem> items) {
    final sorted = List<TestItem>.from(items);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  // Méthodes d'état requises par BaseListViewModel
  @override
  TestListViewState setLoading(bool isLoading) {
    return (state as TestListViewState).copyWith(isLoading: isLoading, error: null);
  }

  @override
  TestListViewState setError(String error) {
    return (state as TestListViewState).copyWith(error: error, isLoading: false);
  }

  @override
  TestListViewState setItems(List<TestItem> items) {
    return (state as TestListViewState).copyWith(
      items: items,
      filteredItems: items,
      isLoading: false,
      error: null,
    );
  }

  @override
  TestListViewState setFilteredItems(List<TestItem> filteredItems) {
    return (state as TestListViewState).copyWith(
      filteredItems: filteredItems,
      currentPage: 0, // Reset pagination
    );
  }

  @override
  TestListViewState updateSearchQueryState(String query) {
    return (state as TestListViewState).copyWith(searchQuery: query);
  }

  @override
  TestListViewState updateDateFilterState(DateRange? dateFilter) {
    return (state as TestListViewState).copyWith(dateFilter: dateFilter);
  }

  @override
  TestListViewState setCurrentPage(int currentPage) {
    return (state as TestListViewState).copyWith(currentPage: currentPage);
  }

  @override
  TestListViewState setItemsPerPage(int itemsPerPage) {
    return (state as TestListViewState).copyWith(itemsPerPage: itemsPerPage);
  }

  @override
  TestListViewState clearFiltersState() {
    return const TestListViewState(
      items: [],
      filteredItems: [],
      searchQuery: '',
      currentPage: 0,
      itemsPerPage: 20,
      isLoading: false,
      error: null,
      dateFilter: null,
    ).copyWith(
      items: state.items,
      filteredItems: state.items,
    );
  }
}

void main() {
  group('BaseListViewModel', () {
    late TestListViewModel viewModel;
    late List<TestItem> mockData;

    setUp(() {
      mockData = [
        TestItem(id: 1, name: 'Apple', date: DateTime(2024, 1, 1)),
        TestItem(id: 2, name: 'Banana', date: DateTime(2024, 1, 5)),
        TestItem(id: 3, name: 'Cherry', date: DateTime(2024, 1, 10)),
        TestItem(id: 4, name: 'Date', date: DateTime(2024, 1, 15)),
        TestItem(id: 5, name: 'Elderberry', date: DateTime(2024, 1, 20)),
      ];
      viewModel = TestListViewModel(mockData);
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Initialization and Loading', () {
      test('should have empty initial state', () {
        expect(viewModel.state.items, isEmpty);
        expect(viewModel.state.filteredItems, isEmpty);
        expect(viewModel.state.searchQuery, equals(''));
        expect(viewModel.state.currentPage, equals(0));
        expect(viewModel.state.isLoading, isFalse);
      });

      test('should load all items on refresh', () async {
        await viewModel.refresh();

        expect(viewModel.state.items, hasLength(5));
        expect(viewModel.state.filteredItems, hasLength(5));
        expect(viewModel.state.isLoading, isFalse);
        expect(viewModel.state.hasError, isFalse);
      });

      test('should initialize once', () async {
        await viewModel.initialize();
        expect(viewModel.state.hasItems, isTrue);

        // Second call should not reload
        final currentItems = viewModel.state.items;
        await viewModel.initialize();
        expect(viewModel.state.items, same(currentItems));
      });
    });

    group('Search Functionality', () {
      setUp(() async {
        await viewModel.refresh();
      });

      test('should filter items by search query', () async {
        await viewModel.updateSearchQuery('a'); // Apple, Banana, Date

        expect(viewModel.state.searchQuery, equals('a'));
        expect(viewModel.state.filteredItems, hasLength(3));
        expect(viewModel.state.isFiltered, isTrue);
      });

      test('should clear search query', () async {
        await viewModel.updateSearchQuery('apple');
        expect(viewModel.state.filteredItems, hasLength(1));

        await viewModel.clearSearch();
        expect(viewModel.state.searchQuery, equals(''));
        expect(viewModel.state.filteredItems, hasLength(5));
        expect(viewModel.state.isFiltered, isFalse);
      });

      test('should reset pagination when search changes', () async {
        // D'abord configurer plus de 2 éléments par page pour pouvoir vraiment changer de page
        viewModel.updateItemsPerPage(2);
        viewModel.goToPage(1); // Va à la page 1 (qui devrait contenir "Cherry", "Date")
        expect(viewModel.state.currentPage, equals(1));

        await viewModel.updateSearchQuery('apple');
        // La pagination devrait être reset à 0 par setFilteredItems
        expect(viewModel.state.currentPage, equals(0));
      });
    });

    group('Date Filtering', () {
      setUp(() async {
        await viewModel.refresh();
      });

      test('should filter items by date range', () async {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 10),
        );

        await viewModel.updateDateFilter(dateRange);

        expect(viewModel.state.dateFilter, equals(dateRange));
        expect(viewModel.state.filteredItems, hasLength(3)); // Apple, Banana, Cherry
        expect(viewModel.state.isFiltered, isTrue);
      });

      test('should clear all filters', () async {
        await viewModel.updateSearchQuery('apple');
        await viewModel.updateDateFilter(DateRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 5),
        ));

        expect(viewModel.state.isFiltered, isTrue);

        await viewModel.clearFilters();

        expect(viewModel.state.searchQuery, equals(''));
        expect(viewModel.state.dateFilter, isNull);
        expect(viewModel.state.filteredItems, hasLength(5));
        expect(viewModel.state.isFiltered, isFalse);
      });
    });

    group('Pagination', () {
      setUp(() async {
        await viewModel.refresh();
        viewModel.updateItemsPerPage(2); // 2 items per page
      });

      test('should calculate pagination correctly', () {
        expect(viewModel.state.totalPages, equals(3)); // 5 items / 2 per page = 3 pages
        expect(viewModel.state.hasNextPage, isTrue);
        expect(viewModel.state.hasPreviousPage, isFalse);
      });

      test('should get paginated items correctly', () {
        final paginatedItems = viewModel.state.paginatedItems;
        expect(paginatedItems, hasLength(2));
        expect(paginatedItems.first.name, equals('Apple')); // Sorted alphabetically
      });

      test('should navigate between pages', () {
        viewModel.nextPage();
        expect(viewModel.state.currentPage, equals(1));
        expect(viewModel.state.paginatedItems, hasLength(2));

        viewModel.previousPage();
        expect(viewModel.state.currentPage, equals(0));
      });

      test('should not go beyond page bounds', () {
        // Try to go to previous page when already at first page
        viewModel.previousPage();
        expect(viewModel.state.currentPage, equals(0));

        // Go to last page and try to go beyond
        viewModel.goToPage(2);
        viewModel.nextPage();
        expect(viewModel.state.currentPage, equals(2));
      });

      test('should update items per page', () {
        viewModel.updateItemsPerPage(3);
        expect(viewModel.state.itemsPerPage, equals(3));
        expect(viewModel.state.currentPage, equals(0)); // Should reset to first page
        expect(viewModel.state.totalPages, equals(2)); // 5 items / 3 per page = 2 pages
      });

      test('should provide pagination info', () {
        expect(viewModel.state.paginationInfo, equals('1-2 sur 5'));
        
        viewModel.nextPage();
        expect(viewModel.state.paginationInfo, equals('3-4 sur 5'));
      });
    });

    group('State Properties', () {
      test('should calculate derived state correctly', () {
        expect(viewModel.state.hasItems, isFalse);
        expect(viewModel.state.hasFilteredItems, isFalse);
        expect(viewModel.state.isFiltered, isFalse);
      });

      test('should detect loaded and filtered state', () async {
        await viewModel.refresh();
        
        expect(viewModel.state.hasItems, isTrue);
        expect(viewModel.state.hasFilteredItems, isTrue);
        expect(viewModel.state.isFiltered, isFalse);

        await viewModel.updateSearchQuery('apple');
        expect(viewModel.state.isFiltered, isTrue);
      });
    });

    group('Sorting', () {
      setUp(() async {
        await viewModel.refresh();
      });

      test('should sort items alphabetically', () {
        final sortedItems = viewModel.state.filteredItems;
        expect(sortedItems.first.name, equals('Apple'));
        expect(sortedItems.last.name, equals('Elderberry'));
      });
    });
  });
}