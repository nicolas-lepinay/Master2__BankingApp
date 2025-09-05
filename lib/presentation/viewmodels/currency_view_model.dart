import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/core/services/currency_conversion_service.dart';
import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/domain/entities/currency.dart';
import 'package:bankapp/domain/entities/exchange_rate.dart';
import 'package:bankapp/presentation/viewmodels/base_view_model.dart';

/// État du ViewModel de devises
class CurrencyViewState extends BaseViewState {
  final List<Currency> availableCurrencies;
  final Currency? selectedCurrency;
  final Map<String, ExchangeRate> exchangeRates;
  final ConversionResult? lastConversion;
  final bool isConversionLoading;
  final String? conversionError;

  const CurrencyViewState({
    this.availableCurrencies = const [],
    this.selectedCurrency,
    this.exchangeRates = const {},
    this.lastConversion,
    this.isConversionLoading = false,
    this.conversionError,
  });

  CurrencyViewState copyWith({
    List<Currency>? availableCurrencies,
    Currency? selectedCurrency,
    Map<String, ExchangeRate>? exchangeRates,
    ConversionResult? lastConversion,
    bool? isConversionLoading,
    String? conversionError,
  }) {
    return CurrencyViewState(
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      lastConversion: lastConversion ?? this.lastConversion,
      isConversionLoading: isConversionLoading ?? this.isConversionLoading,
      conversionError: conversionError ?? this.conversionError,
    );
  }

  @override
  String toString() =>
      'CurrencyViewState(currencies: ${availableCurrencies.length}, '
      'selected: ${selectedCurrency?.code}, rates: ${exchangeRates.length})';
}

/// ViewModel pour la gestion des devises et conversions
class CurrencyViewModel extends BaseViewModel<CurrencyViewState> {
  final CurrencyConversionService _conversionService;

  CurrencyViewModel(this._conversionService)
    : super(const CurrencyViewState()) {
    _loadAvailableCurrencies();
    _subscribeToExchangeRates();
  }

  /// Charge les devises disponibles
  void _loadAvailableCurrencies() {
    final currencies = SupportedCurrencies.getAllCurrencies();
    state = state.copyWith(availableCurrencies: currencies);
  }

  /// S'abonne aux mises à jour des taux de change
  void _subscribeToExchangeRates() {
    _conversionService.exchangeRatesStream.listen((rates) {
      state = state.copyWith(exchangeRates: rates);
    });
  }

  /// Sélectionne une devise
  void selectCurrency(Currency currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  /// Sélectionne une devise par code
  void selectCurrencyByCode(String currencyCode) {
    final currency = CurrencyService.getCurrency(currencyCode);
    if (currency != null) {
      selectCurrency(currency);
    }
  }

  /// Efface la sélection de devise
  void clearSelection() {
    state = state.copyWith(selectedCurrency: null);
  }

  /// Convertit un montant
  Future<void> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    await executeWithErrorHandling(() async {
      state = state.copyWith(isConversionLoading: true, conversionError: null);

      final result = await _conversionService.convertAmount(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          lastConversion: result,
          isConversionLoading: false,
        );
      } else {
        state = state.copyWith(
          conversionError: result.errorMessage,
          isConversionLoading: false,
        );
      }
    });
  }

  /// Obtient un taux de change
  Future<ExchangeRate?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    return await _conversionService.getExchangeRate(fromCurrency, toCurrency);
  }

  /// Vérifie si un taux de change est disponible
  Future<bool> isExchangeRateAvailable(
    String fromCurrency,
    String toCurrency,
  ) async {
    return await _conversionService.isExchangeRateAvailable(
      fromCurrency,
      toCurrency,
    );
  }

  /// Met à jour les taux de change pour une devise
  Future<void> updateExchangeRates(String baseCurrency) async {
    await executeWithErrorHandling(() async {
      await _conversionService.updateExchangeRates(baseCurrency);
    });
  }

  /// Obtient les devises principales
  List<Currency> getMajorCurrencies() {
    return SupportedCurrencies.getMajorCurrencies();
  }

  /// Obtient les devises mineures
  List<Currency> getMinorCurrencies() {
    return SupportedCurrencies.getMinorCurrencies();
  }

  /// Obtient une devise par code
  Currency? getCurrencyByCode(String code) {
    return CurrencyService.getCurrency(code);
  }

  /// Vérifie si une devise est valide
  bool isValidCurrency(String code) {
    return CurrencyService.isValidCurrency(code);
  }

  /// Formate un montant dans une devise
  String formatAmount(double amount, String currencyCode) {
    final currency = getCurrencyByCode(currencyCode);
    if (currency != null) {
      return currency.formatAmount(amount);
    }
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }

  /// Obtient les statistiques des taux de change
  Map<String, dynamic> getExchangeRateStats() {
    final total = state.exchangeRates.length;
    final validRates = state.exchangeRates.values
        .where((rate) => rate.isValid)
        .length;
    final expiredRates = total - validRates;

    return {
      'total': total,
      'valid': validRates,
      'expired': expiredRates,
      'lastUpdate': _conversionService.lastUpdateTime,
    };
  }

  /// Pré-charge les taux de change courants
  Future<void> preloadCommonRates() async {
    await executeWithErrorHandling(() async {
      await _conversionService.preloadCommonRates();
    });
  }

  /// Obtient la devise sélectionnée
  Currency? get selectedCurrency => state.selectedCurrency;

  /// Obtient les devises disponibles
  List<Currency> get availableCurrencies => state.availableCurrencies;

  /// Obtient les taux de change
  Map<String, ExchangeRate> get exchangeRates => state.exchangeRates;

  /// Obtient la dernière conversion
  ConversionResult? get lastConversion => state.lastConversion;

  /// Vérifie si une conversion est en cours
  bool get isConversionLoading => state.isConversionLoading;

  /// Obtient l'erreur de conversion
  String? get conversionError => state.conversionError;

  @override
  void resetToInitialState() {
    state = const CurrencyViewState();
    _loadAvailableCurrencies();
  }
}
