import 'package:drift/drift.dart';

/// Table des taux de change pour le cache local
@DataClassName('ExchangeRateTable')
class ExchangeRates extends Table {
  /// Devise de départ (ex: 'EUR')
  TextColumn get fromCurrency => text().withLength(min: 3, max: 3)();
  
  /// Devise d'arrivée (ex: 'USD')
  TextColumn get toCurrency => text().withLength(min: 3, max: 3)();
  
  /// Taux de change (ex: 1.12)
  RealColumn get rate => real()();
  
  /// Date de dernière mise à jour
  DateTimeColumn get lastUpdated => dateTime()();
  
  /// Date d'expiration du taux
  DateTimeColumn get expiresAt => dateTime()();
  
  /// Clé primaire composée : from_currency + to_currency
  @override
  Set<Column> get primaryKey => {fromCurrency, toCurrency};
  
}