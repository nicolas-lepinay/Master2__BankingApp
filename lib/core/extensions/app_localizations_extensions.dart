import 'package:bankapp/core/l10n/app_localizations.dart';

/// Extension pour AppLocalizations permettant l'accès dynamique aux traductions
extension AppLocalizationsExtensions on AppLocalizations {
  /// Obtient une traduction dynamiquement à partir d'une clé
  /// 
  /// Utilise un mapping pour associer les clés aux méthodes de localisation
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final currencyName = l10n.getTranslation('euroCurrencyName');
  /// ```
  String getTranslation(String key) {
    switch (key) {
      // Devises principales
      case 'euroCurrencyName':
        return euroCurrencyName;
      case 'euroCountryName':
        return euroCountryName;
      case 'usdCurrencyName':
        return usdCurrencyName;
      case 'usdCountryName':
        return usdCountryName;
      case 'gbpCurrencyName':
        return gbpCurrencyName;
      case 'gbpCountryName':
        return gbpCountryName;
      case 'jpyCurrencyName':
        return jpyCurrencyName;
      case 'jpyCountryName':
        return jpyCountryName;
      case 'cadCurrencyName':
        return cadCurrencyName;
      case 'cadCountryName':
        return cadCountryName;
      case 'audCurrencyName':
        return audCurrencyName;
      case 'audCountryName':
        return audCountryName;
      case 'chfCurrencyName':
        return chfCurrencyName;
      case 'chfCountryName':
        return chfCountryName;
      case 'cnyCurrencyName':
        return cnyCurrencyName;
      case 'cnyCountryName':
        return cnyCountryName;
      
      // Devises asiatiques
      case 'hkdCurrencyName':
        return hkdCurrencyName;
      case 'hkdCountryName':
        return hkdCountryName;
      case 'sgdCurrencyName':
        return sgdCurrencyName;
      case 'sgdCountryName':
        return sgdCountryName;
      case 'krwCurrencyName':
        return krwCurrencyName;
      case 'krwCountryName':
        return krwCountryName;
      case 'inrCurrencyName':
        return inrCurrencyName;
      case 'inrCountryName':
        return inrCountryName;
      case 'twdCurrencyName':
        return twdCurrencyName;
      case 'twdCountryName':
        return twdCountryName;
      case 'thbCurrencyName':
        return thbCurrencyName;
      case 'thbCountryName':
        return thbCountryName;
      case 'idrCurrencyName':
        return idrCurrencyName;
      case 'idrCountryName':
        return idrCountryName;
      case 'phpCurrencyName':
        return phpCurrencyName;
      case 'phpCountryName':
        return phpCountryName;
      case 'myrCurrencyName':
        return myrCurrencyName;
      case 'myrCountryName':
        return myrCountryName;
      
      // Devises européennes
      case 'sekCurrencyName':
        return sekCurrencyName;
      case 'sekCountryName':
        return sekCountryName;
      case 'nokCurrencyName':
        return nokCurrencyName;
      case 'nokCountryName':
        return nokCountryName;
      case 'dkkCurrencyName':
        return dkkCurrencyName;
      case 'dkkCountryName':
        return dkkCountryName;
      case 'plnCurrencyName':
        return plnCurrencyName;
      case 'plnCountryName':
        return plnCountryName;
      case 'czkCurrencyName':
        return czkCurrencyName;
      case 'czkCountryName':
        return czkCountryName;
      case 'hufCurrencyName':
        return hufCurrencyName;
      case 'hufCountryName':
        return hufCountryName;
      case 'ronCurrencyName':
        return ronCurrencyName;
      case 'ronCountryName':
        return ronCountryName;
      case 'tryCurrencyName':
        return tryCurrencyName;
      case 'tryCountryName':
        return tryCountryName;
      case 'rubCurrencyName':
        return rubCurrencyName;
      case 'rubCountryName':
        return rubCountryName;
      
      // Devises des Amériques
      case 'mxnCurrencyName':
        return mxnCurrencyName;
      case 'mxnCountryName':
        return mxnCountryName;
      case 'brlCurrencyName':
        return brlCurrencyName;
      case 'brlCountryName':
        return brlCountryName;
      case 'clpCurrencyName':
        return clpCurrencyName;
      case 'clpCountryName':
        return clpCountryName;
      case 'copCurrencyName':
        return copCurrencyName;
      case 'copCountryName':
        return copCountryName;
      case 'penCurrencyName':
        return penCurrencyName;
      case 'penCountryName':
        return penCountryName;
      
      // Devises du Moyen-Orient et Afrique/Océanie
      case 'nzdCurrencyName':
        return nzdCurrencyName;
      case 'nzdCountryName':
        return nzdCountryName;
      case 'zarCurrencyName':
        return zarCurrencyName;
      case 'zarCountryName':
        return zarCountryName;
      case 'ilsCurrencyName':
        return ilsCurrencyName;
      case 'ilsCountryName':
        return ilsCountryName;
      case 'aedCurrencyName':
        return aedCurrencyName;
      case 'aedCountryName':
        return aedCountryName;
      case 'sarCurrencyName':
        return sarCurrencyName;
      case 'sarCountryName':
        return sarCountryName;
      
      // Catégories par défaut
      case 'expenses':
        return expenses;
      case 'incomes':
        return incomes;
      case 'fixedExpenses':
        return fixedExpenses;
      case 'variableExpenses':
        return variableExpenses;
      case 'fixedIncomes':
        return fixedIncomes;
      case 'variableIncomes':
        return variableIncomes;
      
      // Fallback pour les clés non trouvées
      default:
        return key; // Retourne la clé elle-même si aucune traduction n'est trouvée
    }
  }

  /// Obtient une traduction de devise dynamiquement
  /// 
  /// Méthode de commodité spécifique pour les devises
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final currencyName = l10n.getCurrencyTranslation('EUR', 'name');
  /// final countryName = l10n.getCurrencyTranslation('EUR', 'country');
  /// ```
  String getCurrencyTranslation(String currencyCode, String type) {
    final lowerCode = currencyCode.toLowerCase();
    final key = '${lowerCode}Currency${type.toLowerCase() == 'name' ? 'Name' : 'CountryName'}';
    return getTranslation(key);
  }

  /// Obtient le nom d'une devise à partir de son code
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final name = l10n.getCurrencyName('EUR'); // Retourne "Euro"
  /// ```
  String getCurrencyName(String currencyCode) {
    return getCurrencyTranslation(currencyCode, 'name');
  }

  /// Obtient le nom du pays d'une devise à partir de son code
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final country = l10n.getCurrencyCountry('EUR'); // Retourne "Union Européenne"
  /// ```
  String getCurrencyCountry(String currencyCode) {
    return getCurrencyTranslation(currencyCode, 'country');
  }

  /// Obtient l'affichage complet d'une devise "Code - Nom (Pays)"
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final display = l10n.getCurrencyFullDisplay('EUR'); // Retourne "EUR - Euro (Union Européenne)"
  /// ```
  String getCurrencyFullDisplay(String currencyCode) {
    final name = getCurrencyName(currencyCode);
    final country = getCurrencyCountry(currencyCode);
    return '$currencyCode - $name ($country)';
  }

  /// Obtient le nom d'une catégorie par défaut à partir de sa clé
  /// 
  /// Exemple d'utilisation :
  /// ```dart
  /// final l10n = AppLocalizations.of(context)!;
  /// final name = l10n.getCategoryName('expenses'); // Retourne "Dépenses"
  /// ```
  String getCategoryName(String categoryKey) {
    return getTranslation(categoryKey);
  }
}