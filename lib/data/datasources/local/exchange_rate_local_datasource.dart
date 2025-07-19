import 'package:bankapp/core/utils/app_logger.dart';
import 'package:bankapp/data/database/app_database.dart';
import 'package:bankapp/data/models/exchange_rate_model.dart';
import 'package:drift/drift.dart';

/// Interface pour le DataSource local des taux de change
abstract class ExchangeRateLocalDataSource {
  /// Récupère tous les taux de change depuis une devise
  Future<List<ExchangeRateModel>> getExchangeRates(String fromCurrency);
  
  /// Récupère un taux de change spécifique
  Future<ExchangeRateModel?> getExchangeRate(String fromCurrency, String toCurrency);
  
  /// Sauvegarde une liste de taux de change
  Future<void> saveExchangeRates(List<ExchangeRateModel> rates);
  
  /// Sauvegarde un taux de change
  Future<void> saveExchangeRate(ExchangeRateModel rate);
  
  /// Supprime les taux de change expirés
  Future<void> deleteExpiredRates();
  
  /// Supprime tous les taux de change d'une devise
  Future<void> deleteExchangeRates(String fromCurrency);
  
  /// Supprime tous les taux de change
  Future<void> deleteAllExchangeRates();
  
  /// Récupère tous les taux de change valides
  Future<List<ExchangeRateModel>> getAllValidRates();
  
  /// Récupère tous les taux de change expirés
  Future<List<ExchangeRateModel>> getExpiredRates();
  
  /// Compte le nombre de taux de change
  Future<int> countExchangeRates();
  
  /// Récupère des statistiques sur le cache
  Future<Map<String, int>> getStatistics();
  
  /// Récupère les devises disponibles dans le cache
  Future<List<String>> getAvailableBaseCurrencies();
  
  /// Récupère les devises cibles pour une devise de base
  Future<List<String>> getTargetCurrencies(String fromCurrency);
}

/// Implémentation du DataSource local utilisant Drift
class ExchangeRateLocalDataSourceImpl with AppLoggerMixin implements ExchangeRateLocalDataSource {
  final AppDatabase _database;

  ExchangeRateLocalDataSourceImpl(this._database);

  @override
  Future<List<ExchangeRateModel>> getExchangeRates(String fromCurrency) async {
    final query = _database.select(_database.exchangeRates)
      ..where((tbl) => tbl.fromCurrency.equals(fromCurrency));
    
    final results = await query.get();
    final rates = results.map((row) => ExchangeRateModel(
      fromCurrency: row.fromCurrency,
      toCurrency: row.toCurrency,
      rate: row.rate,
      lastUpdated: row.lastUpdated,
      expiresAt: row.expiresAt,
    )).toList();
    
    if (rates.isNotEmpty) {
      final now = DateTime.now();
      final validRates = rates.where((r) => r.expiresAt.isAfter(now)).length;
      final avgAge = rates.map((r) => now.difference(r.lastUpdated).inHours).reduce((a, b) => a + b) / rates.length;
      
      logInfo('getExchangeRates', 'Found ${rates.length} rates for $fromCurrency ($validRates valid, avg age: ${avgAge.toStringAsFixed(1)}h)');
    } else {
      logCacheMiss('getExchangeRates', fromCurrency, 'ALL', reason: 'no rates found');
    }
    
    return rates;
  }

  @override
  Future<ExchangeRateModel?> getExchangeRate(String fromCurrency, String toCurrency) async {
    final query = _database.select(_database.exchangeRates)
      ..where((tbl) => 
          tbl.fromCurrency.equals(fromCurrency) & 
          tbl.toCurrency.equals(toCurrency));
    
    final result = await query.getSingleOrNull();
    
    if (result == null) {
      logCacheMiss('getExchangeRate', fromCurrency, toCurrency, reason: 'not found');
      return null;
    }
    
    final rate = ExchangeRateModel(
      fromCurrency: result.fromCurrency,
      toCurrency: result.toCurrency,
      rate: result.rate,
      lastUpdated: result.lastUpdated,
      expiresAt: result.expiresAt,
    );
    
    final now = DateTime.now();
    final ageHours = now.difference(rate.lastUpdated).inHours.toDouble();
    final isValid = rate.expiresAt.isAfter(now);
    
    if (isValid) {
      logCacheHit('getExchangeRate', fromCurrency, toCurrency, rate: rate.rate, age: ageHours);
    } else {
      logCacheMiss('getExchangeRate', fromCurrency, toCurrency, reason: 'expired');
    }
    
    return rate;
  }

  @override
  Future<void> saveExchangeRates(List<ExchangeRateModel> rates) async {
    if (rates.isEmpty) {
      logWarning('saveExchangeRates', 'No rates to save');
      return;
    }
    
    final baseCurrency = rates.first.fromCurrency;
    final expiresAt = rates.first.expiresAt;
    
    await _database.batch((batch) {
      for (final rate in rates) {
        batch.insert(
          _database.exchangeRates,
          ExchangeRatesCompanion.insert(
            fromCurrency: rate.fromCurrency,
            toCurrency: rate.toCurrency,
            rate: rate.rate,
            lastUpdated: rate.lastUpdated,
            expiresAt: rate.expiresAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    
    logCacheUpdate('saveExchangeRates', baseCurrency, rates.length, expires: expiresAt);
  }

  @override
  Future<void> saveExchangeRate(ExchangeRateModel rate) async {
    await _database.into(_database.exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        fromCurrency: rate.fromCurrency,
        toCurrency: rate.toCurrency,
        rate: rate.rate,
        lastUpdated: rate.lastUpdated,
        expiresAt: rate.expiresAt,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> deleteExpiredRates() async {
    final now = DateTime.now();
    
    final deletedCount = await (_database.delete(_database.exchangeRates)
      ..where((tbl) => tbl.expiresAt.isSmallerThanValue(now)))
      .go();
    
    if (deletedCount > 0) {
      logInfo('deleteExpiredRates', 'Deleted $deletedCount expired rates');
    }
  }

  @override
  Future<void> deleteExchangeRates(String fromCurrency) async {
    await (_database.delete(_database.exchangeRates)
      ..where((tbl) => tbl.fromCurrency.equals(fromCurrency)))
      .go();
  }

  @override
  Future<void> deleteAllExchangeRates() async {
    await _database.delete(_database.exchangeRates).go();
  }

  @override
  Future<List<ExchangeRateModel>> getAllValidRates() async {
    final now = DateTime.now();
    
    final query = _database.select(_database.exchangeRates)
      ..where((tbl) => tbl.expiresAt.isBiggerThanValue(now));
    
    final results = await query.get();
    
    return results.map((row) => ExchangeRateModel(
      fromCurrency: row.fromCurrency,
      toCurrency: row.toCurrency,
      rate: row.rate,
      lastUpdated: row.lastUpdated,
      expiresAt: row.expiresAt,
    )).toList();
  }

  @override
  Future<List<ExchangeRateModel>> getExpiredRates() async {
    final now = DateTime.now();
    
    final query = _database.select(_database.exchangeRates)
      ..where((tbl) => tbl.expiresAt.isSmallerThanValue(now));
    
    final results = await query.get();
    
    return results.map((row) => ExchangeRateModel(
      fromCurrency: row.fromCurrency,
      toCurrency: row.toCurrency,
      rate: row.rate,
      lastUpdated: row.lastUpdated,
      expiresAt: row.expiresAt,
    )).toList();
  }

  @override
  Future<int> countExchangeRates() async {
    final query = _database.selectOnly(_database.exchangeRates)
      ..addColumns([_database.exchangeRates.fromCurrency.count()]);
    
    final result = await query.getSingle();
    return result.read(_database.exchangeRates.fromCurrency.count()) ?? 0;
  }

  /// Nettoie automatiquement les taux expirés (appelé périodiquement)
  Future<void> cleanup() async {
    logInfo('cleanup', 'Starting cache cleanup');
    await deleteExpiredRates();
  }

  /// Récupère des statistiques sur le cache
  @override
  Future<Map<String, int>> getStatistics() async {
    final total = await countExchangeRates();
    final expired = (await getExpiredRates()).length;
    final valid = total - expired;
    
    return {
      'total': total,
      'valid': valid,
      'expired': expired,
    };
  }

  /// Récupère les devises disponibles dans le cache
  @override
  Future<List<String>> getAvailableBaseCurrencies() async {
    final query = _database.selectOnly(_database.exchangeRates, distinct: true)
      ..addColumns([_database.exchangeRates.fromCurrency]);
    
    final results = await query.get();
    
    return results
        .map((row) => row.read(_database.exchangeRates.fromCurrency)!)
        .toList();
  }

  /// Récupère les devises cibles pour une devise de base
  @override
  Future<List<String>> getTargetCurrencies(String fromCurrency) async {
    final query = _database.selectOnly(_database.exchangeRates)
      ..addColumns([_database.exchangeRates.toCurrency])
      ..where(_database.exchangeRates.fromCurrency.equals(fromCurrency));
    
    final results = await query.get();
    
    return results
        .map((row) => row.read(_database.exchangeRates.toCurrency)!)
        .toList();
  }
}