import 'package:bankapp/domain/entities/currency.dart';

/// Liste des devises supportées par l'application
class SupportedCurrencies {
  /// Toutes les devises supportées (36 devises)
  static const List<Currency> all = [
    // Devises principales (G7 + principales économies)
    _usd, _eur, _jpy, _gbp, _cny, _aud, _cad, _chf,

    // Devises asiatiques
    _hkd, _sgd, _krw, _inr, _twd, _thb, _idr, _php,

    // Devises européennes
    _sek, _nok, _dkk, _pln, _czk, _huf, _try,

    // Devises des Amériques
    _mxn, _brl, _clp,

    // Devises du Moyen-Orient et Afrique
    _nzd, _zar, _ils, _aed, _sar,

    // Devise européenne (Russie)
    _rub,
  ];

  /// Devises principales (les plus utilisées dans le commerce international)
  static const List<Currency> major = [
    _usd,
    _eur,
    _jpy,
    _gbp,
    _cny,
    _aud,
    _cad,
    _chf,
  ];

  /// Devises asiatiques
  static const List<Currency> asian = [
    _hkd,
    _sgd,
    _krw,
    _inr,
    _twd,
    _thb,
    _idr,
    _php,
  ];

  /// Devises européennes (hors majeures)
  static const List<Currency> european = [
    _sek,
    _nok,
    _dkk,
    _pln,
    _czk,
    _huf,
    _try,
    _rub,
  ];

  /// Devises des Amériques (hors majeures)
  static const List<Currency> americas = [_mxn, _brl, _clp];

  /// Devises du Moyen-Orient et Afrique/Océanie
  static const List<Currency> meaOceania = [_nzd, _zar, _ils, _aed, _sar];

  /// Devises secondaires (toutes sauf les principales)
  static const List<Currency> minor = [
    // Devises asiatiques
    _hkd, _sgd, _krw, _inr, _twd, _thb, _idr, _php,
    // Devises européennes
    _sek, _nok, _dkk, _pln, _czk, _huf, _try, _rub,
    // Devises des Amériques
    _mxn, _brl, _clp,
    // Devises du Moyen-Orient et Afrique/Océanie
    _nzd, _zar, _ils, _aed, _sar,
  ];

  // ==================== DÉFINITIONS DES DEVISES ====================

  // DEVISES PRINCIPALES

  /// Dollar Américain (États-Unis)
  static const Currency _usd = Currency(
    code: 'USD',
    symbol: '\$',
    nameKey: 'usdCurrencyName',
    countryKey: 'usdCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇺🇸',
  );

  /// Euro (Zone Euro)
  static const Currency _eur = Currency(
    code: 'EUR',
    symbol: '€',
    nameKey: 'euroCurrencyName',
    countryKey: 'euroCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇪🇺',
  );

  /// Yen Japonais (Japon)
  static const Currency _jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    nameKey: 'jpyCurrencyName',
    countryKey: 'jpyCountryName',
    decimalPlaces: 0, // Le yen n'a pas de décimales
    flagEmoji: '🇯🇵',
  );

  /// Livre Sterling (Royaume-Uni)
  static const Currency _gbp = Currency(
    code: 'GBP',
    symbol: '£',
    nameKey: 'gbpCurrencyName',
    countryKey: 'gbpCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇬🇧',
  );

  /// Renminbi/Yuan Chinois (Chine)
  static const Currency _cny = Currency(
    code: 'CNY',
    symbol: '¥',
    nameKey: 'cnyCurrencyName',
    countryKey: 'cnyCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇨🇳',
  );

  /// Dollar Australien (Australie)
  static const Currency _aud = Currency(
    code: 'AUD',
    symbol: '\$',
    nameKey: 'audCurrencyName',
    countryKey: 'audCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇦🇺',
  );

  /// Dollar Canadien (Canada)
  static const Currency _cad = Currency(
    code: 'CAD',
    symbol: '\$',
    nameKey: 'cadCurrencyName',
    countryKey: 'cadCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇨🇦',
  );

  /// Franc Suisse (Suisse)
  static const Currency _chf = Currency(
    code: 'CHF',
    symbol: 'CHF',
    nameKey: 'chfCurrencyName',
    countryKey: 'chfCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇨🇭',
  );

  // DEVISES ASIATIQUES

  /// Dollar de Hong Kong (Hong Kong)
  static const Currency _hkd = Currency(
    code: 'HKD',
    symbol: '\$',
    nameKey: 'hkdCurrencyName',
    countryKey: 'hkdCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇭🇰',
  );

  /// Dollar de Singapour (Singapour)
  static const Currency _sgd = Currency(
    code: 'SGD',
    symbol: 'S\$',
    nameKey: 'sgdCurrencyName',
    countryKey: 'sgdCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇸🇬',
  );

  /// Won Sud-Coréen (Corée du Sud)
  static const Currency _krw = Currency(
    code: 'KRW',
    symbol: '₩',
    nameKey: 'krwCurrencyName',
    countryKey: 'krwCountryName',
    decimalPlaces: 0, // Le won n'a pas de décimales
    flagEmoji: '🇰🇷',
  );

  /// Roupie Indienne (Inde)
  static const Currency _inr = Currency(
    code: 'INR',
    symbol: '₹',
    nameKey: 'inrCurrencyName',
    countryKey: 'inrCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇮🇳',
  );

  /// Nouveau Dollar de Taïwan (Taïwan)
  static const Currency _twd = Currency(
    code: 'TWD',
    symbol: 'NT\$',
    nameKey: 'twdCurrencyName',
    countryKey: 'twdCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇹🇼',
  );

  /// Baht Thaïlandais (Thaïlande)
  static const Currency _thb = Currency(
    code: 'THB',
    symbol: '฿',
    nameKey: 'thbCurrencyName',
    countryKey: 'thbCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇹🇭',
  );

  /// Rupiah Indonésienne (Indonésie)
  static const Currency _idr = Currency(
    code: 'IDR',
    symbol: 'Rp',
    nameKey: 'idrCurrencyName',
    countryKey: 'idrCountryName',
    decimalPlaces: 0, // La rupiah n'a pas de décimales
    flagEmoji: '🇮🇩',
  );

  /// Peso Philippin (Philippines)
  static const Currency _php = Currency(
    code: 'PHP',
    symbol: '₱',
    nameKey: 'phpCurrencyName',
    countryKey: 'phpCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇵🇭',
  );

  /// Ringgit Malaisien (Malaisie)
  /*
  static const Currency _myr = Currency(
    code: 'MYR',
    symbol: 'RM',
    nameKey: 'myrCurrencyName',
    countryKey: 'myrCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇲🇾',
  );
*/
  // DEVISES EUROPÉENNES

  /// Couronne Suédoise (Suède)
  static const Currency _sek = Currency(
    code: 'SEK',
    symbol: 'kr',
    nameKey: 'sekCurrencyName',
    countryKey: 'sekCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇸🇪',
  );

  /// Couronne Norvégienne (Norvège)
  static const Currency _nok = Currency(
    code: 'NOK',
    symbol: 'kr',
    nameKey: 'nokCurrencyName',
    countryKey: 'nokCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇳🇴',
  );

  /// Couronne Danoise (Danemark)
  static const Currency _dkk = Currency(
    code: 'DKK',
    symbol: 'kr',
    nameKey: 'dkkCurrencyName',
    countryKey: 'dkkCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇩🇰',
  );

  /// Złoty Polonais (Pologne)
  static const Currency _pln = Currency(
    code: 'PLN',
    symbol: 'zł',
    nameKey: 'plnCurrencyName',
    countryKey: 'plnCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇵🇱',
  );

  /// Couronne Tchèque (République Tchèque)
  static const Currency _czk = Currency(
    code: 'CZK',
    symbol: 'Kč',
    nameKey: 'czkCurrencyName',
    countryKey: 'czkCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇨🇿',
  );

  /// Forint Hongrois (Hongrie)
  static const Currency _huf = Currency(
    code: 'HUF',
    symbol: 'Ft',
    nameKey: 'hufCurrencyName',
    countryKey: 'hufCountryName',
    decimalPlaces: 0, // Le forint n'a pas de décimales
    flagEmoji: '🇭🇺',
  );

  /// Leu Roumain (Roumanie)
  /*
  static const Currency _ron = Currency(
    code: 'RON',
    symbol: 'lei',
    nameKey: 'ronCurrencyName',
    countryKey: 'ronCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇷🇴',
  );
*/

  /// Livre Turque (Turquie)
  static const Currency _try = Currency(
    code: 'TRY',
    symbol: '₺',
    nameKey: 'tryCurrencyName',
    countryKey: 'tryCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇹🇷',
  );

  /// Rouble Russe (Russie)
  static const Currency _rub = Currency(
    code: 'RUB',
    symbol: '₽',
    nameKey: 'rubCurrencyName',
    countryKey: 'rubCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇷🇺',
  );

  // DEVISES DES AMÉRIQUES

  /// Peso Mexicain (Mexique)
  static const Currency _mxn = Currency(
    code: 'MXN',
    symbol: '\$',
    nameKey: 'mxnCurrencyName',
    countryKey: 'mxnCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇲🇽',
  );

  /// Réal Brésilien (Brésil)
  static const Currency _brl = Currency(
    code: 'BRL',
    symbol: 'R\$',
    nameKey: 'brlCurrencyName',
    countryKey: 'brlCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇧🇷',
  );

  /// Peso Chilien (Chili)
  static const Currency _clp = Currency(
    code: 'CLP',
    symbol: '\$',
    nameKey: 'clpCurrencyName',
    countryKey: 'clpCountryName',
    decimalPlaces: 0, // Le peso chilien n'a pas de décimales
    flagEmoji: '🇨🇱',
  );

  /// Peso Colombien (Colombie)
  /*
  static const Currency _cop = Currency(
    code: 'COP',
    symbol: '\$',
    nameKey: 'copCurrencyName',
    countryKey: 'copCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇨🇴',
  );
*/

  /// Sol Péruvien (Pérou)
  /*
  static const Currency _pen = Currency(
    code: 'PEN',
    symbol: 'S/',
    nameKey: 'penCurrencyName',
    countryKey: 'penCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇵🇪',
  );
  */

  // DEVISES DU MOYEN-ORIENT ET AFRIQUE/OCÉANIE

  /// Dollar Néo-Zélandais (Nouvelle-Zélande)
  static const Currency _nzd = Currency(
    code: 'NZD',
    symbol: '\$',
    nameKey: 'nzdCurrencyName',
    countryKey: 'nzdCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇳🇿',
  );

  /// Rand Sud-Africain (Afrique du Sud)
  static const Currency _zar = Currency(
    code: 'ZAR',
    symbol: 'R',
    nameKey: 'zarCurrencyName',
    countryKey: 'zarCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇿🇦',
  );

  /// Nouveau Shekel Israélien (Israël)
  static const Currency _ils = Currency(
    code: 'ILS',
    symbol: '₪',
    nameKey: 'ilsCurrencyName',
    countryKey: 'ilsCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇮🇱',
  );

  /// Dirham des Émirats Arabes Unis (EAU)
  static const Currency _aed = Currency(
    code: 'AED',
    symbol: 'د.إ',
    nameKey: 'aedCurrencyName',
    countryKey: 'aedCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇦🇪',
  );

  /// Riyal Saoudien (Arabie Saoudite)
  static const Currency _sar = Currency(
    code: 'SAR',
    symbol: '﷼',
    nameKey: 'sarCurrencyName',
    countryKey: 'sarCountryName',
    decimalPlaces: 2,
    flagEmoji: '🇸🇦',
  );

  // ==================== ACCÈS DIRECT AUX DEVISES ====================

  // Devises principales
  static const Currency usd = _usd;
  static const Currency eur = _eur;
  static const Currency jpy = _jpy;
  static const Currency gbp = _gbp;
  static const Currency cny = _cny;
  static const Currency aud = _aud;
  static const Currency cad = _cad;
  static const Currency chf = _chf;

  // Devises asiatiques
  static const Currency hkd = _hkd;
  static const Currency sgd = _sgd;
  static const Currency krw = _krw;
  static const Currency inr = _inr;
  static const Currency twd = _twd;
  static const Currency thb = _thb;
  static const Currency idr = _idr;
  static const Currency php = _php;
  //static const Currency myr = _myr;

  // Devises européennes
  static const Currency sek = _sek;
  static const Currency nok = _nok;
  static const Currency dkk = _dkk;
  static const Currency pln = _pln;
  static const Currency czk = _czk;
  static const Currency huf = _huf;
  //static const Currency ron = _ron;
  static const Currency tryLira = _try;
  static const Currency rub = _rub;

  // Devises des Amériques
  static const Currency mxn = _mxn;
  static const Currency brl = _brl;
  static const Currency clp = _clp;
  //static const Currency cop = _cop;
  //static const Currency pen = _pen;

  // Devises du Moyen-Orient et Afrique/Océanie
  static const Currency nzd = _nzd;
  static const Currency zar = _zar;
  static const Currency ils = _ils;
  static const Currency aed = _aed;
  static const Currency sar = _sar;

  // ==================== MÉTHODES UTILITAIRES ====================

  /// Obtient la liste des codes de devises
  static List<String> get allCodes => all.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises principales
  static List<String> get majorCodes => major.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises secondaires
  static List<String> get minorCodes => minor.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises asiatiques
  static List<String> get asianCodes => asian.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises européennes
  static List<String> get europeanCodes => european.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises des Amériques
  static List<String> get americasCodes => americas.map((c) => c.code).toList();

  /// Obtient la liste des codes de devises du Moyen-Orient et Afrique/Océanie
  static List<String> get meaOceaniaCodes =>
      meaOceania.map((c) => c.code).toList();

  /// Obtient la liste des devises actives
  static List<Currency> get activeCurrencies =>
      all.where((c) => c.isActive).toList();

  /// Obtient la liste des codes de devises actives
  static List<String> get activeCodes =>
      activeCurrencies.map((c) => c.code).toList();

  // ==================== MÉTHODES DE COMPATIBILITÉ ====================

  /// Obtient toutes les devises (alias pour all)
  static List<Currency> getAllCurrencies() => all;

  /// Obtient les devises principales (alias pour major)
  static List<Currency> getMajorCurrencies() => major;

  /// Obtient les devises secondaires (alias pour minor)
  static List<Currency> getMinorCurrencies() => minor;

  /// Obtient les devises asiatiques
  static List<Currency> getAsianCurrencies() => asian;

  /// Obtient les devises européennes
  static List<Currency> getEuropeanCurrencies() => european;

  /// Obtient les devises des Amériques
  static List<Currency> getAmericasCurrencies() => americas;

  /// Obtient les devises du Moyen-Orient et Afrique/Océanie
  static List<Currency> getMeaOceaniaCurrencies() => meaOceania;

  /// Obtient les codes des devises principales (alias pour majorCodes)
  static List<String> getMajorCurrencyCodes() => majorCodes;

  /// Obtient les codes des devises secondaires (alias pour minorCodes)
  static List<String> getMinorCurrencyCodes() => minorCodes;
}
