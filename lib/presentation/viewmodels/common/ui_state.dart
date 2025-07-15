import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

/// État générique pour les données
class DataState<T> extends BaseViewState {
  final T data;
  final bool isLoading;
  final String? error;
  
  const DataState({
    required this.data,
    this.isLoading = false,
    this.error,
  });
  
  DataState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
  }) {
    return DataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
  
  /// Crée un état de chargement
  DataState<T> loading() {
    return copyWith(isLoading: true, error: null);
  }
  
  /// Crée un état de succès
  DataState<T> success(T newData) {
    return DataState<T>(
      data: newData,
      isLoading: false,
      error: null,
    );
  }
  
  /// Crée un état d'erreur
  DataState<T> failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }
  
  bool get hasError => error != null;
  bool get hasData => !isLoading && !hasError;
  
  @override
  String toString() => 'DataState(data: $data, isLoading: $isLoading, error: $error)';
}

/// État pour les listes avec recherche et filtrage
class ListState<T> extends BaseViewState {
  final List<T> items;
  final List<T> filteredItems;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  
  const ListState({
    required this.items,
    required this.filteredItems,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.totalPages = 1,
  });
  
  ListState<T> copyWith({
    List<T>? items,
    List<T>? filteredItems,
    String? searchQuery,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
  }) {
    return ListState<T>(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
  
  /// Crée un état de chargement
  ListState<T> loading() {
    return copyWith(isLoading: true, error: null);
  }
  
  /// Crée un état de succès
  ListState<T> success(List<T> newItems) {
    return ListState<T>(
      items: newItems,
      filteredItems: newItems,
      searchQuery: '',
      isLoading: false,
      error: null,
      currentPage: 0,
      totalPages: 1,
    );
  }
  
  /// Crée un état d'erreur
  ListState<T> failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }
  
  /// Applique un filtre de recherche
  ListState<T> applySearch(String query, bool Function(T, String) searchPredicate) {
    if (query.isEmpty) {
      return copyWith(
        filteredItems: items,
        searchQuery: query,
        currentPage: 0,
      );
    }
    
    final filtered = items.where((item) => searchPredicate(item, query)).toList();
    
    return copyWith(
      filteredItems: filtered,
      searchQuery: query,
      currentPage: 0,
    );
  }
  
  bool get hasError => error != null;
  bool get hasData => !isLoading && !hasError;
  bool get hasItems => filteredItems.isNotEmpty;
  bool get isSearching => searchQuery.isNotEmpty;
  
  @override
  String toString() => 'ListState(items: ${items.length}, filteredItems: ${filteredItems.length}, searchQuery: "$searchQuery", isLoading: $isLoading, error: $error)';
}

/// État pour les formulaires
class FormState<T> extends BaseViewState {
  final T data;
  final Map<String, String> errors;
  final bool isLoading;
  final bool isValid;
  final String? globalError;
  
  const FormState({
    required this.data,
    this.errors = const {},
    this.isLoading = false,
    this.isValid = true,
    this.globalError,
  });
  
  FormState<T> copyWith({
    T? data,
    Map<String, String>? errors,
    bool? isLoading,
    bool? isValid,
    String? globalError,
  }) {
    return FormState<T>(
      data: data ?? this.data,
      errors: errors ?? this.errors,
      isLoading: isLoading ?? this.isLoading,
      isValid: isValid ?? this.isValid,
      globalError: globalError ?? this.globalError,
    );
  }
  
  /// Crée un état de chargement
  FormState<T> loading() {
    return copyWith(isLoading: true, globalError: null);
  }
  
  /// Crée un état de succès
  FormState<T> success(T newData) {
    return FormState<T>(
      data: newData,
      errors: {},
      isLoading: false,
      isValid: true,
      globalError: null,
    );
  }
  
  /// Crée un état d'erreur
  FormState<T> failure(String errorMessage) {
    return copyWith(isLoading: false, globalError: errorMessage);
  }
  
  /// Ajoute une erreur de validation
  FormState<T> addError(String field, String error) {
    final newErrors = Map<String, String>.from(errors);
    newErrors[field] = error;
    
    return copyWith(
      errors: newErrors,
      isValid: false,
    );
  }
  
  /// Supprime une erreur de validation
  FormState<T> removeError(String field) {
    final newErrors = Map<String, String>.from(errors);
    newErrors.remove(field);
    
    return copyWith(
      errors: newErrors,
      isValid: newErrors.isEmpty,
    );
  }
  
  /// Efface toutes les erreurs
  FormState<T> clearErrors() {
    return copyWith(
      errors: {},
      isValid: true,
      globalError: null,
    );
  }
  
  bool get hasErrors => errors.isNotEmpty || globalError != null;
  bool get hasGlobalError => globalError != null;
  
  String? getError(String field) => errors[field];
  
  @override
  String toString() => 'FormState(data: $data, errors: $errors, isLoading: $isLoading, isValid: $isValid, globalError: $globalError)';
}