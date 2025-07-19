import 'package:equatable/equatable.dart';

/// Exception levée quand un taux de change est expiré
class ExchangeRateExpiredException implements Exception {
  final String message;
  
  const ExchangeRateExpiredException(this.message);
  
  @override
  String toString() => 'ExchangeRateExpiredException: $message';
}

/// Entité représentant un taux de change entre deux devises
class ExchangeRate extends Equatable {
  /// Devise de départ (ex: 'EUR')
  final String fromCurrency;
  
  /// Devise d'arrivée (ex: 'USD')
  final String toCurrency;
  
  /// Taux de change (ex: 1.12 pour EUR->USD)
  final double rate;
  
  /// Date de dernière mise à jour du taux
  final DateTime lastUpdated;
  
  /// Date d'expiration du taux (après laquelle il faut le renouveler)
  final DateTime expiresAt;

  ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    required this.expiresAt,
  }) {
    if (rate <= 0) {
      throw ArgumentError('Exchange rate must be positive, got: $rate');
    }
  }

  /// Vérifie si le taux de change est encore valide
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Vérifie si le taux de change est expiré
  bool get isExpired => !isValid;

  /// Durée avant expiration
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  /// Âge du taux de change
  Duration get age => DateTime.now().difference(lastUpdated);

  /// Convertit un montant en utilisant ce taux de change
  double convertAmount(double amount) {
    if (isExpired) {
      throw ExchangeRateExpiredException(
        'Exchange rate from $fromCurrency to $toCurrency has expired',
      );
    }
    // Calculer la conversion avec arrondi précis pour éviter les erreurs de précision flottante
    final result = amount * rate;
    // Arrondir à 4 décimales pour préserver la précision tout en éliminant les erreurs de flottant
    return (result * 10000).round() / 10000;
  }

  /// Crée un nouveau taux de change avec une nouvelle date d'expiration
  ExchangeRate copyWith({
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    DateTime? lastUpdated,
    DateTime? expiresAt,
  }) {
    return ExchangeRate(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Crée un ExchangeRate avec expiration dans 6 heures (défaut)
  factory ExchangeRate.withDefaultExpiration({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    DateTime? lastUpdated,
  }) {
    final now = lastUpdated ?? DateTime.now();
    return ExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate,
      lastUpdated: now,
      expiresAt: now.add(const Duration(hours: 6)),
    );
  }

  /// Crée un ExchangeRate avec expiration personnalisée
  factory ExchangeRate.withCustomExpiration({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required Duration expirationDuration,
    DateTime? lastUpdated,
  }) {
    final now = lastUpdated ?? DateTime.now();
    return ExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate,
      lastUpdated: now,
      expiresAt: now.add(expirationDuration),
    );
  }

  /// Obtient la paire de devises sous forme de chaîne
  String get currencyPair => '${fromCurrency}_$toCurrency';

  /// Obtient le taux de change inverse (toCurrency vers fromCurrency)
  ExchangeRate get inverse {
    return ExchangeRate(
      fromCurrency: toCurrency,
      toCurrency: fromCurrency,
      rate: 1.0 / rate,
      lastUpdated: lastUpdated,
      expiresAt: expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        fromCurrency,
        toCurrency,
        rate,
        lastUpdated,
        expiresAt,
      ];

  @override
  bool get stringify => true;
}

/// Exception levée quand un taux de change n'est pas trouvé
class ExchangeRateNotFoundException implements Exception {
  final String message;
  
  const ExchangeRateNotFoundException(this.message);
  
  @override
  String toString() => 'ExchangeRateNotFoundException: $message';
}