import 'package:bankapp/core/services/currency_service.dart';
import 'package:bankapp/data/datasources/local/exchange_rate_local_datasource.dart';
import 'package:bankapp/data/datasources/remote/exchange_rate_remote_datasource.dart';
import 'package:bankapp/domain/entities/exchange_rate.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';

/// Implémentation du repository avec stratégie de cache à 3 niveaux
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateLocalDataSource _localDataSource;
  final ExchangeRateRemoteDataSource _remoteDataSource;

  ExchangeRateRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<List<ExchangeRate>> getExchangeRates(String baseCurrency) async {
    // Validation de la devise
    if (!CurrencyService.isValidCurrency(baseCurrency)) {
      throw UnsupportedCurrencyException('Currency $baseCurrency is not supported');
    }

    try {
      // 1. Essayer le cache local d'abord
      final cachedRates = await _localDataSource.getExchangeRates(baseCurrency);
      
      // Vérifier si les taux cachés sont encore valides
      final validCachedRates = cachedRates
          .where((rate) => rate.isValid)
          .toList();
      
      if (validCachedRates.isNotEmpty) {
        return validCachedRates.map((model) => model.toEntity()).toList();
      }
      
      // 2. Si pas de cache valide, récupérer depuis l'API
      final remoteRates = await _remoteDataSource.getExchangeRates(baseCurrency);
      
      // 3. Sauvegarder dans le cache local
      await _localDataSource.saveExchangeRates(remoteRates);
      
      return remoteRates.map((model) => model.toEntity()).toList();
      
    } catch (e) {
      // En cas d'erreur, essayer de récupérer même les taux expirés
      final expiredRates = await _localDataSource.getExchangeRates(baseCurrency);
      
      if (expiredRates.isNotEmpty) {
        // Utiliser les taux expirés comme fallback
        return expiredRates.map((model) => model.toEntity()).toList();
      }
      
      throw ExchangeRateUpdateException('Failed to get exchange rates: $e');
    }
  }

  @override
  Future<ExchangeRate?> getExchangeRate(String fromCurrency, String toCurrency) async {
    // Validation des devises
    if (!CurrencyService.isValidCurrency(fromCurrency)) {
      throw UnsupportedCurrencyException('Currency $fromCurrency is not supported');
    }
    if (!CurrencyService.isValidCurrency(toCurrency)) {
      throw UnsupportedCurrencyException('Currency $toCurrency is not supported');
    }

    // Cas spécial : même devise
    if (fromCurrency == toCurrency) {
      return ExchangeRate.withDefaultExpiration(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        rate: 1.0,
      );
    }

    try {
      // 1. Essayer le cache local
      final cachedRate = await _localDataSource.getExchangeRate(fromCurrency, toCurrency);
      
      if (cachedRate != null && cachedRate.isValid) {
        return cachedRate.toEntity();
      }
      
      // 2. Si pas de cache valide, récupérer depuis l'API
      final remoteRate = await _remoteDataSource.getExchangeRate(fromCurrency, toCurrency);
      
      // 3. Sauvegarder dans le cache
      await _localDataSource.saveExchangeRate(remoteRate);
      
      return remoteRate.toEntity();
      
    } catch (e) {
      // Fallback vers taux expiré si disponible
      final expiredRate = await _localDataSource.getExchangeRate(fromCurrency, toCurrency);
      
      if (expiredRate != null) {
        return expiredRate.toEntity();
      }
      
      return null;
    }
  }

  @override
  Future<double> convertAmount(
    double amount, 
    String fromCurrency, 
    String toCurrency,
  ) async {
    if (amount < 0) {
      throw CurrencyConversionException('Amount cannot be negative');
    }

    // Cas spécial : même devise
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final exchangeRate = await getExchangeRate(fromCurrency, toCurrency);
    
    if (exchangeRate == null) {
      throw CurrencyConversionException(
        'No exchange rate available for $fromCurrency to $toCurrency',
      );
    }

    try {
      return exchangeRate.convertAmount(amount);
    } catch (e) {
      throw CurrencyConversionException('Conversion failed: $e');
    }
  }

  @override
  Future<void> updateExchangeRates(String baseCurrency) async {
    if (!CurrencyService.isValidCurrency(baseCurrency)) {
      throw UnsupportedCurrencyException('Currency $baseCurrency is not supported');
    }

    try {
      // Récupérer les nouveaux taux depuis l'API
      final remoteRates = await _remoteDataSource.getExchangeRates(baseCurrency);
      
      // Sauvegarder dans le cache local
      await _localDataSource.saveExchangeRates(remoteRates);
      
    } catch (e) {
      throw ExchangeRateUpdateException('Failed to update exchange rates: $e');
    }
  }

  @override
  Future<bool> isExchangeRateAvailable(String fromCurrency, String toCurrency) async {
    if (!CurrencyService.isValidCurrency(fromCurrency) || 
        !CurrencyService.isValidCurrency(toCurrency)) {
      return false;
    }

    // Même devise = toujours disponible
    if (fromCurrency == toCurrency) {
      return true;
    }

    try {
      final rate = await getExchangeRate(fromCurrency, toCurrency);
      return rate != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getLastUpdateTime(String fromCurrency, String toCurrency) async {
    final cachedRate = await _localDataSource.getExchangeRate(fromCurrency, toCurrency);
    return cachedRate?.lastUpdated;
  }

  @override
  Future<List<ExchangeRate>> getAllValidRates() async {
    final validRates = await _localDataSource.getAllValidRates();
    return validRates.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> cleanupExpiredRates() async {
    await _localDataSource.deleteExpiredRates();
  }

  @override
  Future<List<String>> getAvailableBaseCurrencies() async {
    return await _localDataSource.getAvailableBaseCurrencies();
  }

  @override
  Future<List<String>> getTargetCurrencies(String baseCurrency) async {
    return await _localDataSource.getTargetCurrencies(baseCurrency);
  }

  @override
  Future<bool> isApiAvailable() async {
    return await _remoteDataSource.isApiAvailable();
  }

  @override
  Future<Map<String, int>> getCacheStatistics() async {
    return await _localDataSource.getStatistics();
  }

  /// Méthodes utilitaires pour la gestion du cache

  /// Force la mise à jour de tous les taux pour les devises principales
  Future<void> updateAllMajorCurrencies() async {
    final majorCurrencies = CurrencyService.getMajorCurrencyCodes();
    
    for (final currency in majorCurrencies) {
      try {
        await updateExchangeRates(currency);
      } catch (e) {
        // Continuer avec les autres devises en cas d'erreur
        continue;
      }
    }
  }

  /// Pré-charge les taux pour les devises courantes
  Future<void> preloadCommonExchangeRates() async {
    final commonPairs = [
      ('EUR', 'USD'),
      ('USD', 'EUR'),
      ('GBP', 'USD'),
      ('USD', 'GBP'),
      ('EUR', 'GBP'),
      ('GBP', 'EUR'),
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

  /// Convertit avec gestion d'erreur et fallback
  Future<double?> convertAmountSafe(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      return await convertAmount(amount, fromCurrency, toCurrency);
    } catch (e) {
      return null;
    }
  }

  /// Nettoie et optimise le cache
  Future<void> optimizeCache() async {
    // Supprimer les taux expirés
    await cleanupExpiredRates();
    
    // Pré-charger les taux courants
    await preloadCommonExchangeRates();
  }
}