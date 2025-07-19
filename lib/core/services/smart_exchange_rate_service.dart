import 'dart:async';

import 'package:bankapp/core/services/currency_locale_service.dart';
import 'package:bankapp/data/cache/cache_manager.dart';
import 'package:bankapp/domain/repositories/exchange_rate_repository.dart';

/// Service intelligent pour la gestion des taux de change
/// Optimisé pour l'UX et l'efficacité réseau
class SmartExchangeRateService {
  final CacheManager _cacheManager;
  final ExchangeRateRepository _exchangeRateRepository;

  /// Timeout global pour éviter les blocages
  static const Duration _globalTimeout = Duration(seconds: 10);
  
  /// Timeout par devise individuelle  
  static const Duration _currencyTimeout = Duration(seconds: 8);
  
  /// Limite de devises à traiter en parallèle
  static const int _maxParallelCurrencies = 3;

  SmartExchangeRateService(
    this._cacheManager,
    this._exchangeRateRepository,
  );

  /// Analyse le cache et retourne les devises de base expirées
  Future<List<String>> getExpiredBaseCurrencies() async {
    try {
      // Récupérer tous les taux de change en cache
      final allRates = _cacheManager.getAllExchangeRates();
      
      if (allRates.isEmpty) {
        return [];
      }

      // Extraire les devises de base uniques
      final baseCurrencies = <String>{};
      final expiredBaseCurrencies = <String>{};

      for (final rate in allRates.values) {
        baseCurrencies.add(rate.fromCurrency);
        
        // Si au moins un taux de cette devise de base est expiré
        if (rate.isExpired) {
          expiredBaseCurrencies.add(rate.fromCurrency);
        }
      }

      return expiredBaseCurrencies.toList();
    } catch (e) {
      // En cas d'erreur, retourner liste vide
      return [];
    }
  }

  /// Met à jour les devises expirées avec stratégie de timeout intelligent
  Future<ExchangeRateUpdateResult> updateExpiredRatesWithTimeout() async {
    final startTime = DateTime.now();
    
    try {
      // Identifier les devises de base expirées
      final expiredCurrencies = await getExpiredBaseCurrencies();
      
      if (expiredCurrencies.isEmpty) {
        return ExchangeRateUpdateResult.success(
          updatedCurrencies: [],
          duration: DateTime.now().difference(startTime),
          strategy: UpdateStrategy.noneNeeded,
        );
      }

      // Limiter le nombre de devises à traiter
      final currenciesToUpdate = expiredCurrencies.take(_maxParallelCurrencies).toList();
      
      final results = <String, bool>{};
      bool firstFailure = false;

      // Traiter les devises avec timeout
      await Future.wait(
        currenciesToUpdate.map((currency) async {
          try {
            // Si premier échec déjà détecté, abandonner
            if (firstFailure) return;
            
            await _exchangeRateRepository
                .updateExchangeRates(currency)
                .timeout(_currencyTimeout);
            
            results[currency] = true;
          } catch (e) {
            results[currency] = false;
            firstFailure = true; // Marquer premier échec
          }
        }),
      ).timeout(_globalTimeout);

      final successful = results.values.where((success) => success).length;
      final duration = DateTime.now().difference(startTime);

      if (successful > 0) {
        return ExchangeRateUpdateResult.success(
          updatedCurrencies: results.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList(),
          duration: duration,
          strategy: UpdateStrategy.selective,
        );
      } else {
        return ExchangeRateUpdateResult.failure(
          error: 'All currency updates failed',
          duration: duration,
          strategy: UpdateStrategy.selective,
        );
      }

    } on TimeoutException {
      return ExchangeRateUpdateResult.failure(
        error: 'Update timeout after ${_globalTimeout.inSeconds}s',
        duration: DateTime.now().difference(startTime),
        strategy: UpdateStrategy.selective,
      );
    } catch (e) {
      return ExchangeRateUpdateResult.failure(
        error: 'Unexpected error: $e',
        duration: DateTime.now().difference(startTime),
        strategy: UpdateStrategy.selective,
      );
    }
  }

  /// S'assure qu'une devise spécifique est disponible et à jour
  Future<ExchangeRateUpdateResult> ensureCurrencyAvailable(String currency) async {
    final startTime = DateTime.now();
    
    try {
      // Vérifier si des taux existent déjà pour cette devise
      final existingRates = _cacheManager.getAllExchangeRates().values
          .where((rate) => rate.fromCurrency == currency.toUpperCase())
          .toList();

      // Si des taux existent et sont valides, pas besoin de mise à jour
      if (existingRates.isNotEmpty && existingRates.any((rate) => rate.isValid)) {
        return ExchangeRateUpdateResult.success(
          updatedCurrencies: [],
          duration: DateTime.now().difference(startTime),
          strategy: UpdateStrategy.noneNeeded,
        );
      }

      // Sinon, mettre à jour cette devise
      await _exchangeRateRepository
          .updateExchangeRates(currency.toUpperCase())
          .timeout(_currencyTimeout);

      return ExchangeRateUpdateResult.success(
        updatedCurrencies: [currency.toUpperCase()],
        duration: DateTime.now().difference(startTime),
        strategy: UpdateStrategy.single,
      );

    } on TimeoutException {
      return ExchangeRateUpdateResult.failure(
        error: 'Currency update timeout for $currency',
        duration: DateTime.now().difference(startTime),
        strategy: UpdateStrategy.single,
      );
    } catch (e) {
      return ExchangeRateUpdateResult.failure(
        error: 'Failed to update $currency: $e',
        duration: DateTime.now().difference(startTime),
        strategy: UpdateStrategy.single,
      );
    }
  }

  /// Détermine si le cache est vide (aucun taux de change)
  bool isCacheEmpty() {
    return _cacheManager.getAllExchangeRates().isEmpty;
  }

  /// Récupère la devise locale de l'utilisateur
  String getLocalCurrency() {
    return CurrencyLocaleService.getLocalCurrency();
  }

  /// Stratégie pour cache vide : charger devise locale
  Future<ExchangeRateUpdateResult> initializeEmptyCache() async {
    final localCurrency = getLocalCurrency();
    return await ensureCurrencyAvailable(localCurrency);
  }

  /// Récupère les statistiques du cache pour debug
  Map<String, dynamic> getCacheStatistics() {
    final allRates = _cacheManager.getAllExchangeRates();
    final validRates = allRates.values.where((rate) => rate.isValid).toList();
    final expiredRates = allRates.values.where((rate) => rate.isExpired).toList();
    
    final baseCurrencies = allRates.values
        .map((rate) => rate.fromCurrency)
        .toSet();

    return {
      'totalRates': allRates.length,
      'validRates': validRates.length,
      'expiredRates': expiredRates.length,
      'baseCurrencies': baseCurrencies.toList(),
      'lastUpdate': _cacheManager.lastExchangeRateUpdate?.toIso8601String(),
      'isEmpty': isCacheEmpty(),
      'localCurrency': getLocalCurrency(),
    };
  }
}

/// Résultat d'une opération de mise à jour des taux de change
class ExchangeRateUpdateResult {
  final bool success;
  final List<String> updatedCurrencies;
  final String? error;
  final Duration duration;
  final UpdateStrategy strategy;

  const ExchangeRateUpdateResult._({
    required this.success,
    required this.updatedCurrencies,
    this.error,
    required this.duration,
    required this.strategy,
  });

  factory ExchangeRateUpdateResult.success({
    required List<String> updatedCurrencies,
    required Duration duration,
    required UpdateStrategy strategy,
  }) {
    return ExchangeRateUpdateResult._(
      success: true,
      updatedCurrencies: updatedCurrencies,
      duration: duration,
      strategy: strategy,
    );
  }

  factory ExchangeRateUpdateResult.failure({
    required String error,
    required Duration duration,
    required UpdateStrategy strategy,
  }) {
    return ExchangeRateUpdateResult._(
      success: false,
      updatedCurrencies: [],
      error: error,
      duration: duration,
      strategy: strategy,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'ExchangeRateUpdateResult.success(${updatedCurrencies.length} currencies, ${duration.inMilliseconds}ms, $strategy)';
    } else {
      return 'ExchangeRateUpdateResult.failure($error, ${duration.inMilliseconds}ms, $strategy)';
    }
  }
}

/// Stratégie utilisée pour la mise à jour
enum UpdateStrategy {
  /// Aucune mise à jour nécessaire
  noneNeeded,
  /// Mise à jour sélective des devises expirées
  selective,
  /// Mise à jour d'une seule devise
  single,
}