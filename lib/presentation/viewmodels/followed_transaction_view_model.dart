import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/transaction_repository.dart';
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

class FollowedTransactionViewState extends BaseViewState {
  final List<domain.TransactionWithBalance> followedTransactions;
  final bool isLoading;
  final String? error;

  const FollowedTransactionViewState({
    this.followedTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  FollowedTransactionViewState copyWith({
    List<domain.TransactionWithBalance>? followedTransactions,
    bool? isLoading,
    String? error,
  }) {
    return FollowedTransactionViewState(
      followedTransactions: followedTransactions ?? this.followedTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  FollowedTransactionViewState loading() => copyWith(
        isLoading: true,
        error: null,
      );

  FollowedTransactionViewState success(
    List<domain.TransactionWithBalance> transactions,
  ) =>
      copyWith(
        followedTransactions: transactions,
        isLoading: false,
        error: null,
      );

  FollowedTransactionViewState failure(String error) => copyWith(
        isLoading: false,
        error: error,
      );

  List<Object?> get props => [followedTransactions, isLoading, error];

  bool get hasError => error != null;
  bool get isEmpty => followedTransactions.isEmpty && !isLoading && !hasError;
}

class FollowedTransactionViewModel
    extends BaseViewModel<FollowedTransactionViewState> {
  final TransactionRepository _transactionRepository;

  FollowedTransactionViewModel(this._transactionRepository)
      : super(const FollowedTransactionViewState());

  /// Charge les transactions suivies
  Future<void> loadFollowedTransactions() async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final transactions =
          await _transactionRepository.getFollowedTransactionsWithDetails();

      state = state.success(transactions);
    });
  }

  /// Retire une transaction du suivi
  Future<void> unfollowTransaction(int transactionId) async {
    await executeWithErrorHandling(() async {
      await _transactionRepository.unfollowTransaction(transactionId);

      // Recharger la liste après suppression
      await loadFollowedTransactions();
    });
  }

  /// Ajoute une transaction au suivi
  Future<void> followTransaction(int transactionId) async {
    await executeWithErrorHandling(() async {
      await _transactionRepository.followTransaction(transactionId);

      // Recharger la liste après ajout
      await loadFollowedTransactions();
    });
  }

  /// Rafraîchit les transactions suivies
  Future<void> refresh() async {
    await loadFollowedTransactions();
  }


  @override
  void resetToInitialState() {
    state = const FollowedTransactionViewState();
  }
}