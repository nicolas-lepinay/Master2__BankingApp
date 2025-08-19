import 'package:bankapp/domain/entities/exchange_rate.dart';

/// Interface du repository pour les taux de change
abstract class ExchangeRateRepository {
  /// Récupère tous les taux de change pour une devise de base
  Future<List<ExchangeRate>> getExchangeRates(String baseCurrency);
  
  /// Récupère un taux de change spécifique
  Future<ExchangeRate?> getExchangeRate(String fromCurrency, String toCurrency);
  
  /// Convertit un montant d'une devise à une autre
  Future<double> convertAmount(
    double amount, 
    String fromCurrency, 
    String toCurrency,
  );
  
  /// Met à jour les taux de change depuis l'API
  Future<void> updateExchangeRates(String baseCurrency);
  
  /// Vérifie si un taux de change est disponible et valide
  Future<bool> isExchangeRateAvailable(String fromCurrency, String toCurrency);
  
  /// Récupère la date de dernière mise à jour d'un taux
  Future<DateTime?> getLastUpdateTime(String fromCurrency, String toCurrency);
  
  /// Récupère tous les taux de change valides (non expirés)
  Future<List<ExchangeRate>> getAllValidRates();
  
  /// Nettoie les taux de change expirés
  Future<void> cleanupExpiredRates();
  
  /// Récupère les devises disponibles
  Future<List<String>> getAvailableBaseCurrencies();
  
  /// Récupère les devises cibles pour une devise de base
  Future<List<String>> getTargetCurrencies(String baseCurrency);
  
  /// Vérifie si l'API est disponible
  Future<bool> isApiAvailable();
  
  /// Récupère des statistiques sur le cache
  Future<Map<String, int>> getCacheStatistics();
}

/// Exceptions du repository
abstract class ExchangeRateRepositoryException implements Exception {
  final String message;
  
  const ExchangeRateRepositoryException(this.message);
  
  @override
  String toString() => '$runtimeType: $message';
}

/// Exception pour les erreurs de conversion
class CurrencyConversionException extends ExchangeRateRepositoryException {
  const CurrencyConversionException(super.message);
}

/// Exception pour les devises non supportées
class UnsupportedCurrencyException extends ExchangeRateRepositoryException {
  const UnsupportedCurrencyException(super.message);
}

/// Exception pour les taux de change expirés
class ExpiredExchangeRateException extends ExchangeRateRepositoryException {
  const ExpiredExchangeRateException(super.message);
}

/// Exception pour les erreurs de mise à jour
class ExchangeRateUpdateException extends ExchangeRateRepositoryException {
  const ExchangeRateUpdateException(super.message);
}