import 'package:bankapp/domain/entities/exchange_rate.dart';

/// Modèle Drift pour les taux de change
class ExchangeRateModel {
  /// Devise de départ
  final String fromCurrency;
  
  /// Devise d'arrivée
  final String toCurrency;
  
  /// Taux de change
  final double rate;
  
  /// Date de dernière mise à jour
  final DateTime lastUpdated;
  
  /// Date d'expiration
  final DateTime expiresAt;

  const ExchangeRateModel({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    required this.expiresAt,
  });

  /// Convertit vers l'entité domain
  ExchangeRate toEntity() {
    return ExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate,
      lastUpdated: lastUpdated,
      expiresAt: expiresAt,
    );
  }

  /// Crée depuis l'entité domain
  factory ExchangeRateModel.fromEntity(ExchangeRate entity) {
    return ExchangeRateModel(
      fromCurrency: entity.fromCurrency,
      toCurrency: entity.toCurrency,
      rate: entity.rate,
      lastUpdated: entity.lastUpdated,
      expiresAt: entity.expiresAt,
    );
  }

  /// Crée depuis une ligne de base de données
  factory ExchangeRateModel.fromDriftRow(Map<String, dynamic> row) {
    return ExchangeRateModel(
      fromCurrency: row['from_currency'] as String,
      toCurrency: row['to_currency'] as String,
      rate: row['rate'] as double,
      lastUpdated: row['last_updated'] as DateTime,
      expiresAt: row['expires_at'] as DateTime,
    );
  }

  /// Convertit vers un Map pour l'insertion
  Map<String, dynamic> toMap() {
    return {
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
      'rate': rate,
      'last_updated': lastUpdated,
      'expires_at': expiresAt,
    };
  }

  /// Crée depuis un Map
  factory ExchangeRateModel.fromMap(Map<String, dynamic> map) {
    return ExchangeRateModel(
      fromCurrency: map['from_currency'] as String,
      toCurrency: map['to_currency'] as String,
      rate: map['rate'] as double,
      lastUpdated: map['last_updated'] as DateTime,
      expiresAt: map['expires_at'] as DateTime,
    );
  }

  /// Vérifie si le taux est encore valide
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Vérifie si le taux est expiré
  bool get isExpired => !isValid;

  /// Obtient la paire de devises
  String get currencyPair => '${fromCurrency}_$toCurrency';

  /// Crée une copie avec de nouvelles valeurs
  ExchangeRateModel copyWith({
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    DateTime? lastUpdated,
    DateTime? expiresAt,
  }) {
    return ExchangeRateModel(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'ExchangeRateModel(fromCurrency: $fromCurrency, toCurrency: $toCurrency, rate: $rate, lastUpdated: $lastUpdated, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExchangeRateModel &&
        other.fromCurrency == fromCurrency &&
        other.toCurrency == toCurrency &&
        other.rate == rate &&
        other.lastUpdated == lastUpdated &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      fromCurrency,
      toCurrency,
      rate,
      lastUpdated,
      expiresAt,
    );
  }
}