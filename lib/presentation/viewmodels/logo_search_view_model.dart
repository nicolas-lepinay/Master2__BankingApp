import 'package:bankapp/core/services/brandfetch_service.dart';
import 'package:bankapp/core/utils/app_logger.dart';
import 'package:bankapp/domain/entities/entities.dart';
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

/// État pour LogoSearchViewModel
class LogoSearchViewState extends BaseViewState {
  final List<BrandLogo> searchResults;
  final String searchQuery;
  final BrandLogo? selectedLogo;
  final bool isSearching;
  final String? errorMessage;

  const LogoSearchViewState({
    this.searchResults = const [],
    this.searchQuery = '',
    this.selectedLogo,
    this.isSearching = false,
    this.errorMessage,
  });

  LogoSearchViewState copyWith({
    List<BrandLogo>? searchResults,
    String? searchQuery,
    BrandLogo? selectedLogo,
    bool? isSearching,
    String? errorMessage,
    bool clearSelectedLogo = false,
    bool clearError = false,
  }) {
    return LogoSearchViewState(
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLogo: clearSelectedLogo ? null : (selectedLogo ?? this.selectedLogo),
      isSearching: isSearching ?? this.isSearching,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasResults => searchResults.isNotEmpty;
  bool get hasError => errorMessage != null;
}

/// ViewModel pour gérer la recherche de logos
class LogoSearchViewModel extends BaseViewModel<LogoSearchViewState> with AppLoggerMixin {
  final BrandfetchService _brandfetchService;

  LogoSearchViewModel({
    required BrandfetchService brandfetchService,
  }) : _brandfetchService = brandfetchService,
       super(const LogoSearchViewState());

  // Getters
  List<BrandLogo> get searchResults => state.searchResults;
  String get searchQuery => state.searchQuery;
  BrandLogo? get selectedLogo => state.selectedLogo;
  bool get isSearching => state.isSearching;
  @override
  String? get errorMessage => state.errorMessage;
  bool get hasResults => state.hasResults;
  @override
  bool get hasError => state.hasError;

  @override
  void resetToInitialState() {
    state = const LogoSearchViewState();
  }

  /// Définit la requête de recherche initiale
  void setInitialQuery(String query) {
    if (query != state.searchQuery) {
      state = state.copyWith(searchQuery: query, clearError: true);
    }
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    if (query != state.searchQuery) {
      state = state.copyWith(searchQuery: query, clearError: true);
    }
  }

  /// Lance la recherche de logos
  Future<void> searchLogos() async {
    if (state.searchQuery.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'La recherche ne peut pas être vide');
      return;
    }

    if (state.isSearching) return;

    logInfo('searchLogos', 'Searching logos for: "${state.searchQuery}"');
    
    state = state.copyWith(
      isSearching: true,
      clearError: true,
      searchResults: [],
    );

    try {
      final response = await _brandfetchService.searchLogos(state.searchQuery);
      
      if (response.success) {
        logInfo('searchLogos', 'Found ${response.logos.length} logos for "${state.searchQuery}"');
        
        if (response.logos.isEmpty) {
          state = state.copyWith(
            isSearching: false,
            errorMessage: 'Aucun logo trouvé pour "${state.searchQuery}"',
          );
        } else {
          state = state.copyWith(
            isSearching: false,
            searchResults: response.logos,
          );
        }
      } else {
        state = state.copyWith(
          isSearching: false,
          errorMessage: response.error ?? 'Erreur lors de la recherche',
        );
        logError('searchLogos', 'Logo search failed', Exception(response.error ?? 'Unknown error'));
      }
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: _getErrorMessage(e),
      );
      logError('searchLogos', 'Logo search error for "${state.searchQuery}"', e);
    }
  }

  /// Sélectionne un logo
  void selectLogo(BrandLogo logo) {
    state = state.copyWith(selectedLogo: logo);
    logInfo('selectLogo', 'Logo selected: ${logo.name} (${logo.domain})');
  }

  /// Désélectionne le logo actuel
  void clearSelectedLogo() {
    state = state.copyWith(clearSelectedLogo: true);
    logInfo('clearSelectedLogo', 'Logo selection cleared');
  }

  /// Efface les résultats de recherche
  void clearSearchResults() {
    state = state.copyWith(searchResults: [], clearError: true);
  }

  /// Remet à zéro l'état complet
  void reset() {
    resetToInitialState();
  }

  /// Convertit une exception en message d'erreur utilisateur
  String _getErrorMessage(dynamic error) {
    if (error is BrandfetchAuthException) {
      return 'Problème d\'authentification avec le service de logos';
    } else if (error is BrandfetchRateLimitException) {
      return 'Trop de requêtes. Veuillez réessayer plus tard';
    } else if (error is BrandfetchNetworkException) {
      return 'Problème de connexion internet';
    } else if (error is BrandfetchParseException) {
      return 'Erreur lors du traitement de la réponse';
    } else if (error is BrandfetchException) {
      return 'Erreur lors de la recherche de logos';
    } else {
      return 'Erreur inattendue lors de la recherche';
    }
  }

  @override
  void dispose() {
    _brandfetchService.dispose();
    super.dispose();
  }
}