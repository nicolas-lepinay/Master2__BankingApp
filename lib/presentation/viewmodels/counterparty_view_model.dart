import 'package:bankapp/domain/entities/entities.dart' as domain;
import 'package:bankapp/domain/repositories/repositories.dart';
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

/// État pour la gestion des contreparties
class CounterpartyViewState extends BaseViewState {
  final List<domain.Counterparty> counterparties;
  final domain.Counterparty? selectedCounterparty;
  final bool isLoading;
  final String? error;

  const CounterpartyViewState({
    this.counterparties = const [],
    this.selectedCounterparty,
    this.isLoading = false,
    this.error,
  });

  CounterpartyViewState copyWith({
    List<domain.Counterparty>? counterparties,
    domain.Counterparty? selectedCounterparty,
    bool? isLoading,
    String? error,
  }) {
    return CounterpartyViewState(
      counterparties: counterparties ?? this.counterparties,
      selectedCounterparty: selectedCounterparty ?? this.selectedCounterparty,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  CounterpartyViewState loading() {
    return copyWith(isLoading: true, error: null);
  }

  CounterpartyViewState success({
    List<domain.Counterparty>? counterparties,
    domain.Counterparty? selectedCounterparty,
  }) {
    return CounterpartyViewState(
      counterparties: counterparties ?? this.counterparties,
      selectedCounterparty: selectedCounterparty ?? this.selectedCounterparty,
      isLoading: false,
      error: null,
    );
  }

  CounterpartyViewState failure(String errorMessage) {
    return copyWith(isLoading: false, error: errorMessage);
  }

  bool get hasError => error != null;
  bool get hasCounterparties => counterparties.isNotEmpty;

  @override
  String toString() =>
      'CounterpartyViewState(counterparties: ${counterparties.length}, selectedCounterparty: $selectedCounterparty, isLoading: $isLoading, error: $error)';
}

/// ViewModel pour la gestion des contreparties
class CounterpartyViewModel extends BaseViewModel<CounterpartyViewState> {
  final CounterpartyRepository _counterpartyRepository;

  CounterpartyViewModel(this._counterpartyRepository)
    : super(const CounterpartyViewState());

  /// Charge toutes les contreparties
  Future<void> loadCounterparties() async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final counterparties = await _counterpartyRepository
          .getAllCounterparties();

      state = state.success(counterparties: counterparties);
    });
  }

  /// Crée une nouvelle contrepartie
  Future<void> createCounterparty({required String name, String? icon}) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      final newCounterparty = domain.Counterparty(
        id: 0, // Sera assigné par la base de données
        name: name,
        icon: icon,
      );

      await _counterpartyRepository.createCounterparty(newCounterparty);

      // Recharger les contreparties
      await loadCounterparties();
    });
  }

  /// Met à jour une contrepartie
  Future<void> updateCounterparty({
    required int counterpartyId,
    required String name,
    String? icon,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      // Récupérer la contrepartie existante
      final existingCounterparty = await _counterpartyRepository
          .getCounterpartyById(counterpartyId);
      if (existingCounterparty == null) {
        throw Exception('Counterparty not found: $counterpartyId');
      }

      final updatedCounterparty = existingCounterparty.copyWith(
        name: name,
        icon: icon,
      );

      await _counterpartyRepository.updateCounterparty(updatedCounterparty);

      // Recharger les contreparties
      await loadCounterparties();
    });
  }

  /// Supprime une contrepartie
  Future<void> deleteCounterparty(int counterpartyId) async {
    await executeWithErrorHandling(() async {
      state = state.loading();

      await _counterpartyRepository.deleteCounterparty(counterpartyId);

      // Recharger les contreparties
      await loadCounterparties();
    });
  }

  /// Sélectionne une contrepartie
  void selectCounterparty(domain.Counterparty counterparty) {
    state = state.copyWith(selectedCounterparty: counterparty);
  }

  /// Désélectionne la contrepartie
  void clearSelection() {
    state = state.copyWith(selectedCounterparty: null);
  }

  /// Obtient une contrepartie par ID
  domain.Counterparty? getCounterpartyById(int counterpartyId) {
    try {
      return state.counterparties.firstWhere(
        (counterparty) => counterparty.id == counterpartyId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Recherche des contreparties par nom
  List<domain.Counterparty> searchCounterparties(String query) {
    if (query.isEmpty) return state.counterparties;

    return state.counterparties
        .where(
          (counterparty) =>
              counterparty.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadCounterparties();
  }

  @override
  void resetToInitialState() {
    state = const CounterpartyViewState();
  }
}
