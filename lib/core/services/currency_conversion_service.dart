import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/domain/entities/exchange_rate.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';

/// Service de conversion de devises haut niveau
class CurrencyConversionService {
  final CacheManager _cacheManager;
  final ExchangeRateRepository _exchangeRateRepository;

  CurrencyConversionService(
    this._cacheManager,
    this._exchangeRateRepository,
  );

  /// Convertit un montant d'une devise à une autre
  Future<ConversionResult> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    // Validation des paramètres
    if (amount < 0) {
      return ConversionResult.error('Amount cannot be negative');
    }

    if (!CurrencyService.isValidCurrency(fromCurrency)) {
      return ConversionResult.error('From currency $fromCurrency is not supported');
    }

    if (!CurrencyService.isValidCurrency(toCurrency)) {
      return ConversionResult.error('To currency $toCurrency is not supported');
    }

    // Cas spécial : même devise
    if (fromCurrency == toCurrency) {
      return ConversionResult.success(
        originalAmount: amount,
        convertedAmount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        exchangeRate: 1.0,
        source: ConversionSource.identity,
      );
    }

    try {
      // Essayer la conversion via le cache manager
      final convertedAmount = await _cacheManager.convertAmount(
        amount,
        fromCurrency,
        toCurrency,
      );

      if (convertedAmount != null) {
        // Obtenir le taux de change utilisé
        final exchangeRate = await _cacheManager.getExchangeRate(fromCurrency, toCurrency);
        
        return ConversionResult.success(
          originalAmount: amount,
          convertedAmount: convertedAmount,
          fromCurrency: fromCurrency,
          toCurrency: toCurrency,
          exchangeRate: exchangeRate?.rate ?? 1.0,
          source: ConversionSource.cache,
          lastUpdated: exchangeRate?.lastUpdated,
        );
      }

      // Si la conversion via cache échoue, essayer directement le repository
      final repositoryAmount = await _exchangeRateRepository.convertAmount(
        amount,
        fromCurrency,
        toCurrency,
      );

      final exchangeRate = await _exchangeRateRepository.getExchangeRate(fromCurrency, toCurrency);

      return ConversionResult.success(
        originalAmount: amount,
        convertedAmount: repositoryAmount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        exchangeRate: exchangeRate?.rate ?? 1.0,
        source: ConversionSource.api,
        lastUpdated: exchangeRate?.lastUpdated,
      );

    } catch (e) {
      return ConversionResult.error('Conversion failed: ${e.toString()}');
    }
  }

  /// Convertit un montant avec gestion d'erreur silencieuse
  Future<double?> convertAmountSafe({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final result = await convertAmount(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );

    return result.isSuccess ? result.convertedAmount : null;
  }

  /// Obtient un taux de change
  Future<ExchangeRate?> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (!CurrencyService.isValidCurrency(fromCurrency) ||
        !CurrencyService.isValidCurrency(toCurrency)) {
      return null;
    }

    return await _cacheManager.getExchangeRate(fromCurrency, toCurrency);
  }

  /// Vérifie si un taux de change est disponible
  Future<bool> isExchangeRateAvailable(String fromCurrency, String toCurrency) async {
    return await _cacheManager.isExchangeRateAvailable(fromCurrency, toCurrency);
  }

  /// Met à jour les taux de change pour une devise
  Future<void> updateExchangeRates(String baseCurrency) async {
    if (!CurrencyService.isValidCurrency(baseCurrency)) return;

    await _cacheManager.updateExchangeRates(baseCurrency);
  }

  /// Met à jour les taux de change pour toutes les devises principales
  Future<void> updateAllMajorCurrencies() async {
    final majorCurrencies = CurrencyService.getMajorCurrencyCodes();
    
    for (final currency in majorCurrencies) {
      try {
        await updateExchangeRates(currency);
      } catch (e) {
        // Continuer avec les autres devises
        continue;
      }
    }
  }

  /// Obtient tous les taux de change en cache
  Map<String, ExchangeRate> getAllExchangeRates() {
    return _cacheManager.getAllExchangeRates();
  }

  /// Obtient la date de dernière mise à jour des taux
  DateTime? get lastUpdateTime => _cacheManager.lastExchangeRateUpdate;

  /// Stream des taux de change
  Stream<Map<String, ExchangeRate>> get exchangeRatesStream => 
      _cacheManager.exchangeRatesStream;

  /// Pré-charge les taux de change courants
  Future<void> preloadCommonRates() async {
    final commonPairs = [
      ('EUR', 'USD'),
      ('USD', 'EUR'),
      ('GBP', 'USD'),
      ('USD', 'GBP'),
      ('EUR', 'GBP'),
      ('GBP', 'EUR'),
      ('USD', 'JPY'),
      ('JPY', 'USD'),
    ];

    for (final (from, to) in commonPairs) {
      try {
        await getExchangeRate(from, to);
      } catch (e) {
        // Ignorer les erreurs de pré-chargement
        continue;
      }
    }
  }
}

/// Résultat d'une conversion de devise
class ConversionResult {
  final bool isSuccess;
  final double? originalAmount;
  final double? convertedAmount;
  final String? fromCurrency;
  final String? toCurrency;
  final double? exchangeRate;
  final ConversionSource? source;
  final DateTime? lastUpdated;
  final String? errorMessage;

  const ConversionResult._({
    required this.isSuccess,
    this.originalAmount,
    this.convertedAmount,
    this.fromCurrency,
    this.toCurrency,
    this.exchangeRate,
    this.source,
    this.lastUpdated,
    this.errorMessage,
  });

  /// Crée un résultat de succès
  factory ConversionResult.success({
    required double originalAmount,
    required double convertedAmount,
    required String fromCurrency,
    required String toCurrency,
    required double exchangeRate,
    required ConversionSource source,
    DateTime? lastUpdated,
  }) {
    return ConversionResult._(
      isSuccess: true,
      originalAmount: originalAmount,
      convertedAmount: convertedAmount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      exchangeRate: exchangeRate,
      source: source,
      lastUpdated: lastUpdated,
    );
  }

  /// Crée un résultat d'erreur
  factory ConversionResult.error(String message) {
    return ConversionResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  /// Obtient le message d'affichage de la conversion
  String getDisplayMessage() {
    if (!isSuccess) {
      return errorMessage ?? 'Conversion failed';
    }

    final fromCurrency = this.fromCurrency ?? '';
    final toCurrency = this.toCurrency ?? '';
    final originalAmount = this.originalAmount ?? 0.0;
    final convertedAmount = this.convertedAmount ?? 0.0;
    final exchangeRate = this.exchangeRate ?? 1.0;

    return '${originalAmount.toStringAsFixed(2)} $fromCurrency = '
           '${convertedAmount.toStringAsFixed(2)} $toCurrency '
           '(rate: ${exchangeRate.toStringAsFixed(4)})';
  }

  @override
  String toString() => getDisplayMessage();
}

/// Source de la conversion
enum ConversionSource {
  /// Conversion d'identité (même devise)
  identity,
  
  /// Conversion depuis le cache
  cache,
  
  /// Conversion depuis l'API
  api,
}

/// Extension pour ConversionSource
extension ConversionSourceExtension on ConversionSource {
  /// Obtient la description de la source
  String get description {
    switch (this) {
      case ConversionSource.identity:
        return 'Same currency';
      case ConversionSource.cache:
        return 'Cached rate';
      case ConversionSource.api:
        return 'Live rate';
    }
  }

  /// Indique si la source est fiable pour les calculs
  bool get isReliable {
    switch (this) {
      case ConversionSource.identity:
        return true;
      case ConversionSource.cache:
        return true;
      case ConversionSource.api:
        return true;
    }
  }
}