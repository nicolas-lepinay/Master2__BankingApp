import 'dart:ui';

/// Service pour détecter la devise locale de l'utilisateur
/// basé sur son pays (locale.countryCode)
class CurrencyLocaleService {
  // Mapping pays → devise principale
  static const Map<String, String> _countryToCurrency = {
    // Zone Euro
    'FR': 'EUR', // France
    'DE': 'EUR', // Allemagne  
    'IT': 'EUR', // Italie
    'ES': 'EUR', // Espagne
    'NL': 'EUR', // Pays-Bas
    'BE': 'EUR', // Belgique
    'AT': 'EUR', // Autriche
    'PT': 'EUR', // Portugal
    'IE': 'EUR', // Irlande
    'GR': 'EUR', // Grèce
    'FI': 'EUR', // Finlande
    'EE': 'EUR', // Estonie
    'LV': 'EUR', // Lettonie
    'LT': 'EUR', // Lituanie
    'SI': 'EUR', // Slovénie
    'SK': 'EUR', // Slovaquie
    'CY': 'EUR', // Chypre
    'MT': 'EUR', // Malte
    'LU': 'EUR', // Luxembourg
    
    // Devises Principales
    'US': 'USD', // États-Unis
    'GB': 'GBP', // Royaume-Uni
    'JP': 'JPY', // Japon
    'CA': 'CAD', // Canada
    'AU': 'AUD', // Australie
    'CH': 'CHF', // Suisse
    'CN': 'CNY', // Chine
    'HK': 'HKD', // Hong Kong
    'SG': 'SGD', // Singapour
    'KR': 'KRW', // Corée du Sud
    'IN': 'INR', // Inde
    
    // Autres Devises Importantes
    'SE': 'SEK', // Suède
    'NO': 'NOK', // Norvège
    'DK': 'DKK', // Danemark
    'PL': 'PLN', // Pologne
    'CZ': 'CZK', // République Tchèque
    'HU': 'HUF', // Hongrie
    'TR': 'TRY', // Turquie
    'RU': 'RUB', // Russie
    'MX': 'MXN', // Mexique
    'BR': 'BRL', // Brésil
    'CL': 'CLP', // Chili
    'NZ': 'NZD', // Nouvelle-Zélande
    'ZA': 'ZAR', // Afrique du Sud
    'IL': 'ILS', // Israël
    'AE': 'AED', // Émirats Arabes Unis
    'SA': 'SAR', // Arabie Saoudite
    'TW': 'TWD', // Taïwan
    'TH': 'THB', // Thaïlande
    'ID': 'IDR', // Indonésie
    'PH': 'PHP', // Philippines
  };

  /// Fallback par défaut si pays non supporté
  static const String _defaultCurrency = 'USD';

  /// Récupère la devise locale de l'utilisateur
  /// basée sur le code pays de sa locale système
  static String getLocalCurrency() {
    try {
      // Récupérer la locale système de l'utilisateur
      final locale = PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;
      
      // Si pas de code pays, utiliser fallback
      if (countryCode == null || countryCode.isEmpty) {
        return _defaultCurrency;
      }
      
      // Mapper le code pays vers la devise
      return _countryToCurrency[countryCode.toUpperCase()] ?? _defaultCurrency;
      
    } catch (e) {
      // En cas d'erreur, retourner fallback
      return _defaultCurrency;
    }
  }

  /// Récupère le code pays de l'utilisateur
  static String? getCountryCode() {
    try {
      return PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une devise est supportée pour détection locale
  static bool isSupportedCountry(String countryCode) {
    return _countryToCurrency.containsKey(countryCode.toUpperCase());
  }

  /// Récupère toutes les devises supportées
  static Set<String> getSupportedCurrencies() {
    return _countryToCurrency.values.toSet();
  }

  /// Récupère tous les pays supportés pour une devise
  static List<String> getCountriesForCurrency(String currency) {
    return _countryToCurrency.entries
        .where((entry) => entry.value == currency.toUpperCase())
        .map((entry) => entry.key)
        .toList();
  }

  /// Informations de debug sur la détection locale
  static Map<String, dynamic> getDebugInfo() {
    final locale = PlatformDispatcher.instance.locale;
    return {
      'locale': locale.toString(),
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
      'detectedCurrency': getLocalCurrency(),
      'supportedCountriesCount': _countryToCurrency.length,
      'supportedCurrenciesCount': getSupportedCurrencies().length,
    };
  }
}