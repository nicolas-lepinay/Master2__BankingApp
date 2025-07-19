import 'package:bankapp/core/constants/supported_currencies.dart';
import 'package:bankapp/domain/entities/currency.dart';

/// Exception levée quand une devise n'est pas trouvée
class CurrencyNotFoundException implements Exception {
  final String message;
  
  const CurrencyNotFoundException(this.message);
  
  @override
  String toString() => 'CurrencyNotFoundException: $message';
}

/// Service statique pour la gestion des devises
class CurrencyService {
  /// Map des devises pour accès O(1) par code
  static final Map<String, Currency> _currencyMap = {
    for (final currency in SupportedCurrencies.all) currency.code: currency,
  };

  /// Obtient une devise par son code
  /// Retourne null si la devise n'est pas supportée
  static Currency? getCurrency(String code) {
    return _currencyMap[code];
  }

  /// Obtient une devise par son code (lance une exception si non trouvée)
  static Currency getCurrencyOrThrow(String code) {
    final currency = getCurrency(code);
    if (currency == null) {
      throw CurrencyNotFoundException('Currency $code is not supported');
    }
    return currency;
  }

  /// Vérifie si une devise est supportée
  static bool isValidCurrency(String code) {
    return _currencyMap.containsKey(code);
  }

  /// Obtient toutes les devises supportées
  static List<Currency> getAllCurrencies() {
    return SupportedCurrencies.all;
  }

  /// Obtient les devises actives uniquement
  static List<Currency> getActiveCurrencies() {
    return SupportedCurrencies.activeCurrencies;
  }

  /// Obtient les devises principales
  static List<Currency> getMajorCurrencies() {
    return SupportedCurrencies.major;
  }

  /// Obtient les devises secondaires
  static List<Currency> getMinorCurrencies() {
    return SupportedCurrencies.minor;
  }

  /// Obtient tous les codes de devises
  static List<String> getAllCurrencyCodes() {
    return SupportedCurrencies.allCodes;
  }

  /// Obtient les codes des devises actives
  static List<String> getActiveCurrencyCodes() {
    return SupportedCurrencies.activeCodes;
  }

  /// Obtient les codes des devises principales
  static List<String> getMajorCurrencyCodes() {
    return SupportedCurrencies.majorCodes;
  }

  /// Obtient les codes des devises secondaires
  static List<String> getMinorCurrencyCodes() {
    return SupportedCurrencies.minorCodes;
  }

  /// Obtient le symbole d'une devise
  static String? getCurrencySymbol(String code) {
    return getCurrency(code)?.symbol;
  }

  /// Obtient le nombre de décimales d'une devise
  static int getCurrencyDecimalPlaces(String code) {
    return getCurrency(code)?.decimalPlaces ?? 2;
  }

  /// Formate un montant avec la devise
  static String formatAmount(double amount, String currencyCode) {
    final currency = getCurrency(currencyCode);
    if (currency == null) {
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
    return currency.formatAmount(amount);
  }

  /// Formate un montant avec le code de devise
  static String formatAmountWithCode(double amount, String currencyCode) {
    final currency = getCurrency(currencyCode);
    if (currency == null) {
      return '${amount.toStringAsFixed(2)} $currencyCode';
    }
    return currency.formatAmountWithCode(amount);
  }

  /// Valide une liste de codes de devises
  static List<String> validateCurrencies(List<String> codes) {
    final invalidCodes = <String>[];
    for (final code in codes) {
      if (!isValidCurrency(code)) {
        invalidCodes.add(code);
      }
    }
    return invalidCodes;
  }

  /// Filtre les devises par critères
  static List<Currency> filterCurrencies({
    bool? isActive,
    bool? isMajor,
    List<String>? excludeCodes,
    List<String>? includeCodes,
  }) {
    var currencies = getAllCurrencies();

    if (isActive != null) {
      currencies = currencies.where((c) => c.isActive == isActive).toList();
    }

    if (isMajor != null) {
      final majorCodes = getMajorCurrencyCodes().toSet();
      currencies = currencies.where((c) => majorCodes.contains(c.code) == isMajor).toList();
    }

    if (excludeCodes != null && excludeCodes.isNotEmpty) {
      final excludeSet = excludeCodes.toSet();
      currencies = currencies.where((c) => !excludeSet.contains(c.code)).toList();
    }

    if (includeCodes != null && includeCodes.isNotEmpty) {
      final includeSet = includeCodes.toSet();
      currencies = currencies.where((c) => includeSet.contains(c.code)).toList();
    }

    return currencies;
  }

  /// Trie les devises par nom
  static List<Currency> sortCurrenciesByName(List<Currency> currencies) {
    return List.from(currencies)..sort((a, b) => a.code.compareTo(b.code));
  }

  /// Constantes pour les devises courantes
  static const Currency eur = SupportedCurrencies.eur;
  static const Currency usd = SupportedCurrencies.usd;
  static const Currency gbp = SupportedCurrencies.gbp;
  static const Currency jpy = SupportedCurrencies.jpy;
  static const Currency cad = SupportedCurrencies.cad;
  static const Currency aud = SupportedCurrencies.aud;
  static const Currency chf = SupportedCurrencies.chf;
  static const Currency cny = SupportedCurrencies.cny;
}


/// Exception levée quand une validation de devise échoue
class CurrencyValidationException implements Exception {
  final String message;
  final List<String> invalidCodes;
  
  const CurrencyValidationException(this.message, this.invalidCodes);
  
  @override
  String toString() => 'CurrencyValidationException: $message. Invalid codes: ${invalidCodes.join(", ")}';
}