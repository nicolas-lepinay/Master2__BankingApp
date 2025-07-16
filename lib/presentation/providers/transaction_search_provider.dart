import 'package:bankapp/data/database/models/transaction_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// État de recherche
class TransactionSearchState {
  final String amountQuery;
  final String keywordQuery;
  final List<TransactionWithBalance> filteredTransactions;
  final bool isSearchActive;

  TransactionSearchState({
    this.amountQuery = '',
    this.keywordQuery = '',
    this.filteredTransactions = const [],
    this.isSearchActive = false,
  });

  TransactionSearchState copyWith({
    String? amountQuery,
    String? keywordQuery,
    List<TransactionWithBalance>? filteredTransactions,
    bool? isSearchActive,
  }) {
    return TransactionSearchState(
      amountQuery: amountQuery ?? this.amountQuery,
      keywordQuery: keywordQuery ?? this.keywordQuery,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }
}

// Notifier pour gérer la recherche
class TransactionSearchNotifier extends StateNotifier<TransactionSearchState> {
  TransactionSearchNotifier() : super(TransactionSearchState());

  List<TransactionWithBalance> _originalTransactions = [];

  // Initialiser avec la liste complète des transactions
  void setOriginalTransactions(List<TransactionWithBalance> transactions) {
    _originalTransactions = transactions;
    if (!state.isSearchActive) {
      state = state.copyWith(filteredTransactions: transactions);
    }
  }

  // Recherche par montant
  void searchByAmount(String query) {
    state = state.copyWith(amountQuery: query);
    _performSearch();
  }

  // Recherche par mot-clé
  void searchByKeyword(String query) {
    state = state.copyWith(keywordQuery: query);
    _performSearch();
  }

  // Effacer les recherches
  void clearSearch() {
    state = TransactionSearchState(
      filteredTransactions: _originalTransactions,
      isSearchActive: false,
    );
  }

  // Effectuer la recherche combinée
  void _performSearch() {
    final amountQuery = state.amountQuery.trim();
    final keywordQuery = state.keywordQuery.trim().toLowerCase();

    // Si aucune recherche, afficher tout
    if (amountQuery.isEmpty && keywordQuery.isEmpty) {
      state = state.copyWith(
        filteredTransactions: _originalTransactions,
        isSearchActive: false,
      );
      return;
    }

    // Filtrer les transactions
    List<TransactionWithBalance> filteredTransactions = _originalTransactions;

    // Filtrage par montant
    if (amountQuery.isNotEmpty) {
      filteredTransactions = _filterByAmount(filteredTransactions, amountQuery);
    }

    // Filtrage par mot-clé
    if (keywordQuery.isNotEmpty) {
      filteredTransactions = _filterByKeyword(
        filteredTransactions,
        keywordQuery,
      );
    }

    state = state.copyWith(
      filteredTransactions: filteredTransactions,
      isSearchActive: true,
    );
  }

  // Filtrage par montant avec logique spécifique
  List<TransactionWithBalance> _filterByAmount(
    List<TransactionWithBalance> transactions,
    String amountQuery,
  ) {
    // Remplacer les virgules par des points
    String normalizedQuery = amountQuery.replaceAll(',', '.');

    try {
      double? queryAmount = double.tryParse(normalizedQuery);
      if (queryAmount == null) return transactions;

      return transactions.where((transactionWithBalance) {
        final amount = transactionWithBalance.transaction.amount;

        // Si le query est un entier (pas de point décimal)
        if (!normalizedQuery.contains('.')) {
          // Recherche dans la plage [montant, montant+0.99]
          int integerAmount = queryAmount.toInt();
          return amount >= integerAmount && amount < (integerAmount + 1);
        } else {
          // Recherche exacte pour les nombres décimaux
          return (amount - queryAmount).abs() <
              0.01; // Tolérance pour les erreurs de virgule flottante
        }
      }).toList();
    } catch (e) {
      // En cas d'erreur de parsing, retourner la liste non filtrée
      return transactions;
    }
  }

  // Filtrage par mot-clé dans plusieurs champs
  List<TransactionWithBalance> _filterByKeyword(
    List<TransactionWithBalance> transactions,
    String keywordQuery,
  ) {
    return transactions.where((transactionWithBalance) {
      final transaction = transactionWithBalance.transaction;

      // Recherche dans le titre
      if (transaction.title?.toLowerCase().contains(keywordQuery) == true) {
        return true;
      }

      // Recherche dans le commentaire
      if (transaction.comment?.toLowerCase().contains(keywordQuery) == true) {
        return true;
      }

      // TODO: Recherche dans le nom du tiers (counterparty)
      // Note: Il faudrait récupérer les counterparties depuis la base de données
      // pour avoir accès au nom. Pour l'instant, on se concentre sur title et comment.

      // TODO: Recherche dans les catégories
      // Note: Même chose pour les catégories, il faudrait les récupérer depuis la base.

      return false;
    }).toList();
  }
}

// Provider pour la recherche de transactions
final transactionSearchProvider =
    StateNotifierProvider<TransactionSearchNotifier, TransactionSearchState>(
      (ref) => TransactionSearchNotifier(),
    );
