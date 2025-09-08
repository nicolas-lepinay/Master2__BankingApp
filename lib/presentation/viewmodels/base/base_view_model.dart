import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de base pour tous les ViewModels
abstract class BaseViewState {
  const BaseViewState();
}

/// État de chargement
class LoadingState extends BaseViewState {
  const LoadingState();
}

/// État d'erreur
class ErrorState extends BaseViewState {
  final String message;
  final Object? error;

  const ErrorState(this.message, [this.error]);

  @override
  String toString() => 'ErrorState(message: $message, error: $error)';
}

/// ViewModel de base avec gestion d'état commune
abstract class BaseViewModel<T extends BaseViewState> extends StateNotifier<T> {
  BaseViewModel(super.initialState);

  /// Indique si le ViewModel est en cours de chargement
  bool get isLoading => state is LoadingState;

  /// Indique si le ViewModel est en erreur
  bool get hasError => state is ErrorState;

  /// Obtient le message d'erreur s'il y en a un
  String? get errorMessage =>
      state is ErrorState ? (state as ErrorState).message : null;

  /// Exécute une action avec gestion d'erreur automatique
  Future<void> executeWithErrorHandling(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Error in $runtimeType: $error');
        print('StackTrace: $stackTrace');
      }

      final errorMessage = error.toString();
      state = ErrorState(errorMessage, error) as T;
    }
  }

  /// Exécute une action avec état de chargement
  Future<void> executeWithLoading(Future<void> Function() action) async {
    state = const LoadingState() as T;
    await executeWithErrorHandling(action);
  }

  /// Réinitialise l'état d'erreur
  void clearError() {
    if (hasError) {
      // Sous-classes doivent override cette méthode pour revenir à un état valide
      resetToInitialState();
    }
  }

  /// Remet le ViewModel à son état initial
  void resetToInitialState();

  /// Méthode appelée quand le ViewModel est disposé
  @override
  void dispose() {
    super.dispose();
  }
}

/// Mixin pour les ViewModels qui gèrent des listes
mixin ListViewModelMixin<T extends BaseViewState, Item> on BaseViewModel<T> {
  /// Filtre les éléments d'une liste
  List<Item> filterItems(List<Item> items, bool Function(Item) predicate) {
    return items.where(predicate).toList();
  }

  /// Trie les éléments d'une liste
  List<Item> sortItems(List<Item> items, int Function(Item, Item) compare) {
    final sortedItems = List<Item>.from(items);
    sortedItems.sort(compare);
    return sortedItems;
  }

  /// Recherche des éléments dans une liste
  List<Item> searchItems(
    List<Item> items,
    String query,
    String Function(Item) getText,
  ) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      final text = getText(item).toLowerCase();
      return text.contains(lowerQuery);
    }).toList();
  }
}

/// Mixin pour les ViewModels qui gèrent la pagination
mixin PaginationViewModelMixin<T extends BaseViewState, Item>
    on BaseViewModel<T> {
  int _currentPage = 0;
  int _itemsPerPage = 20;

  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;

  /// Obtient les éléments pour la page actuelle
  List<Item> getPaginatedItems(List<Item> allItems) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allItems.length);

    if (startIndex >= allItems.length) return [];

    return allItems.sublist(startIndex, endIndex);
  }

  /// Passe à la page suivante
  void nextPage() {
    _currentPage++;
  }

  /// Passe à la page précédente
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
    }
  }

  /// Va à une page spécifique
  void goToPage(int page) {
    _currentPage = page.clamp(0, double.infinity).toInt();
  }

  /// Définit le nombre d'éléments par page
  void setItemsPerPage(int itemsPerPage) {
    _itemsPerPage = itemsPerPage.clamp(1, 100);
    _currentPage = 0; // Reset à la première page
  }

  /// Réinitialise la pagination
  void resetPagination() {
    _currentPage = 0;
  }

  /// Calcule le nombre total de pages
  int getTotalPages(int totalItems) {
    return (totalItems / _itemsPerPage).ceil();
  }

  /// Indique s'il y a une page suivante
  bool hasNextPage(int totalItems) {
    return (_currentPage + 1) * _itemsPerPage < totalItems;
  }

  /// Indique s'il y a une page précédente
  bool get hasPreviousPage => _currentPage > 0;
}
